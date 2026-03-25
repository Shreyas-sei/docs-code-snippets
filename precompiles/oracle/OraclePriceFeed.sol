// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IOracle.sol";

/// @title OraclePriceFeed
/// @notice A price feed consumer that reads asset prices from the Sei oracle
///         precompile and exposes them to other contracts.
///
/// @dev Uses the Sei Oracle precompile at 0x0000000000000000000000000000000000001008.
///
/// The oracle returns prices as decimal strings (e.g. "0.512345678900000000").
/// This contract converts them to uint256 with 18-decimal precision for
/// compatibility with DeFi primitives.
contract OraclePriceFeed {
    // ─── Constants ────────────────────────────────────────────────────────────

    IOracle constant ORACLE =
        IOracle(0x0000000000000000000000000000000000001008);

    /// @dev 18-decimal scaling factor used throughout.
    uint256 constant PRECISION = 1e18;

    // ─── State ────────────────────────────────────────────────────────────────

    address public owner;

    /// @notice Cached prices: denom => price in 18-decimal uint256.
    mapping(string => uint256) public cachedPrices;

    /// @notice Timestamp of last cache update per denom.
    mapping(string => uint256) public lastUpdated;

    /// @notice Maximum age (seconds) before a cached price is considered stale.
    uint256 public stalePriceThreshold = 300; // 5 minutes

    // ─── Events ───────────────────────────────────────────────────────────────

    event PriceCached(string denom, uint256 price, uint256 timestamp);
    event StalePriceThresholdUpdated(uint256 newThreshold);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error PriceStale(string denom, uint256 lastUpdate);
    error InvalidPrice();
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

    // ─── Price Feed Functions ─────────────────────────────────────────────────

    /// @notice Get the live exchange rate for a denomination directly from the oracle.
    /// @param denom Token denomination (e.g. "SEI", "BTC", "ETH").
    /// @return rate Decimal string (e.g. "0.512345678900000000").
    function getLiveExchangeRate(string calldata denom)
        external
        view
        returns (string memory rate)
    {
        return ORACLE.getExchangeRate(denom);
    }

    /// @notice Get all live exchange rates from the oracle.
    /// @return rates Array of DenomOracleExchangeRatePair.
    function getAllExchangeRates()
        external
        view
        returns (IOracle.DenomOracleExchangeRatePair[] memory rates)
    {
        return ORACLE.getExchangeRates();
    }

    /// @notice Get TWAP prices for a given lookback window.
    /// @param lookbackSeconds Lookback duration in seconds (e.g. 3600 for 1h TWAP).
    /// @return twaps Array of OracleTwap.
    function getTwapPrices(uint64 lookbackSeconds)
        external
        view
        returns (IOracle.OracleTwap[] memory twaps)
    {
        return ORACLE.getOracleTwaps(lookbackSeconds);
    }

    // ─── Cache Functions ──────────────────────────────────────────────────────

    /// @notice Update the cached price for a denomination from the live oracle.
    ///         Parses the oracle's decimal string into a uint256 with 18 decimals.
    /// @param denom Token denomination to cache.
    function updateCachedPrice(string calldata denom) external {
        string memory rateStr = ORACLE.getExchangeRate(denom);
        uint256 price = _parseDecimalString(rateStr);
        cachedPrices[denom] = price;
        lastUpdated[denom] = block.timestamp;
        emit PriceCached(denom, price, block.timestamp);
    }

    /// @notice Update cached prices for multiple denominations at once.
    function updateMultipleCachedPrices(string[] calldata denoms) external {
        for (uint256 i = 0; i < denoms.length; i++) {
            string memory rateStr = ORACLE.getExchangeRate(denoms[i]);
            uint256 price = _parseDecimalString(rateStr);
            cachedPrices[denoms[i]] = price;
            lastUpdated[denoms[i]] = block.timestamp;
            emit PriceCached(denoms[i], price, block.timestamp);
        }
    }

    /// @notice Returns the cached price for a denom, reverting if stale.
    /// @param denom Token denomination.
    /// @return price Price in 18-decimal uint256.
    function getCachedPrice(string calldata denom)
        external
        view
        returns (uint256 price)
    {
        uint256 updated = lastUpdated[denom];
        if (block.timestamp - updated > stalePriceThreshold) {
            revert PriceStale(denom, updated);
        }
        return cachedPrices[denom];
    }

    // ─── Admin Functions ──────────────────────────────────────────────────────

    /// @notice Update the stale price threshold.
    function setStalePriceThreshold(uint256 newThreshold) external onlyOwner {
        stalePriceThreshold = newThreshold;
        emit StalePriceThresholdUpdated(newThreshold);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    // ─── Internal Helpers ────────────────────────────────────────────────────

    /// @notice Parse a decimal string like "0.512345678900000000" into a
    ///         uint256 with 18-decimal precision.
    /// @dev Handles both integer strings (e.g. "2") and decimal strings.
    function _parseDecimalString(string memory s)
        internal
        pure
        returns (uint256 result)
    {
        bytes memory b = bytes(s);
        uint256 dotPos = type(uint256).max;

        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] == '.') {
                dotPos = i;
                break;
            }
        }

        if (dotPos == type(uint256).max) {
            // No decimal point — treat as integer
            result = _parseUint(b, 0, b.length);
            return result * PRECISION;
        }

        uint256 intPart  = _parseUint(b, 0, dotPos);
        uint256 fracLen  = b.length - dotPos - 1;

        // Limit to 18 decimal places
        uint256 fracDigits = fracLen > 18 ? 18 : fracLen;
        uint256 fracPart   = _parseUint(b, dotPos + 1, dotPos + 1 + fracDigits);

        // Scale fracPart to 18 decimals
        uint256 scale = 10 ** (18 - fracDigits);

        result = intPart * PRECISION + fracPart * scale;
    }

    function _parseUint(bytes memory b, uint256 start, uint256 end)
        internal
        pure
        returns (uint256 v)
    {
        for (uint256 i = start; i < end; i++) {
            uint8 d = uint8(b[i]) - 48;
            if (d > 9) break;
            v = v * 10 + d;
        }
    }
}
