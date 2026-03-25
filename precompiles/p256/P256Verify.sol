// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title P256Verify
/// @notice Low-level interface to the EIP-7212 P256 signature verification
///         precompile deployed at address 0x0000000000000000000000000000000000000100.
///
/// @dev EIP-7212: https://eips.ethereum.org/EIPS/eip-7212
///      Input format: abi.encode(hash32, r, s, x, y)
///        - hash32 : 32-byte message digest
///        - r, s   : 32-byte signature components
///        - x, y   : 32-byte uncompressed public key coordinates
///
///      Output: 32 bytes where output[31] == 0x01 indicates a valid signature.
interface IP256Verify {
    /// @notice Verify a P-256 (secp256r1) signature.
    /// @param input ABI-encoded (hash, r, s, x, y).
    /// @return output 32 bytes; output[31] == 0x01 if the signature is valid.
    function verify(bytes memory input) external view returns (bytes memory output);
}

/// @notice The EIP-7212 P256VERIFY precompile instance.
IP256Verify constant P256VERIFY_CONTRACT =
    IP256Verify(0x0000000000000000000000000000000000000100);
