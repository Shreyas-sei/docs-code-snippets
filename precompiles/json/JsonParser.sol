// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IJson.sol";

/// @title JsonParser
/// @notice Utility contract for parsing JSON data on-chain using the Sei JSON
///         precompile. Useful for decoding oracle responses, CosmWasm query
///         results, and any arbitrary JSON payload passed as calldata.
///
/// @dev Uses the Sei JSON precompile at 0x0000000000000000000000000000000000001003.
///
/// Example JSON that can be parsed:
/// ```json
/// { "price": 100, "symbol": "SEI", "decimals": 6, "tags": ["defi", "staking"] }
/// ```
contract JsonParser {
    // ─── Constants ────────────────────────────────────────────────────────────

    IJson constant JSON_PRECOMPILE =
        IJson(0x0000000000000000000000000000000000001003);

    // ─── Events ───────────────────────────────────────────────────────────────

    event Parsed(string key, bytes value);

    // ─── String Extraction ────────────────────────────────────────────────────

    /// @notice Extract a string field from a JSON payload.
    /// @param jsonBytes UTF-8 encoded JSON bytes.
    /// @param key       JSON key.
    /// @return value    Decoded UTF-8 string.
    function extractString(bytes calldata jsonBytes, string calldata key)
        external
        view
        returns (string memory value)
    {
        bytes memory raw = JSON_PRECOMPILE.extractAsBytes(jsonBytes, key);
        return string(raw);
    }

    // ─── Numeric Extraction ───────────────────────────────────────────────────

    /// @notice Extract a uint256 field from a JSON payload.
    /// @param jsonBytes UTF-8 encoded JSON bytes.
    /// @param key       JSON key with a numeric value.
    /// @return value    uint256 representation.
    function extractUint256(bytes calldata jsonBytes, string calldata key)
        external
        view
        returns (uint256 value)
    {
        return JSON_PRECOMPILE.extractAsUint256(jsonBytes, key);
    }

    // ─── Bytes Extraction ─────────────────────────────────────────────────────

    /// @notice Extract a raw bytes field from a JSON payload.
    /// @param jsonBytes UTF-8 encoded JSON bytes.
    /// @param key       JSON key.
    /// @return value    Raw bytes.
    function extractBytes(bytes calldata jsonBytes, string calldata key)
        external
        view
        returns (bytes memory value)
    {
        return JSON_PRECOMPILE.extractAsBytes(jsonBytes, key);
    }

    // ─── Array Extraction ─────────────────────────────────────────────────────

    /// @notice Extract a JSON array field as a list of byte arrays.
    /// @param jsonBytes UTF-8 encoded JSON bytes.
    /// @param key       JSON key pointing to an array.
    /// @return items    Array of bytes, one per JSON array element.
    function extractBytesList(bytes calldata jsonBytes, string calldata key)
        external
        view
        returns (bytes[] memory items)
    {
        return JSON_PRECOMPILE.extractAsBytesList(jsonBytes, key);
    }

    /// @notice Extract a JSON string array as a string array.
    /// @param jsonBytes UTF-8 encoded JSON bytes.
    /// @param key       JSON key pointing to a string array.
    /// @return items    Decoded string array.
    function extractStringArray(bytes calldata jsonBytes, string calldata key)
        external
        view
        returns (string[] memory items)
    {
        bytes[] memory rawItems = JSON_PRECOMPILE.extractAsBytesList(jsonBytes, key);
        items = new string[](rawItems.length);
        for (uint256 i = 0; i < rawItems.length; i++) {
            items[i] = string(rawItems[i]);
        }
    }

    // ─── Multi-Key Extraction ─────────────────────────────────────────────────

    /// @notice Extract multiple string fields in a single call.
    /// @param jsonBytes UTF-8 encoded JSON bytes.
    /// @param keys      Array of JSON keys to extract.
    /// @return values   Array of decoded UTF-8 strings, aligned to keys.
    function extractMultipleStrings(bytes calldata jsonBytes, string[] calldata keys)
        external
        view
        returns (string[] memory values)
    {
        values = new string[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            bytes memory raw = JSON_PRECOMPILE.extractAsBytes(jsonBytes, keys[i]);
            values[i] = string(raw);
        }
    }

    /// @notice Extract multiple uint256 fields in a single call.
    /// @param jsonBytes UTF-8 encoded JSON bytes.
    /// @param keys      Array of JSON keys to extract.
    /// @return values   Array of uint256 values, aligned to keys.
    function extractMultipleUints(bytes calldata jsonBytes, string[] calldata keys)
        external
        view
        returns (uint256[] memory values)
    {
        values = new uint256[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            values[i] = JSON_PRECOMPILE.extractAsUint256(jsonBytes, keys[i]);
        }
    }

    // ─── Combined Price Data Decoder ─────────────────────────────────────────

    /// @notice Convenience decoder for a standard price-data JSON:
    ///         { "symbol": "...", "price": <uint>, "decimals": <uint> }
    /// @param jsonBytes UTF-8 encoded JSON bytes.
    /// @return symbol   Asset symbol string.
    /// @return price    Price as uint256.
    /// @return decimals Decimal precision as uint256.
    function decodePriceData(bytes calldata jsonBytes)
        external
        view
        returns (
            string memory symbol,
            uint256 price,
            uint256 decimals
        )
    {
        bytes memory symBytes = JSON_PRECOMPILE.extractAsBytes(jsonBytes, "symbol");
        symbol = string(symBytes);
        price = JSON_PRECOMPILE.extractAsUint256(jsonBytes, "price");
        decimals = JSON_PRECOMPILE.extractAsUint256(jsonBytes, "decimals");
    }
}
