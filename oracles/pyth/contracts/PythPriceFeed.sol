// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

/**
 * @title PythPriceFeed
 * @notice Consumes Pyth Network price feeds on Sei EVM
 * @dev Pyth prices require an on-chain update before they can be read.
 *      The caller must supply a fresh price update VAA (obtained from the Pyth Hermes API)
 *      and pass it to updatePriceFeeds() before (or atomically with) reading the price.
 *
 * Pyth contract address on Sei:
 *   Mainnet:  0xA2aa501b19aff244D90cc15a4Cf739D2725B5729
 *   Testnet:  0xA2aa501b19aff244D90cc15a4Cf739D2725B5729  (same address, EVM-based)
 *
 * Common price feed IDs (bytes32):
 *   SEI/USD:  0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace
 *   ETH/USD:  0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace  (example)
 *   BTC/USD:  0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43
 *
 * Full list: https://pyth.network/developers/price-feed-ids
 */
contract PythPriceFeed {
    IPyth public immutable pyth;

    // Price feed IDs — set at construction time
    mapping(bytes32 => bool) public registeredFeeds;
    bytes32[] public feedIds;

    event PriceUpdated(bytes32 indexed feedId, int64 price, uint64 publishTime);

    /**
     * @param pythContract Address of the Pyth contract on Sei
     * @param _feedIds     List of price feed IDs to register (e.g. SEI/USD, ETH/USD)
     */
    constructor(address pythContract, bytes32[] memory _feedIds) {
        pyth = IPyth(pythContract);
        for (uint256 i = 0; i < _feedIds.length; i++) {
            registeredFeeds[_feedIds[i]] = true;
            feedIds.push(_feedIds[i]);
        }
    }

    // ─────────────────────────────────────────────
    // Price update
    // ─────────────────────────────────────────────

    /**
     * @notice Updates price feeds on-chain using Pyth price update data
     * @dev Must be called before getPrice() if the cached price is stale.
     *      Obtain updateData from the Pyth Hermes API:
     *        https://hermes.pyth.network/api/latest_vaas?ids[]=<feedId>
     * @param updateData Array of VAAs returned by the Hermes API
     */
    function updatePriceFeeds(bytes[] calldata updateData) external payable {
        uint256 fee = pyth.getUpdateFee(updateData);
        require(msg.value >= fee, "PythPriceFeed: insufficient update fee");
        pyth.updatePriceFeeds{value: fee}(updateData);
        // Refund excess ETH
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }
    }

    /**
     * @notice Returns the update fee for a given set of update data
     */
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint256) {
        return pyth.getUpdateFee(updateData);
    }

    // ─────────────────────────────────────────────
    // Price reading
    // ─────────────────────────────────────────────

    /**
     * @notice Returns the latest cached price for a feed (may be stale)
     * @param feedId The price feed ID
     * @return price       Raw price (must be divided by 10**abs(expo))
     * @return conf        Confidence interval
     * @return expo        Price exponent (negative, e.g. -8 means divide by 10^8)
     * @return publishTime Timestamp when the price was published
     */
    function getPrice(bytes32 feedId)
        public
        view
        returns (
            int64 price,
            uint64 conf,
            int32 expo,
            uint256 publishTime
        )
    {
        PythStructs.Price memory p = pyth.getPriceUnsafe(feedId);
        return (p.price, p.conf, p.expo, p.publishTime);
    }

    /**
     * @notice Returns the price, asserting it is no older than maxAge seconds
     * @param feedId The price feed ID
     * @param maxAge Maximum acceptable age in seconds (e.g. 60)
     */
    function getPriceNoOlderThan(bytes32 feedId, uint256 maxAge)
        public
        view
        returns (
            int64 price,
            uint64 conf,
            int32 expo,
            uint256 publishTime
        )
    {
        PythStructs.Price memory p = pyth.getPriceNoOlderThan(feedId, maxAge);
        return (p.price, p.conf, p.expo, p.publishTime);
    }

    /**
     * @notice Converts a raw Pyth price to a uint256 scaled to 18 decimals
     * @param feedId The price feed ID
     * @param maxAge Maximum acceptable age in seconds
     */
    function getPriceAsUint256(bytes32 feedId, uint256 maxAge)
        public
        view
        returns (uint256)
    {
        PythStructs.Price memory p = pyth.getPriceNoOlderThan(feedId, maxAge);
        require(p.price > 0, "PythPriceFeed: negative price");

        // expo is negative (e.g. -8), so actual value = price * 10^expo
        // Scale to 18 decimals: multiply by 10^(18 + expo)
        uint256 absExpo = uint256(int256(-p.expo));
        if (absExpo <= 18) {
            return uint256(int256(p.price)) * (10 ** (18 - absExpo));
        } else {
            return uint256(int256(p.price)) / (10 ** (absExpo - 18));
        }
    }

    /**
     * @notice Atomically updates price feeds and returns the latest price
     * @param feedId     The price feed ID to read
     * @param updateData VAA update data from Hermes API
     * @param maxAge     Maximum acceptable age in seconds after update
     */
    function updateAndGetPrice(
        bytes32 feedId,
        bytes[] calldata updateData,
        uint256 maxAge
    ) external payable returns (int64 price, uint64 conf, int32 expo, uint256 publishTime) {
        uint256 fee = pyth.getUpdateFee(updateData);
        require(msg.value >= fee, "PythPriceFeed: insufficient fee");
        pyth.updatePriceFeeds{value: fee}(updateData);
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }
        PythStructs.Price memory p = pyth.getPriceNoOlderThan(feedId, maxAge);
        return (p.price, p.conf, p.expo, p.publishTime);
    }

    /**
     * @notice Registers a new price feed ID
     */
    function registerFeed(bytes32 feedId) external {
        if (!registeredFeeds[feedId]) {
            registeredFeeds[feedId] = true;
            feedIds.push(feedId);
        }
    }

    /**
     * @notice Returns all registered feed IDs
     */
    function getAllFeedIds() external view returns (bytes32[] memory) {
        return feedIds;
    }
}
