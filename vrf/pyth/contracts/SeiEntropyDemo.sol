// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@pythnetwork/entropy-sdk-solidity/IEntropyV2.sol";
import "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";

/**
 * @title SeiEntropyDemo
 * @notice A dice game using Pyth Entropy (VRF) on Sei EVM
 * @dev Demonstrates the full Pyth Entropy request-callback lifecycle:
 *      1. Player calls playDiceGame() with a target number and fee
 *      2. Contract requests randomness from Pyth Entropy via requestV2()
 *      3. Pyth calls back entropyCallback() with the random number
 *      4. Contract resolves the game and distributes winnings
 *
 * Pyth Entropy contract addresses on Sei:
 *   Mainnet:  0x98046Bd286715D3B0BC227Dd7a956b83D8978603
 *   Testnet:  0x98046Bd286715D3B0BC227Dd7a956b83D8978603
 *
 * Provider address (required for requestV2):
 *   0x6CC14824Ea2918f5De5C2f75A9Da968ad4BD6344
 */
contract SeiEntropyDemo is IEntropyConsumer {
    IEntropyV2 entropy;

    struct DiceGame {
        address player;
        uint256 betAmount;
        uint256 targetNumber;
        bool fulfilled;
        bool won;
        uint256 diceRoll;
        uint256 timestamp;
    }

    mapping(uint64 => DiceGame) public games;
    mapping(address => uint256) public playerBalances;
    uint256 public gameCounter;

    event GameRequested(
        uint64 indexed sequenceNumber,
        address indexed player,
        uint256 betAmount,
        uint256 targetNumber
    );
    event GameResolved(
        uint64 indexed sequenceNumber,
        address indexed player,
        bool won,
        uint256 diceRoll
    );
    event RandomnessRequested(uint64 indexed sequenceNumber);
    event RandomnessFulfilled(uint64 indexed sequenceNumber, bytes32 randomNumber);

    constructor(address _entropy) {
        entropy = IEntropyV2(_entropy);
    }

    // ─────────────────────────────────────────────
    // IEntropyConsumer required override
    // ─────────────────────────────────────────────

    function getEntropy() internal view override returns (address) {
        return address(entropy);
    }

    // ─────────────────────────────────────────────
    // Game logic
    // ─────────────────────────────────────────────

    /**
     * @notice Start a new dice game round
     * @param targetNumber The dice value the player is betting on (1–6)
     * @dev msg.value must cover the Pyth Entropy fee; any excess is treated as the bet
     */
    function playDiceGame(uint256 targetNumber)
        external
        payable
        returns (uint64 sequenceNumber)
    {
        require(targetNumber >= 1 && targetNumber <= 6, "Target must be 1-6");
        uint128 requestFee = entropy.getFeeV2();
        require(msg.value >= requestFee, "Insufficient fee for randomness");

        uint256 betAmount = msg.value - requestFee;

        // Generate a user-supplied random commitment (prevents front-running)
        bytes32 userRandom = keccak256(
            abi.encodePacked(
                msg.sender,
                block.timestamp,
                block.prevrandao,
                gameCounter++
            )
        );

        // Request randomness from Pyth Entropy
        address provider = entropy.getDefaultProvider();
        sequenceNumber = entropy.requestV2{value: requestFee}(provider, userRandom);

        games[sequenceNumber] = DiceGame({
            player: msg.sender,
            betAmount: betAmount,
            targetNumber: targetNumber,
            fulfilled: false,
            won: false,
            diceRoll: 0,
            timestamp: block.timestamp
        });

        emit GameRequested(sequenceNumber, msg.sender, betAmount, targetNumber);
        emit RandomnessRequested(sequenceNumber);
    }

    // ─────────────────────────────────────────────
    // Entropy callback (called by Pyth)
    // ─────────────────────────────────────────────

    /**
     * @notice Called by the Pyth Entropy contract after randomness is fulfilled
     * @param sequenceNumber The sequence number from the original request
     * @param provider       The entropy provider address
     * @param randomNumber   The fulfilled random bytes32
     */
    function entropyCallback(
        uint64 sequenceNumber,
        address provider,
        bytes32 randomNumber
    ) internal override {
        emit RandomnessFulfilled(sequenceNumber, randomNumber);

        DiceGame storage game = games[sequenceNumber];
        require(!game.fulfilled, "SeiEntropyDemo: already fulfilled");
        require(game.player != address(0), "SeiEntropyDemo: game not found");

        // Derive a dice roll (1–6) from the random number
        uint256 diceRoll = (uint256(randomNumber) % 6) + 1;

        game.fulfilled = true;
        game.diceRoll = diceRoll;

        if (diceRoll == game.targetNumber) {
            game.won = true;
            // Winner gets 5x their bet (5/6 probability-adjusted payout)
            uint256 winnings = game.betAmount * 5;
            if (address(this).balance >= winnings) {
                playerBalances[game.player] += winnings;
            } else {
                // House ran out of funds — return bet
                playerBalances[game.player] += game.betAmount;
            }
        }
        // Loser's bet stays in the contract as house funds

        emit GameResolved(sequenceNumber, game.player, game.won, diceRoll);
    }

    // ─────────────────────────────────────────────
    // Withdrawals
    // ─────────────────────────────────────────────

    /**
     * @notice Withdraw accumulated winnings
     */
    function withdraw() external {
        uint256 amount = playerBalances[msg.sender];
        require(amount > 0, "SeiEntropyDemo: nothing to withdraw");
        playerBalances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // ─────────────────────────────────────────────
    // View helpers
    // ─────────────────────────────────────────────

    /**
     * @notice Returns the current Pyth Entropy fee
     */
    function getRequestFee() external view returns (uint128) {
        return entropy.getFeeV2();
    }

    /**
     * @notice Returns full game state for a sequence number
     */
    function getGame(uint64 sequenceNumber)
        external
        view
        returns (DiceGame memory)
    {
        return games[sequenceNumber];
    }

    // ─────────────────────────────────────────────
    // House funding
    // ─────────────────────────────────────────────

    /// @notice Fund the house bankroll
    receive() external payable {}

    /**
     * @notice Withdraw house funds (no access control for demo — add Ownable in production)
     */
    function withdrawHouseFunds(uint256 amount) external {
        require(address(this).balance >= amount, "SeiEntropyDemo: insufficient balance");
        payable(msg.sender).transfer(amount);
    }
}
