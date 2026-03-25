// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDistribution.sol";

/// @title YieldAggregator
/// @notice Harvests staking rewards from multiple validators and optionally
///         compounds them by re-delegating via the staking precompile.
/// @dev Uses the Sei Distribution precompile at 0x0000000000000000000000000000000000001007.
contract YieldAggregator {
    // ─── Constants ────────────────────────────────────────────────────────────

    IDistribution constant DISTR =
        IDistribution(0x0000000000000000000000000000000000001007);

    // ─── State ────────────────────────────────────────────────────────────────

    address public owner;

    /// @notice Per-user list of validators to harvest rewards from.
    mapping(address => string[]) public userValidators;

    // ─── Events ───────────────────────────────────────────────────────────────

    event ValidatorsUpdated(address indexed user, string[] validators);
    event RewardsHarvested(address indexed user, uint256 validatorCount);
    event WithdrawAddressChanged(address indexed user, address newAddress);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error NoValidators();
    error HarvestFailed();
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

    // ─── User-Facing Functions ────────────────────────────────────────────────

    /// @notice Register which validators to harvest rewards from.
    /// @param validators Array of bech32 validator addresses.
    function setValidators(string[] calldata validators) external {
        userValidators[msg.sender] = validators;
        emit ValidatorsUpdated(msg.sender, validators);
    }

    /// @notice Change the address that receives withdrawn rewards.
    /// @param newAddress EVM address to receive future reward withdrawals.
    function setWithdrawAddress(address newAddress) external {
        bool success = DISTR.setWithdrawAddress(newAddress);
        require(success, "Failed to set withdraw address");
        emit WithdrawAddressChanged(msg.sender, newAddress);
    }

    /// @notice Harvest (withdraw) pending rewards from all registered validators
    ///         for the caller.
    function harvestRewards() external {
        string[] memory validators = userValidators[msg.sender];
        if (validators.length == 0) revert NoValidators();

        bool success = DISTR.withdrawMultipleDelegationRewards(validators);
        if (!success) revert HarvestFailed();

        emit RewardsHarvested(msg.sender, validators.length);
    }

    /// @notice Harvest rewards from a single validator.
    /// @param validator Bech32 validator address.
    function harvestFromValidator(string memory validator) external {
        bool success = DISTR.withdrawDelegationRewards(validator);
        require(success, "Harvest failed");
    }

    // ─── View Functions ───────────────────────────────────────────────────────

    /// @notice Returns the total pending usei rewards for a user across all validators.
    /// @param user EVM address of the delegator.
    /// @return totalSei Amount in 18-decimal precision (as returned by the precompile).
    function checkPendingRewards(address user) external view returns (uint256 totalSei) {
        IDistribution.Rewards memory pending = DISTR.rewards(user);

        for (uint256 i = 0; i < pending.total.length; i++) {
            if (
                keccak256(bytes(pending.total[i].denom)) == keccak256(bytes("usei"))
            ) {
                totalSei = pending.total[i].amount;
                break;
            }
        }
    }

    /// @notice Returns per-validator pending rewards for a user.
    /// @param user EVM address of the delegator.
    function getPerValidatorRewards(address user)
        external
        view
        returns (IDistribution.Reward[] memory)
    {
        IDistribution.Rewards memory pending = DISTR.rewards(user);
        return pending.rewards;
    }

    /// @notice Returns all validators registered for a user.
    function getValidators(address user) external view returns (string[] memory) {
        return userValidators[user];
    }

    // ─── Owner Functions ──────────────────────────────────────────────────────

    /// @notice Transfer contract ownership.
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}
