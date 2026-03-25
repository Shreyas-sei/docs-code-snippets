# Oracle Precompile

Solidity contracts for reading on-chain asset prices from the Sei oracle
precompile, including spot rates and TWAP prices.

**Precompile address:** `0x0000000000000000000000000000000000001008`

## Files

| File | Description |
|------|-------------|
| `interfaces/IOracle.sol` | Full oracle precompile interface |
| `OraclePriceFeed.sol` | Price feed consumer with caching and staleness protection |

## Interface Overview

```solidity
interface IOracle {
    // Get spot exchange rate for one denom (returns decimal string)
    function getExchangeRate(string memory denom) external view returns (string memory);

    // Get all exchange rates
    function getExchangeRates() external view returns (DenomOracleExchangeRatePair[] memory);

    // Get TWAP prices over a lookback window
    function getOracleTwaps(uint64 lookbackSeconds) external view returns (OracleTwap[] memory);

    // Get oracle module parameters
    function getOracleParams() external view returns (OracleParams memory);
}
```

## Usage Examples

### Read a Price (Solidity)

```solidity
IOracle constant ORACLE = IOracle(0x0000000000000000000000000000000000001008);

string memory seiRate = ORACLE.getExchangeRate("SEI");
// Returns a decimal string, e.g. "0.512345678900000000"
```

### Read All Prices (Solidity)

```solidity
IOracle.DenomOracleExchangeRatePair[] memory rates = ORACLE.getExchangeRates();
for (uint i = 0; i < rates.length; i++) {
    // rates[i].denom
    // rates[i].oracleExchangeRateStr
    // rates[i].lastUpdate (Unix seconds)
}
```

### Get TWAP (Solidity)

```solidity
// Get 1-hour TWAP prices
IOracle.OracleTwap[] memory twaps = ORACLE.getOracleTwaps(3600);
```

## Notes

- Exchange rates are returned as **decimal strings** (e.g. `"0.5123456789"`).
- Use `OraclePriceFeed._parseDecimalString()` to convert to `uint256` with 18-decimal precision.
- TWAP lookback window must be within the oracle's configured lookback limit.

## Deployment

```bash
npx hardhat run scripts/deploy.js --network sei-mainnet
```

## References

- [Oracle Precompile Docs](https://docs.sei.io/evm/precompiles/oracle)
