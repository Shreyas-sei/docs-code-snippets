# Pyth Network Price Feeds on Sei

Demonstrates how to consume Pyth Network price data on Sei EVM, including fetching price update VAAs from the Hermes API and submitting them on-chain.

## Overview

Pyth uses a pull-based model: prices are published off-chain and must be pushed on-chain before they can be consumed. The workflow is:

1. Fetch a fresh price update VAA from the [Pyth Hermes API](https://hermes.pyth.network)
2. Call `updatePriceFeeds()` on-chain with the VAA (paying a small fee)
3. Read the price via `getPriceNoOlderThan()` or `getPriceUnsafe()`

## Files

| File | Description |
|------|-------------|
| `contracts/PythPriceFeed.sol` | Consumer contract with update, read, and staleness-check helpers |
| `scripts/updateAndRead.js` | End-to-end script: fetch VAA, update on-chain, read price |

## Contract Addresses

| Network | Pyth Contract |
|---------|--------------|
| Sei Mainnet | `0xA2aa501b19aff244D90cc15a4Cf739D2725B5729` |
| Sei Testnet | `0xA2aa501b19aff244D90cc15a4Cf739D2725B5729` |

## Common Price Feed IDs

| Pair | Feed ID |
|------|---------|
| SEI/USD | `0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace` |
| BTC/USD | `0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43` |
| ETH/USD | `0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace` |

Full list: https://pyth.network/developers/price-feed-ids

## Setup

```bash
npm install @pythnetwork/pyth-sdk-solidity axios
```

### hardhat.config.js

```js
networks: {
  sei: {
    url: "https://evm-rpc.sei-apis.com",
    chainId: 1329,
    accounts: [process.env.PRIVATE_KEY],
  },
  seiTestnet: {
    url: "https://evm-rpc-testnet.sei-apis.com",
    chainId: 713715,
    accounts: [process.env.PRIVATE_KEY],
  },
}
```

## Running the Script

```bash
# Deploy fresh and run
PRIVATE_KEY=0x... npx hardhat run scripts/updateAndRead.js --network sei

# Attach to existing contract
PRIVATE_KEY=0x... PYTH_CONTRACT=0x... npx hardhat run scripts/updateAndRead.js --network sei
```

## Price Format

Pyth prices are returned as `(price, conf, expo, publishTime)`. The actual USD value is:

```
actualPrice = price * 10^expo
```

For example, if `price = 35000000000` and `expo = -8`, then `actualPrice = $350.00`.

## References

- [Pyth on Sei EVM](https://docs.sei.io/evm/oracles/pyth)
- [Pyth SDK Solidity](https://github.com/pyth-network/pyth-sdk-solidity)
- [Pyth Hermes API](https://hermes.pyth.network/docs)
- [Pyth Price Feed IDs](https://pyth.network/developers/price-feed-ids)
