// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IJson
/// @notice Interface for the Sei JSON precompile.
/// @dev Precompile address: 0x0000000000000000000000000000000000001003
///
/// The JSON precompile allows Solidity contracts to extract typed values from
/// raw JSON byte arrays. This is useful when consuming oracle data, decoding
/// CosmWasm responses, or processing off-chain data passed as calldata.
interface IJson {
    /// @notice Extract a JSON field as raw bytes.
    /// @param input UTF-8 encoded JSON bytes.
    /// @param key   JSON key to extract.
    /// @return value Raw bytes of the field value.
    function extractAsBytes(bytes memory input, string memory key)
        external
        view
        returns (bytes memory value);

    /// @notice Extract a JSON field as a list of bytes arrays.
    /// @param input UTF-8 encoded JSON bytes.
    /// @param key   JSON key pointing to an array.
    /// @return value Array of bytes, one element per JSON array item.
    function extractAsBytesList(bytes memory input, string memory key)
        external
        view
        returns (bytes[] memory value);

    /// @notice Extract a JSON field as a uint256.
    /// @param input UTF-8 encoded JSON bytes.
    /// @param key   JSON key with a numeric value.
    /// @return value The numeric value as uint256.
    function extractAsUint256(bytes memory input, string memory key)
        external
        view
        returns (uint256 value);
}
