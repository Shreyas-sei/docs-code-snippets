# API3 dAPI Consumer on Sei

Demonstrates how to read API3 dAPI (decentralised API) price feeds on Sei EVM. API3 dAPIs are backed by first-party oracles and provide a simple `read()` interface via proxy contracts.

## Overview

API3 uses a **proxy-based** model:

- Each dAPI (e.g. SEI/USD) has a proxy contract with a single `read()` function
- Proxy contracts are deployed per dAPI via the API3 Market
- Prices are 18-decimal signed integers (`int224`)

## Files

| File | Description |
|------|-------------|
| `contracts/Api3Consumer.sol` | dAPI reader with staleness checks and multi-feed support |

## Getting Proxy Addresses

1. Go to [https://market.api3.org](https://market.api3.org)
2. Select the **Sei** network
3. Choose your desired data feed (e.g. SEI/USD)
4. Activate/deploy the proxy and copy its address

## Setup

```bash
npm install @api3/contracts ethers hardhat
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
    chainId: 1328,
    accounts: [process.env.PRIVATE_KEY],
  },
}
```

## Deployment

```js
const Api3Consumer = await ethers.getContractFactory("Api3Consumer");
const consumer = await Api3Consumer.deploy(
  ["SEI/USD", "ETH/USD"],
  ["0xSEI_USD_PROXY_ADDRESS", "0xETH_USD_PROXY_ADDRESS"]
);
```

## Usage

```solidity
// Read SEI/USD price (18 decimals)
(int224 value, uint32 timestamp) = consumer.readDapi("SEI/USD");
uint256 price = uint256(int256(value)); // e.g. 450000000000000000 = $0.45

// Read with staleness check (max 1 hour)
(int224 safeValue, uint32 safeTs) = consumer.getPriceWithStalenessCheck("SEI/USD", 3600);

// Read multiple feeds at once
string[] memory names = new string[](2);
names[0] = "SEI/USD";
names[1] = "ETH/USD";
(int224[] memory values, uint32[] memory timestamps) = consumer.readMultiple(names);
```

## Price Format

API3 dAPI prices are `int224` with **18 decimal places**:

```
actualPrice = value / 10^18
```

For example, `value = 450000000000000000` corresponds to `$0.45`.

## References

- [API3 on Sei EVM](https://docs.sei.io/evm/oracles/api3)
- [API3 Market](https://market.api3.org)
- [API3 dAPI Documentation](https://docs.api3.org/reference/dapis/understand/)
