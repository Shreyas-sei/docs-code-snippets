// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title PointerPrecompile
/// @notice Demonstrates pointer and pointerview precompile usage on Sei.
///         Pointers are ERC-20 / ERC-721 contracts that represent native Cosmos
///         tokens or CosmWasm contracts in the EVM environment.
///
/// The pointer precompile (write) is at:  0x000000000000000000000000000000000000100A
/// The pointerview precompile (read) is at: 0x000000000000000000000000000000000000100B

// ─── Pointer (write) precompile ───────────────────────────────────────────────

interface IPointer {
    /// @notice Create an ERC-20 pointer for a Cosmos native token.
    /// @param cwAddr Bech32 address of the original CW-20 contract, OR the
    ///               native denom string (e.g. "usei", "ibc/...").
    /// @return ret   EVM address of the newly deployed ERC-20 pointer contract.
    function addNativePointerForCw20(string memory cwAddr)
        external
        returns (address ret);

    /// @notice Create an ERC-20 pointer for an EVM ERC-20 token on the Cosmos side.
    /// @param erc20Addr EVM address of the ERC-20 contract.
    /// @return ret      Bech32 CW-20 address of the new pointer.
    function addCwPointerForErc20(address erc20Addr)
        external
        returns (string memory ret);

    /// @notice Create an ERC-721 pointer for a CW-721 NFT contract.
    /// @param cwAddr Bech32 address of the CW-721 contract.
    /// @return ret   EVM address of the newly deployed ERC-721 pointer.
    function addNativePointerForCw721(string memory cwAddr)
        external
        returns (address ret);

    /// @notice Create a CW-721 pointer for an EVM ERC-721 contract.
    /// @param erc721Addr EVM address of the ERC-721 contract.
    /// @return ret       Bech32 CW-721 address of the new pointer.
    function addCwPointerForErc721(address erc721Addr)
        external
        returns (string memory ret);
}

// ─── Pointerview (read) precompile ────────────────────────────────────────────

interface IPointerView {
    /// @notice Get the ERC-20 pointer address for a CW-20 or native token.
    /// @param cwAddr Bech32 CW-20 address or native denom.
    /// @return ret   EVM address of the pointer contract (address(0) if none).
    function getNativePointerForCw20(string memory cwAddr)
        external
        view
        returns (address ret);

    /// @notice Get the CW-20 address for an ERC-20 pointer.
    /// @param erc20Addr EVM address of the ERC-20 pointer.
    /// @return ret      Bech32 CW-20 address.
    function getCwPointerForErc20(address erc20Addr)
        external
        view
        returns (string memory ret);

    /// @notice Get the ERC-721 pointer address for a CW-721 contract.
    /// @param cwAddr Bech32 CW-721 address.
    /// @return ret   EVM address of the ERC-721 pointer (address(0) if none).
    function getNativePointerForCw721(string memory cwAddr)
        external
        view
        returns (address ret);

    /// @notice Get the CW-721 address for an ERC-721 pointer.
    /// @param erc721Addr EVM address of the ERC-721 pointer.
    /// @return ret       Bech32 CW-721 address.
    function getCwPointerForErc721(address erc721Addr)
        external
        view
        returns (string memory ret);
}

IPointer constant POINTER_PRECOMPILE =
    IPointer(0x000000000000000000000000000000000000100A);

IPointerView constant POINTER_VIEW_PRECOMPILE =
    IPointerView(0x000000000000000000000000000000000000100B);

// ─── Contract ────────────────────────────────────────────────────────────────

/// @title PointerRegistry
/// @notice Helper contract for creating and resolving token pointers between
///         the EVM and Cosmos environments on Sei.
contract PointerRegistry {
    // ─── Events ───────────────────────────────────────────────────────────────

    event Erc20PointerCreated(string indexed cwAddr, address evmPointer);
    event Erc721PointerCreated(string indexed cwAddr, address evmPointer);
    event CwPointerCreated(address indexed evmAddr, string cwPointer);

    // ─── Create Pointers ──────────────────────────────────────────────────────

    /// @notice Create an ERC-20 pointer for a CW-20 or native token.
    /// @param cwAddr Bech32 CW-20 address or native denom string.
    /// @return evmPointer EVM address of the new ERC-20 pointer.
    function createErc20Pointer(string calldata cwAddr)
        external
        returns (address evmPointer)
    {
        evmPointer = POINTER_PRECOMPILE.addNativePointerForCw20(cwAddr);
        emit Erc20PointerCreated(cwAddr, evmPointer);
    }

    /// @notice Create an ERC-721 pointer for a CW-721 NFT contract.
    /// @param cwAddr Bech32 CW-721 address.
    /// @return evmPointer EVM address of the new ERC-721 pointer.
    function createErc721Pointer(string calldata cwAddr)
        external
        returns (address evmPointer)
    {
        evmPointer = POINTER_PRECOMPILE.addNativePointerForCw721(cwAddr);
        emit Erc721PointerCreated(cwAddr, evmPointer);
    }

    /// @notice Create a CW-20 pointer for an EVM ERC-20 token.
    /// @param erc20Addr EVM address of the ERC-20 contract.
    /// @return cwPointer Bech32 address of the new CW-20 pointer.
    function createCwPointerForErc20(address erc20Addr)
        external
        returns (string memory cwPointer)
    {
        cwPointer = POINTER_PRECOMPILE.addCwPointerForErc20(erc20Addr);
        emit CwPointerCreated(erc20Addr, cwPointer);
    }

    // ─── Resolve Pointers ─────────────────────────────────────────────────────

    /// @notice Resolve the ERC-20 pointer for a CW-20 or native token.
    /// @param cwAddr Bech32 address or denom string.
    /// @return evmPointer EVM address (address(0) if no pointer exists).
    function getErc20Pointer(string calldata cwAddr)
        external
        view
        returns (address evmPointer)
    {
        return POINTER_VIEW_PRECOMPILE.getNativePointerForCw20(cwAddr);
    }

    /// @notice Check whether an ERC-20 pointer exists for a CW-20 token.
    function hasErc20Pointer(string calldata cwAddr) external view returns (bool) {
        return POINTER_VIEW_PRECOMPILE.getNativePointerForCw20(cwAddr) != address(0);
    }

    /// @notice Resolve the ERC-721 pointer for a CW-721 contract.
    /// @param cwAddr Bech32 CW-721 address.
    /// @return evmPointer EVM address (address(0) if no pointer exists).
    function getErc721Pointer(string calldata cwAddr)
        external
        view
        returns (address evmPointer)
    {
        return POINTER_VIEW_PRECOMPILE.getNativePointerForCw721(cwAddr);
    }

    /// @notice Resolve the CW-20 pointer for an EVM ERC-20 token.
    function getCwPointerForErc20(address erc20Addr)
        external
        view
        returns (string memory)
    {
        return POINTER_VIEW_PRECOMPILE.getCwPointerForErc20(erc20Addr);
    }
}
