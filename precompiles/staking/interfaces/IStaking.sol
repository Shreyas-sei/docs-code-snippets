// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IStaking
/// @notice Interface for the Sei Staking precompile.
/// @dev Precompile address: 0x0000000000000000000000000000000000001005
interface IStaking {
    // ─── Structs ──────────────────────────────────────────────────────────────

    /// @notice Balance in the staking module (usei, 6 decimals).
    struct Balance {
        /// @dev Staked balance in usei (6 decimal precision).
        uint256 amount;
        /// @dev Token denomination, e.g. "usei".
        string denom;
    }

    /// @notice Details of a specific delegation.
    struct DelegationDetails {
        string delegator_address;
        /// @dev Delegation shares with 18-decimal precision.
        uint256 shares;
        /// @dev Always 18.
        uint256 decimals;
        string validator_address;
    }

    /// @notice Combined delegation info returned by delegation().
    struct Delegation {
        Balance balance;
        DelegationDetails delegation;
    }

    /// @notice Full validator information.
    struct Validator {
        string operatorAddress;
        string consensusPubkey;
        bool jailed;
        /// @dev 1=Unbonded, 2=Unbonding, 3=Bonded.
        int32 status;
        string tokens;
        string delegatorShares;
        string description;
        int64 unbondingHeight;
        int64 unbondingTime;
        string commissionRate;
        string commissionMaxRate;
        string commissionMaxChangeRate;
        int64 commissionUpdateTime;
        string minSelfDelegation;
    }

    /// @notice Paginated response containing validators.
    struct ValidatorsResponse {
        Validator[] validators;
        bytes nextKey;
    }

    /// @notice Paginated response containing delegations.
    struct DelegationsResponse {
        Delegation[] delegations;
        bytes nextKey;
    }

    /// @notice Single unbonding entry.
    struct UnbondingEntry {
        int64 creationHeight;
        int64 completionTime;
        uint256 initialBalance;
        uint256 balance;
    }

    /// @notice Unbonding delegations for a validator.
    struct UnbondingDelegation {
        string delegatorAddress;
        string validatorAddress;
        UnbondingEntry[] entries;
    }

    /// @notice Paginated response containing unbonding delegations.
    struct UnbondingDelegationsResponse {
        UnbondingDelegation[] unbondingDelegations;
        bytes nextKey;
    }

    /// @notice A single redelegation entry.
    struct RedelegationEntry {
        int64 creationHeight;
        int64 completionTime;
        uint256 initialBalance;
        uint256 sharesDst;
    }

    /// @notice A redelegation between two validators.
    struct Redelegation {
        string delegatorAddress;
        string validatorSrcAddress;
        string validatorDstAddress;
        RedelegationEntry[] entries;
    }

    /// @notice Paginated response containing redelegations.
    struct RedelegationsResponse {
        Redelegation[] redelegations;
        bytes nextKey;
    }

    /// @notice Historical validator set at a given block height.
    struct HistoricalInfo {
        Validator[] validators;
    }

    /// @notice Staking pool totals.
    struct Pool {
        string bondedTokens;
        string notBondedTokens;
    }

    /// @notice Module-level staking parameters.
    struct Params {
        uint256 unbondingTime;
        uint32 maxValidators;
        uint32 maxEntries;
        uint32 historicalEntries;
        string bondDenom;
        string minCommissionRate;
    }

    // ─── Events ───────────────────────────────────────────────────────────────

    event Delegate(address indexed delegator, string validator, uint256 amount);
    event Redelegate(
        address indexed delegator,
        string srcValidator,
        string dstValidator,
        uint256 amount
    );
    event Undelegate(address indexed delegator, string validator, uint256 amount);
    event ValidatorCreated(address indexed creator, string validatorAddress, string moniker);
    event ValidatorEdited(address indexed editor, string validatorAddress, string moniker);

    // ─── Write Methods ────────────────────────────────────────────────────────

    /// @notice Delegate SEI to a validator.
    /// @dev msg.value must be provided in 18-decimal wei.
    /// @param valAddress Bech32 validator address (seivaloper1...).
    /// @return success True on success.
    function delegate(string memory valAddress) external payable returns (bool success);

    /// @notice Move tokens from one validator to another without unbonding.
    /// @param srcAddress Source validator bech32 address.
    /// @param dstAddress Destination validator bech32 address.
    /// @param amount Amount in usei (6 decimals).
    /// @return success True on success.
    function redelegate(
        string memory srcAddress,
        string memory dstAddress,
        uint256 amount
    ) external returns (bool success);

    /// @notice Begin unbonding tokens from a validator.
    /// @param valAddress Bech32 validator address.
    /// @param amount Amount in usei (6 decimals).
    /// @return success True on success.
    function undelegate(
        string memory valAddress,
        uint256 amount
    ) external returns (bool success);

    /// @notice Create a new validator.
    /// @param pubKeyHex Ed25519 public key as a 64-character hex string.
    /// @param moniker Human-readable validator name.
    /// @param commissionRate Initial commission rate (e.g. "0.05").
    /// @param commissionMaxRate Maximum allowed commission (e.g. "0.20").
    /// @param commissionMaxChangeRate Maximum rate of change per day (e.g. "0.01").
    /// @param minSelfDelegation Minimum self-delegation in usei.
    /// @return success True on success.
    function createValidator(
        string memory pubKeyHex,
        string memory moniker,
        string memory commissionRate,
        string memory commissionMaxRate,
        string memory commissionMaxChangeRate,
        uint256 minSelfDelegation
    ) external payable returns (bool success);

    /// @notice Edit an existing validator's parameters.
    /// @param moniker New human-readable name.
    /// @param commissionRate New commission rate string.
    /// @param minSelfDelegation New minimum self-delegation.
    /// @return success True on success.
    function editValidator(
        string memory moniker,
        string memory commissionRate,
        uint256 minSelfDelegation
    ) external returns (bool success);

    // ─── View Methods ─────────────────────────────────────────────────────────

    /// @notice Query the delegation of a specific delegator to a validator.
    function delegation(address delegator, string memory valAddress)
        external
        view
        returns (Delegation memory);

    /// @notice Query validators with an optional status filter and pagination.
    /// @param status Filter by bonding status: "BOND_STATUS_BONDED", "BOND_STATUS_UNBONDING",
    ///               "BOND_STATUS_UNBONDED", or "" for all.
    /// @param nextKey Pagination cursor (use "0x" for the first page).
    function validators(string memory status, bytes memory nextKey)
        external
        view
        returns (ValidatorsResponse memory response);

    /// @notice Query a single validator by address.
    function validator(string memory validatorAddress)
        external
        view
        returns (Validator memory);

    /// @notice Query all delegations to a specific validator.
    function validatorDelegations(string memory validatorAddress, bytes memory nextKey)
        external
        view
        returns (DelegationsResponse memory response);

    /// @notice Query the unbonding delegation between a delegator and validator.
    function unbondingDelegation(address delegator, string memory validatorAddress)
        external
        view
        returns (UnbondingDelegation memory);

    /// @notice Query all delegations for a delegator.
    function delegatorDelegations(address delegator, bytes memory nextKey)
        external
        view
        returns (DelegationsResponse memory response);

    /// @notice Query all unbonding delegations for a delegator.
    function delegatorUnbondingDelegations(address delegator, bytes memory nextKey)
        external
        view
        returns (UnbondingDelegationsResponse memory response);

    /// @notice Query redelegations with optional filters.
    function redelegations(
        string memory delegator,
        string memory srcValidator,
        string memory dstValidator,
        bytes memory nextKey
    ) external view returns (RedelegationsResponse memory response);

    /// @notice Query all validators a delegator has staked with.
    function delegatorValidators(address delegator, bytes memory nextKey)
        external
        view
        returns (ValidatorsResponse memory response);

    /// @notice Query the validator set at a historical block height.
    function historicalInfo(int64 height)
        external
        view
        returns (HistoricalInfo memory);

    /// @notice Query the current staking pool.
    function pool() external view returns (Pool memory);

    /// @notice Query module-level staking parameters.
    function params() external view returns (Params memory);
}
