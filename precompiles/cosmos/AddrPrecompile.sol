// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title AddrPrecompile
/// @notice Demonstrates address conversion between EVM (0x) and Sei bech32
///         formats using the Sei addr precompile.
///
/// @dev The addr precompile is at 0x0000000000000000000000000000000000001004.
///      It provides bidirectional conversion between:
///        - EVM addresses  (0x...)
///        - Sei addresses  (sei1...)
interface IAddr {
    /// @notice Convert an EVM address to its corresponding Sei bech32 address.
    /// @param addr EVM address.
    /// @return response Bech32 Sei address string (sei1...).
    function getSeiAddr(address addr) external view returns (string memory response);

    /// @notice Convert a Sei bech32 address to its corresponding EVM address.
    /// @param addr Bech32 Sei address (sei1...).
    /// @return response EVM address.
    function getEvmAddr(string memory addr) external view returns (address response);
}

/// @notice The Sei addr precompile instance.
IAddr constant ADDR_PRECOMPILE = IAddr(0x0000000000000000000000000000000000001004);

/// @title AddrConverter
/// @notice Utility contract wrapping the addr precompile for cross-format
///         address lookups and on-chain bech32 ↔ EVM address resolution.
contract AddrConverter {
    // ─── Events ───────────────────────────────────────────────────────────────

    event Resolved(address indexed evmAddr, string seiAddr);

    // ─── Address Conversion ───────────────────────────────────────────────────

    /// @notice Convert an EVM address to a Sei bech32 address.
    /// @param evmAddr EVM address to convert.
    /// @return seiAddr Bech32 Sei address (sei1...).
    function toSeiAddress(address evmAddr) external view returns (string memory seiAddr) {
        return ADDR_PRECOMPILE.getSeiAddr(evmAddr);
    }

    /// @notice Convert a Sei bech32 address to an EVM address.
    /// @param seiAddr Bech32 Sei address (sei1...).
    /// @return evmAddr EVM address.
    function toEvmAddress(string memory seiAddr) external view returns (address evmAddr) {
        return ADDR_PRECOMPILE.getEvmAddr(seiAddr);
    }

    /// @notice Look up the caller's corresponding Sei address.
    /// @return seiAddr Bech32 address for msg.sender.
    function getMySeiAddress() external view returns (string memory seiAddr) {
        return ADDR_PRECOMPILE.getSeiAddr(msg.sender);
    }

    /// @notice Verify that a bech32 address and EVM address represent the same account.
    /// @param evmAddr EVM address.
    /// @param seiAddr Bech32 Sei address.
    /// @return same True if both addresses map to each other.
    function areSameAccount(address evmAddr, string memory seiAddr)
        external
        view
        returns (bool same)
    {
        address resolved = ADDR_PRECOMPILE.getEvmAddr(seiAddr);
        return resolved == evmAddr;
    }

    /// @notice Resolve and emit the Sei address for an EVM address.
    function resolveAndEmit(address evmAddr) external {
        string memory seiAddr = ADDR_PRECOMPILE.getSeiAddr(evmAddr);
        emit Resolved(evmAddr, seiAddr);
    }
}
