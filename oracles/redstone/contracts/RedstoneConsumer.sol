// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@redstone-finance/evm-connector/contracts/data-services/MainDemoConsumerBase.sol";

/**
 * @title RedstoneConsumer
 * @notice Consumes RedStone oracle price data on Sei EVM
 * @dev RedStone uses a unique "on-demand" delivery model (Classic variant):
 *      price data is appended to the calldata by the RedStone SDK at the frontend/script level.
 *      The contract extracts and validates this data automatically via the inherited base contract.
 *
 * RedStone supports two integration models:
 *   1. Classic (this contract) — data is injected into calldata via the JS SDK
 *   2. Core  — data is fetched from the RedStone cache layer and passed explicitly
 *
 * When calling functions on this contract from JS/TS, wrap the call with the RedStone
 * WrapperBuilder so that price data is automatically appended:
 *
 *   import { WrapperBuilder } from "@redstone-finance/evm-connector";
 *
 *   const wrapped = WrapperBuilder
 *     .fromDataService("redstone-main-demo")
 *     .wrap(contract);
 *
 *   const price = await wrapped.getSEIPrice();
 *
 * Supported data services: https://app.redstone.finance/#/app/data-services
 */
contract RedstoneConsumer is MainDemoConsumerBase {
    // ─────────────────────────────────────────────
    // Single-asset reads
    // ─────────────────────────────────────────────

    /**
     * @notice Returns the SEI/USD price (8 decimals) injected via calldata
     * @dev Call this via the RedStone WrapperBuilder in your JS client
     */
    function getSEIPrice() external view returns (uint256) {
        return getOracleNumericValueFromTxMsg(bytes32("SEI"));
    }

    /**
     * @notice Returns the BTC/USD price (8 decimals)
     */
    function getBTCPrice() external view returns (uint256) {
        return getOracleNumericValueFromTxMsg(bytes32("BTC"));
    }

    /**
     * @notice Returns the ETH/USD price (8 decimals)
     */
    function getETHPrice() external view returns (uint256) {
        return getOracleNumericValueFromTxMsg(bytes32("ETH"));
    }

    /**
     * @notice Returns the price for any ticker symbol supported by the data service
     * @param symbol The asset ticker as a bytes32-encoded string (e.g. bytes32("USDC"))
     */
    function getPrice(bytes32 symbol) external view returns (uint256) {
        return getOracleNumericValueFromTxMsg(symbol);
    }

    // ─────────────────────────────────────────────
    // Multi-asset reads
    // ─────────────────────────────────────────────

    /**
     * @notice Returns prices for multiple assets in a single call
     * @dev Reduces transaction overhead when multiple prices are needed atomically
     * @param symbols Array of bytes32-encoded ticker symbols
     * @return prices Array of prices in the same order as symbols (8 decimals each)
     */
    function getMultiplePrices(bytes32[] memory symbols)
        external
        view
        returns (uint256[] memory prices)
    {
        prices = getOracleNumericValuesFromTxMsg(symbols);
    }

    /**
     * @notice Returns SEI, ETH, and BTC prices in a single call
     */
    function getBasePrices()
        external
        view
        returns (uint256 seiPrice, uint256 ethPrice, uint256 btcPrice)
    {
        bytes32[] memory symbols = new bytes32[](3);
        symbols[0] = bytes32("SEI");
        symbols[1] = bytes32("ETH");
        symbols[2] = bytes32("BTC");

        uint256[] memory prices = getOracleNumericValuesFromTxMsg(symbols);
        return (prices[0], prices[1], prices[2]);
    }

    // ─────────────────────────────────────────────
    // Price-gated example
    // ─────────────────────────────────────────────

    /**
     * @notice Example function that uses a price guard — executes logic only if SEI/USD >= minPrice
     * @dev Shows how to embed RedStone price validation into business logic
     * @param minPrice Minimum acceptable SEI price in USD (8 decimals, e.g. 50000000 = $0.50)
     */
    function executeIfPriceAbove(uint256 minPrice) external view returns (bool executed) {
        uint256 currentPrice = getOracleNumericValueFromTxMsg(bytes32("SEI"));
        require(currentPrice >= minPrice, "RedstoneConsumer: price below minimum");
        // Insert your guarded business logic here
        return true;
    }
}
