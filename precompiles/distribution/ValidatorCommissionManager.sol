// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDistribution.sol";

/// @title ValidatorCommissionManager
/// @notice Manages validator commission withdrawal and treasury routing for
///         Sei validator operators.
/// @dev Uses the Sei Distribution precompile at 0x0000000000000000000000000000000000001007.
///
/// Deployment pattern:
///   1. Deploy with the treasury address.
///   2. The constructor automatically points all reward withdrawals to the treasury.
///   3. Call withdrawCommission() periodically to move earned commissions to treasury.
contract ValidatorCommissionManager {
    // ─── Constants ────────────────────────────────────────────────────────────

    IDistribution constant DISTR =
        IDistribution(0x0000000000000000000000000000000000001007);

    // ─── State ────────────────────────────────────────────────────────────────

    address public owner;
    address public treasury;

    // ─── Events ───────────────────────────────────────────────────────────────

    event CommissionWithdrawn(address indexed operator, address indexed treasury);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event RewardsWithdrawn(address indexed delegator, string validator);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error NotOwner();
    error CommissionWithdrawalFailed();
    error RewardsWithdrawalFailed();
    error InvalidAddress();

    // ─── Modifiers ────────────────────────────────────────────────────────────

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // ─── Constructor ─────────────────────────────────────────────────────────

    /// @param _treasury Address that will receive all reward and commission withdrawals.
    constructor(address _treasury) {
        if (_treasury == address(0)) revert InvalidAddress();
        owner = msg.sender;
        treasury = _treasury;
        // Point all future reward withdrawals to the treasury immediately.
        DISTR.setWithdrawAddress(_treasury);
    }

    // ─── Operator Functions ───────────────────────────────────────────────────

    /// @notice Withdraw accumulated validator commission to the treasury.
    ///         Can only be called by the validator's operator (this contract's owner).
    function withdrawCommission() external onlyOwner {
        bool success = DISTR.withdrawValidatorCommission();
        if (!success) revert CommissionWithdrawalFailed();
        emit CommissionWithdrawn(msg.sender, treasury);
    }

    /// @notice Withdraw delegation rewards from a specific validator.
    /// @param validator Bech32 validator address (seivaloper1...).
    function withdrawDelegationRewards(string calldata validator) external onlyOwner {
        bool success = DISTR.withdrawDelegationRewards(validator);
        if (!success) revert RewardsWithdrawalFailed();
        emit RewardsWithdrawn(msg.sender, validator);
    }

    /// @notice Withdraw delegation rewards from multiple validators at once.
    /// @param validators Array of bech32 validator addresses.
    function withdrawMultipleDelegationRewards(string[] calldata validators)
        external
        onlyOwner
    {
        bool success = DISTR.withdrawMultipleDelegationRewards(validators);
        if (!success) revert RewardsWithdrawalFailed();
    }

    // ─── Treasury Management ─────────────────────────────────────────────────

    /// @notice Update the treasury address.
    ///         Also updates the withdrawal address in the distribution precompile.
    /// @param newTreasury New treasury EVM address.
    function updateTreasury(address newTreasury) external onlyOwner {
        if (newTreasury == address(0)) revert InvalidAddress();
        emit TreasuryUpdated(treasury, newTreasury);
        treasury = newTreasury;
        DISTR.setWithdrawAddress(newTreasury);
    }

    // ─── View Functions ───────────────────────────────────────────────────────

    /// @notice Returns all pending rewards for an address.
    function getPendingRewards(address delegator)
        external
        view
        returns (IDistribution.Rewards memory)
    {
        return DISTR.rewards(delegator);
    }

    /// @notice Returns the total pending usei for a delegator (18-decimal precision).
    function getTotalPendingUsei(address delegator)
        external
        view
        returns (uint256 amount)
    {
        IDistribution.Rewards memory pending = DISTR.rewards(delegator);
        for (uint256 i = 0; i < pending.total.length; i++) {
            if (
                keccak256(bytes(pending.total[i].denom)) == keccak256(bytes("usei"))
            ) {
                return pending.total[i].amount;
            }
        }
    }

    // ─── Owner Functions ──────────────────────────────────────────────────────

    /// @notice Transfer contract ownership to a new operator.
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidAddress();
        owner = newOwner;
    }
}
