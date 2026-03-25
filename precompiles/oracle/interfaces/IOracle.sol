// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IOracle
/// @notice Interface for the Sei Oracle precompile.
/// @dev Precompile address: 0x0000000000000000000000000000000000001008
interface IOracle {
    // ─── Structs ──────────────────────────────────────────────────────────────

    /// @notice Exchange rate for a denomination.
    struct DenomOracleExchangeRatePair {
        /// @dev Token denomination (e.g. "SEI", "ETH", "BTC").
        string denom;
        /// @dev Oracle exchange rate as a decimal string (e.g. "0.5123456789").
        string oracleExchangeRateStr;
        /// @dev Last update timestamp (Unix seconds).
        int64 lastUpdate;
        /// @dev Last update block height.
        int64 lastUpdateTimestamp;
    }

    /// @notice TWAP (time-weighted average price) data for a denomination.
    struct OracleTwap {
        /// @dev Token denomination.
        string denom;
        /// @dev TWAP as a decimal string.
        string twap;
        /// @dev Lookback duration in seconds.
        int64 lookbackSeconds;
    }

    /// @notice Oracle module parameters.
    struct OracleParams {
        int64 votePeriod;
        string voteThreshold;
        string rewardBand;
        string[] whitelist;
        string slashFraction;
        int64 slashWindow;
        string minValidPerWindow;
    }

    // ─── View Methods ─────────────────────────────────────────────────────────

    /// @notice Get the current exchange rate for a single denomination.
    /// @param denom Token denomination (e.g. "SEI").
    /// @return exchangeRate Decimal string representation of the price.
    function getExchangeRate(string memory denom)
        external
        view
        returns (string memory exchangeRate);

    /// @notice Get exchange rates for all whitelisted denominations.
    /// @return rates Array of DenomOracleExchangeRatePair.
    function getExchangeRates()
        external
        view
        returns (DenomOracleExchangeRatePair[] memory rates);

    /// @notice Get TWAP prices for all denominations over the given lookback window.
    /// @param lookbackSeconds Lookback duration in seconds.
    /// @return twaps Array of OracleTwap.
    function getOracleTwaps(uint64 lookbackSeconds)
        external
        view
        returns (OracleTwap[] memory twaps);

    /// @notice Get oracle module parameters.
    /// @return params OracleParams struct.
    function getOracleParams() external view returns (OracleParams memory params);
}
