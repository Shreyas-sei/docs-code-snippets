// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IBCPrecompile
/// @notice Demonstrates initiating IBC (Inter-Blockchain Communication)
///         token transfers from Solidity using the Sei IBC precompile.
///
/// @dev The IBC transfer precompile is at 0x0000000000000000000000000000000000001009.
///      It exposes the ICS-20 fungible token transfer protocol to EVM contracts,
///      enabling cross-chain transfers to Cosmos IBC-enabled chains.
interface IIBC {
    /// @notice Initiate an IBC token transfer.
    /// @param toAddress    Recipient address on the destination chain (bech32 or 0x).
    /// @param port         IBC source port (typically "transfer").
    /// @param channel      IBC source channel (e.g. "channel-0").
    /// @param denom        Token denomination to transfer.
    /// @param amount       Amount to transfer.
    /// @param revisionNumber Revision number for timeout height.
    /// @param revisionHeight Block height on destination chain after which transfer times out.
    /// @param timeoutTimestamp Unix nanoseconds for timeout (0 = use height-based timeout).
    /// @param memo         Optional memo string.
    /// @return success     True on success.
    function transfer(
        string memory toAddress,
        string memory port,
        string memory channel,
        string memory denom,
        uint256 amount,
        uint64 revisionNumber,
        uint64 revisionHeight,
        uint64 timeoutTimestamp,
        string memory memo
    ) external payable returns (bool success);
}

/// @notice The Sei IBC transfer precompile instance.
IIBC constant IBC_PRECOMPILE = IIBC(0x0000000000000000000000000000000000001009);

/// @title IBCTransfer
/// @notice Facilitates IBC token transfers to Cosmos chains from Solidity.
///         Supports standard token transfers with configurable timeout strategies.
contract IBCTransfer {
    // ─── Constants ────────────────────────────────────────────────────────────

    /// @dev Default IBC transfer port.
    string constant DEFAULT_PORT = "transfer";

    // ─── State ────────────────────────────────────────────────────────────────

    address public owner;

    // ─── Events ───────────────────────────────────────────────────────────────

    event IBCTransferInitiated(
        string indexed channel,
        string toAddress,
        string denom,
        uint256 amount,
        string memo
    );

    // ─── Errors ───────────────────────────────────────────────────────────────

    error TransferFailed();
    error ZeroAmount();
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

    // ─── Transfer Functions ───────────────────────────────────────────────────

    /// @notice Transfer tokens via IBC using a block-height timeout.
    /// @param toAddress      Recipient address on the destination chain.
    /// @param channel        IBC source channel (e.g. "channel-0" for Cosmos Hub).
    /// @param denom          Token denomination (e.g. "usei").
    /// @param amount         Amount to transfer.
    /// @param revisionNumber Destination chain's revision/epoch number.
    /// @param revisionHeight Block height on destination chain for timeout.
    /// @param memo           Optional memo.
    function transferWithHeightTimeout(
        string calldata toAddress,
        string calldata channel,
        string calldata denom,
        uint256 amount,
        uint64 revisionNumber,
        uint64 revisionHeight,
        string calldata memo
    ) external payable {
        if (amount == 0) revert ZeroAmount();

        bool success = IBC_PRECOMPILE.transfer{value: msg.value}(
            toAddress,
            DEFAULT_PORT,
            channel,
            denom,
            amount,
            revisionNumber,
            revisionHeight,
            0, // no timestamp timeout
            memo
        );
        if (!success) revert TransferFailed();

        emit IBCTransferInitiated(channel, toAddress, denom, amount, memo);
    }

    /// @notice Transfer tokens via IBC using a Unix nanosecond timestamp timeout.
    /// @param toAddress         Recipient address on the destination chain.
    /// @param channel           IBC source channel.
    /// @param denom             Token denomination.
    /// @param amount            Amount to transfer.
    /// @param timeoutTimestamp  Unix nanoseconds for timeout.
    /// @param memo              Optional memo.
    function transferWithTimestampTimeout(
        string calldata toAddress,
        string calldata channel,
        string calldata denom,
        uint256 amount,
        uint64 timeoutTimestamp,
        string calldata memo
    ) external payable {
        if (amount == 0) revert ZeroAmount();

        bool success = IBC_PRECOMPILE.transfer{value: msg.value}(
            toAddress,
            DEFAULT_PORT,
            channel,
            denom,
            amount,
            0, // no height revision
            0, // no height timeout
            timeoutTimestamp,
            memo
        );
        if (!success) revert TransferFailed();

        emit IBCTransferInitiated(channel, toAddress, denom, amount, memo);
    }

    // ─── Owner Functions ──────────────────────────────────────────────────────

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    receive() external payable {}
}
