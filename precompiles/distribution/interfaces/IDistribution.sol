// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IDistribution
/// @notice Interface for the Sei Distribution precompile.
/// @dev Precompile address: 0x0000000000000000000000000000000000001007
interface IDistribution {
    // ─── Structs ──────────────────────────────────────────────────────────────

    /// @notice A single coin denomination with amount.
    struct Coin {
        /// @dev Token amount in 18-decimal precision (DecCoins for pending rewards;
        ///      6-decimal for withdrawn amounts emitted in events).
        uint256 amount;
        /// @dev Always 18 for reward amounts returned by rewards().
        uint256 decimals;
        /// @dev Token denomination, e.g. "usei".
        string denom;
    }

    /// @notice Pending rewards from a single validator.
    struct Reward {
        /// @dev Reward coins from this validator.
        Coin[] coins;
        /// @dev Validator's Sei bech32 address.
        string validator_address;
    }

    /// @notice Aggregated pending rewards across all validators.
    struct Rewards {
        /// @dev Per-validator reward breakdown.
        Reward[] rewards;
        /// @dev Total rewards across all validators.
        Coin[] total;
    }

    // ─── Events ───────────────────────────────────────────────────────────────

    /// @notice Emitted when a delegator changes their withdrawal address.
    event WithdrawAddressSet(address indexed delegator, address withdrawAddr);

    /// @notice Emitted when delegation rewards are withdrawn from a single validator.
    /// @dev `amount` is denominated in usei (6 decimals).
    event DelegationRewardsWithdrawn(address indexed delegator, string validator, uint256 amount);

    /// @notice Emitted when delegation rewards are withdrawn from multiple validators.
    /// @dev Each `amounts[i]` is denominated in usei (6 decimals).
    event MultipleDelegationRewardsWithdrawn(
        address indexed delegator,
        string[] validators,
        uint256[] amounts
    );

    /// @notice Emitted when a validator withdraws its commission.
    /// @dev `amount` is denominated in usei (6 decimals).
    event ValidatorCommissionWithdrawn(string indexed validator, uint256 amount);

    // ─── Write Methods ────────────────────────────────────────────────────────

    /// @notice Set the address that receives delegation reward withdrawals.
    /// @param withdrawAddr EVM address to receive rewards.
    /// @return success True on success.
    function setWithdrawAddress(address withdrawAddr) external returns (bool success);

    /// @notice Withdraw all pending delegation rewards from a single validator.
    /// @param validator Bech32 validator address (seivaloper1...).
    /// @return success True on success.
    function withdrawDelegationRewards(string memory validator) external returns (bool success);

    /// @notice Withdraw all pending delegation rewards from multiple validators in one call.
    /// @param validators Array of bech32 validator addresses.
    /// @return success True on success.
    function withdrawMultipleDelegationRewards(string[] memory validators)
        external
        returns (bool success);

    /// @notice Withdraw the validator's accumulated commission.
    ///         Only callable by the validator operator.
    /// @return success True on success.
    function withdrawValidatorCommission() external returns (bool success);

    // ─── View Methods ─────────────────────────────────────────────────────────

    /// @notice Query all pending delegation rewards for a delegator.
    /// @param delegatorAddress EVM address of the delegator.
    /// @return Rewards struct containing per-validator and total amounts.
    function rewards(address delegatorAddress) external view returns (Rewards memory);
}
