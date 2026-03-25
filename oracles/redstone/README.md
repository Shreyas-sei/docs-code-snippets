# RedStone Oracle Consumer on Sei

Demonstrates how to consume RedStone oracle price data on Sei EVM using the Classic integration model, where price data is appended to calldata by the RedStone SDK.

## Overview

RedStone's Classic model works differently from Chainlink/Pyth:

- **No on-chain price store** — data is injected into the transaction calldata at call time
- **Cryptographically signed** — each price payload is signed by RedStone data providers
- **The SDK wraps your contract calls** — use `WrapperBuilder` in TypeScript/JavaScript

## Files

| File | Description |
|------|-------------|
| `contracts/RedstoneConsumer.sol` | Price consumer inheriting from `MainDemoConsumerBase` |

## Setup

```bash
npm install @redstone-finance/evm-connector ethers
```

### hardhat.config.js

```js
networks: {
  sei: {
    url: "https://evm-rpc.sei-apis.com",
    chainId: 1329,
    accounts: [process.env.PRIVATE_KEY],
  },
}
```

## Calling from JavaScript/TypeScript

You must wrap contract calls with the `WrapperBuilder` so RedStone injects price data:

```typescript
import { ethers } from "ethers";
import { WrapperBuilder } from "@redstone-finance/evm-connector";
import RedstoneConsumerABI from "./artifacts/contracts/RedstoneConsumer.sol/RedstoneConsumer.json";

const provider = new ethers.JsonRpcProvider("https://evm-rpc.sei-apis.com");
const signer = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);

const contract = new ethers.Contract(
  "0xYOUR_CONTRACT_ADDRESS",
  RedstoneConsumerABI.abi,
  signer
);

// Wrap the contract — data service injects price payloads automatically
const wrapped = WrapperBuilder
  .fromDataService("redstone-main-demo")
  .wrap(contract);

// Now call as normal
const seiPrice = await wrapped.getSEIPrice();
console.log("SEI/USD:", Number(seiPrice) / 1e8);

// Get multiple prices in one call
const [sei, eth, btc] = await wrapped.getBasePrices();
console.log("SEI:", Number(sei) / 1e8);
console.log("ETH:", Number(eth) / 1e8);
console.log("BTC:", Number(btc) / 1e8);
```

## Price Format

Prices are returned with **8 decimal places**:

```
actualPrice = rawValue / 10^8
```

For example, if `getSEIPrice()` returns `45000000`, the price is `$0.45`.

## Data Services

| Service ID | Description |
|-----------|-------------|
| `redstone-main-demo` | Demo/testing data service |
| `redstone-primary-prod` | Production data service |

Full list: https://app.redstone.finance/#/app/data-services

## References

- [RedStone on Sei EVM](https://docs.sei.io/evm/oracles/redstone)
- [RedStone EVM Connector](https://github.com/redstone-finance/redstone-oracles-monorepo/tree/main/packages/evm-connector)
- [RedStone Data Services](https://app.redstone.finance/#/app/data-services)
