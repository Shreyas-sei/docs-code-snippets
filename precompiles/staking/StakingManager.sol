// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IStaking.sol";

/// @title StakingManager
/// @notice A managed staking contract that delegates, undelegates, and
///         redelegates SEI on behalf of its users using the Sei staking precompile.
/// @dev Uses the Sei Staking precompile at 0x0000000000000000000000000000000000001005.
contract StakingManager {
    // ─── Constants ────────────────────────────────────────────────────────────

    IStaking constant STAKING =
        IStaking(0x0000000000000000000000000000000000001005);

    // ─── State ────────────────────────────────────────────────────────────────

    address public owner;

    // ─── Events ───────────────────────────────────────────────────────────────

    event Delegated(address indexed delegator, string validator, uint256 amount);
    event Undelegated(address indexed delegator, string validator, uint256 amount);
    event Redelegated(
        address indexed delegator,
        string fromValidator,
        string toValidator,
        uint256 amount
    );
    event ValidatorCreated(address indexed creator, string moniker);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error ZeroAmount();
    error DelegationFailed();
    error UndelegationFailed();
    error RedelegationFailed();
    error ValidatorCreationFailed();
    error ValidatorEditFailed();
    error NotOwner();

    // ─── Modifiers ────────────────────────────────────────────────────────────

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // ─── Constructor ─────────────────────────────────────────────────────────

    constructor() {
        owner = msg.sender;
    }

    // ─── Write Functions ──────────────────────────────────────────────────────

    /// @notice Delegate SEI to a validator.
    /// @dev msg.value is forwarded to the staking precompile (18-decimal wei).
    /// @param validatorAddress Bech32 validator address (seivaloper1...).
    function delegateToValidator(string memory validatorAddress) external payable {
        if (msg.value == 0) revert ZeroAmount();

        bool success = STAKING.delegate{value: msg.value}(validatorAddress);
        if (!success) revert DelegationFailed();

        emit Delegated(msg.sender, validatorAddress, msg.value);
    }

    /// @notice Begin unbonding tokens from a validator.
    /// @param validatorAddress Bech32 validator address.
    /// @param amount Amount to undelegate in usei (6 decimals).
    function undelegateFromValidator(
        string memory validatorAddress,
        uint256 amount
    ) external {
        if (amount == 0) revert ZeroAmount();

        bool success = STAKING.undelegate(validatorAddress, amount);
        if (!success) revert UndelegationFailed();

        emit Undelegated(msg.sender, validatorAddress, amount);
    }

    /// @notice Move tokens from one validator to another without unbonding.
    /// @param fromValidator Source validator bech32 address.
    /// @param toValidator   Destination validator bech32 address.
    /// @param amount        Amount in usei (6 decimals).
    function redelegateBetweenValidators(
        string memory fromValidator,
        string memory toValidator,
        uint256 amount
    ) external {
        if (amount == 0) revert ZeroAmount();

        bool success = STAKING.redelegate(fromValidator, toValidator, amount);
        if (!success) revert RedelegationFailed();

        emit Redelegated(msg.sender, fromValidator, toValidator, amount);
    }

    /// @notice Create a new Sei validator.
    /// @param pubKeyHex               Ed25519 public key as a 64-char hex string.
    /// @param moniker                  Human-readable validator name.
    /// @param commissionRate           Initial commission rate string (e.g. "0.05").
    /// @param commissionMaxRate        Max commission string (e.g. "0.20").
    /// @param commissionMaxChangeRate  Max change per day (e.g. "0.01").
    /// @param minSelfDelegation        Minimum self-delegation in usei.
    function createNewValidator(
        string memory pubKeyHex,
        string memory moniker,
        string memory commissionRate,
        string memory commissionMaxRate,
        string memory commissionMaxChangeRate,
        uint256 minSelfDelegation
    ) external payable onlyOwner {
        if (msg.value == 0) revert ZeroAmount();

        bool success = STAKING.createValidator{value: msg.value}(
            pubKeyHex,
            moniker,
            commissionRate,
            commissionMaxRate,
            commissionMaxChangeRate,
            minSelfDelegation
        );
        if (!success) revert ValidatorCreationFailed();

        emit ValidatorCreated(msg.sender, moniker);
    }

    /// @notice Edit an existing validator's parameters.
    /// @param moniker             New human-readable name.
    /// @param commissionRate      New commission rate string.
    /// @param minSelfDelegation   New minimum self-delegation in usei.
    function editExistingValidator(
        string memory moniker,
        string memory commissionRate,
        uint256 minSelfDelegation
    ) external onlyOwner {
        bool success = STAKING.editValidator(moniker, commissionRate, minSelfDelegation);
        if (!success) revert ValidatorEditFailed();
    }

    // ─── View Functions ───────────────────────────────────────────────────────

    /// @notice Query the delegation between a delegator and validator.
    function getDelegationInfo(
        address delegator,
        string memory validatorAddress
    ) external view returns (IStaking.Delegation memory) {
        return STAKING.delegation(delegator, validatorAddress);
    }

    /// @notice Query all delegations for a delegator.
    function getAllDelegations(address delegator)
        external
        view
        returns (IStaking.DelegationsResponse memory)
    {
        return STAKING.delegatorDelegations(delegator, "0x");
    }

    /// @notice Query all unbonding delegations for a delegator.
    function getUnbondingDelegations(address delegator)
        external
        view
        returns (IStaking.UnbondingDelegationsResponse memory)
    {
        return STAKING.delegatorUnbondingDelegations(delegator, "0x");
    }

    /// @notice Query information for a single validator.
    function getValidatorInfo(string memory validatorAddress)
        external
        view
        returns (IStaking.Validator memory)
    {
        return STAKING.validator(validatorAddress);
    }

    /// @notice Query the staking pool totals.
    function getPool() external view returns (IStaking.Pool memory) {
        return STAKING.pool();
    }

    /// @notice Query module-level staking parameters.
    function getParams() external view returns (IStaking.Params memory) {
        return STAKING.params();
    }

    // ─── Owner Functions ──────────────────────────────────────────────────────

    /// @notice Transfer contract ownership.
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    // ─── Receive ─────────────────────────────────────────────────────────────

    receive() external payable {}
}
