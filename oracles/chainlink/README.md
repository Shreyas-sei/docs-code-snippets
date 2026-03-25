# Chainlink Data Feeds on Sei

Demonstrates how to consume Chainlink price feed data on Sei EVM using the standard `AggregatorV3Interface`.

## Overview

Chainlink Data Feeds provide reliable, decentralised price data. On Sei EVM, Chainlink aggregators are deployed as standard EVM contracts that implement `AggregatorV3Interface`, so the same Solidity patterns you use on Ethereum apply here.

## Files

| File | Description |
|------|-------------|
| `contracts/ChainlinkConsumer.sol` | Price feed consumer with staleness checks and 18-decimal scaling |

## Key Concepts

- **`latestRoundData()`** – returns `(roundId, answer, startedAt, updatedAt, answeredInRound)`
- **Decimals** – most USD feeds use 8 decimals; divide the raw answer by `10**decimals()` to get the USD value
- **Staleness check** – always verify `updatedAt` is recent to avoid acting on stale prices
- **`answeredInRound >= roundId`** – guards against incomplete rounds

## Setup

```bash
npm install @chainlink/contracts
```

### hardhat.config.js network entry

```js
sei: {
  url: "https://evm-rpc.sei-apis.com",
  chainId: 1329,
  accounts: [process.env.PRIVATE_KEY],
}
```

## Usage

```solidity
// Deploy with the SEI/USD aggregator address for Sei mainnet
ChainlinkConsumer consumer = new ChainlinkConsumer(0xSEI_USD_FEED_ADDRESS);

// Read the latest price (8 decimals)
int256 price = consumer.getLatestPrice();

// Read with staleness check (max 1 hour old)
int256 safePrice = consumer.getSafePriceWithStalenessCheck(3600);

// Get price scaled to 18 decimals
uint256 price18 = consumer.getPriceWith18Decimals();
```

## Feed Addresses

Check [Chainlink docs](https://docs.chain.link/data-feeds/price-feeds/addresses?network=sei) for the latest feed addresses on Sei mainnet and testnet.

## References

- [Chainlink Data Feeds — Sei](https://docs.chain.link/data-feeds/price-feeds/addresses?network=sei)
- [Sei EVM Docs](https://docs.sei.io/evm/oracles/chainlink)
- [AggregatorV3Interface](https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol)
