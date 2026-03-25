// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title ChainlinkConsumer
 * @notice Consumes Chainlink Data Feeds on Sei EVM
 * @dev Demonstrates reading price data from Chainlink aggregator contracts deployed on Sei
 *
 * Chainlink Data Feed addresses on Sei:
 *   SEI/USD  — check https://docs.chain.link/data-feeds/price-feeds/addresses?network=sei for current addresses
 *   ETH/USD  — check https://docs.chain.link/data-feeds/price-feeds/addresses?network=sei for current addresses
 *   BTC/USD  — check https://docs.chain.link/data-feeds/price-feeds/addresses?network=sei for current addresses
 */
contract ChainlinkConsumer {
    AggregatorV3Interface internal priceFeed;

    // Address of the Chainlink aggregator for SEI/USD on Sei mainnet
    // Update this to the correct feed address for your use case
    address public constant SEI_USD_FEED = 0x0000000000000000000000000000000000000000; // placeholder — set at deploy

    /**
     * @notice Initialise with the Chainlink aggregator address for the desired pair
     * @param aggregatorAddress The Chainlink price feed aggregator contract address
     */
    constructor(address aggregatorAddress) {
        priceFeed = AggregatorV3Interface(aggregatorAddress);
    }

    // ─────────────────────────────────────────────
    // Core price-reading functions
    // ─────────────────────────────────────────────

    /**
     * @notice Returns the latest price from the feed
     * @return price The latest answer (scaled by 10**decimals())
     */
    function getLatestPrice() public view returns (int256 price) {
        (, price, , , ) = priceFeed.latestRoundData();
    }

    /**
     * @notice Returns the latest price with full round metadata
     * @return roundId      The Chainlink round ID
     * @return answer       Raw price answer
     * @return startedAt    Timestamp when the round started
     * @return updatedAt    Timestamp of the last price update
     * @return answeredInRound  Round ID in which the answer was computed
     */
    function getLatestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return priceFeed.latestRoundData();
    }

    /**
     * @notice Returns the number of decimals used by this feed
     * @dev Most USD feeds use 8 decimals; divide the raw answer by 10**decimals() to get USD value
     */
    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }

    /**
     * @notice Returns the human-readable description of this feed (e.g. "SEI / USD")
     */
    function getDescription() public view returns (string memory) {
        return priceFeed.description();
    }

    /**
     * @notice Returns the price scaled to 18 decimals for convenient use with ERC-20 arithmetic
     */
    function getPriceWith18Decimals() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "ChainlinkConsumer: negative price");
        uint8 feedDecimals = priceFeed.decimals();
        // Scale up from feedDecimals to 18
        return uint256(price) * (10 ** (18 - feedDecimals));
    }

    /**
     * @notice Validates that the latest round data is fresh (not stale)
     * @param stalePeriod Maximum acceptable age in seconds for the price (e.g. 3600 = 1 hour)
     * @return price The latest answer if valid
     */
    function getSafePriceWithStalenessCheck(uint256 stalePeriod)
        public
        view
        returns (int256 price)
    {
        uint80 roundId;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;

        (roundId, price, startedAt, updatedAt, answeredInRound) = priceFeed.latestRoundData();

        require(price > 0, "ChainlinkConsumer: invalid price");
        require(updatedAt != 0, "ChainlinkConsumer: incomplete round");
        require(answeredInRound >= roundId, "ChainlinkConsumer: stale round");
        require(
            block.timestamp - updatedAt <= stalePeriod,
            "ChainlinkConsumer: price too stale"
        );
    }

    // ─────────────────────────────────────────────
    // Historical data
    // ─────────────────────────────────────────────

    /**
     * @notice Reads data for a specific historical round
     * @param roundId The round ID to query
     */
    function getHistoricalPrice(uint80 roundId)
        public
        view
        returns (
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt
        )
    {
        (, answer, startedAt, updatedAt, ) = priceFeed.getRoundData(roundId);
    }

    // ─────────────────────────────────────────────
    // Feed management
    // ─────────────────────────────────────────────

    /**
     * @notice Updates the price feed aggregator address (owner-only pattern omitted for brevity)
     * @param newAggregator New aggregator contract address
     */
    function updatePriceFeed(address newAggregator) external {
        require(newAggregator != address(0), "ChainlinkConsumer: zero address");
        priceFeed = AggregatorV3Interface(newAggregator);
    }
}
