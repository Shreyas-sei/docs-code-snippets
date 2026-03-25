# JSON Precompile

Solidity contracts for parsing JSON data on-chain using the Sei JSON precompile.
Enables contracts to decode oracle payloads, CosmWasm query results, and
arbitrary JSON strings without off-chain infrastructure.

**Precompile address:** `0x0000000000000000000000000000000000001003`

## Files

| File | Description |
|------|-------------|
| `interfaces/IJson.sol` | JSON precompile interface |
| `JsonParser.sol` | On-chain JSON parsing utilities |

## Interface Overview

```solidity
interface IJson {
    function extractAsBytes(bytes memory input, string memory key) external view returns (bytes memory);
    function extractAsBytesList(bytes memory input, string memory key) external view returns (bytes[] memory);
    function extractAsUint256(bytes memory input, string memory key) external view returns (uint256);
}
```

## Usage Examples

### Parse a Price Feed Response (Solidity)

```solidity
IJson constant JSON_PRECOMPILE = IJson(0x0000000000000000000000000000000000001003);

bytes memory data = bytes('{"price": 100, "symbol": "SEI"}');

bytes memory symbolBytes = JSON_PRECOMPILE.extractAsBytes(data, "symbol");
string memory symbol = string(symbolBytes);

uint256 price = JSON_PRECOMPILE.extractAsUint256(data, "price");
// symbol == "SEI", price == 100
```

### JavaScript: Build JSON Input

```js
import { JSON_PRECOMPILE_ABI, JSON_PRECOMPILE_ADDRESS } from '@sei-js/evm';

const jsonPrecompile = new ethers.Contract(JSON_PRECOMPILE_ADDRESS, JSON_PRECOMPILE_ABI, signer);

const data = { price: 100, symbol: 'SEI' };
const inputData = ethers.toUtf8Bytes(JSON.stringify(data));

const symbolBytes = await jsonPrecompile.extractAsBytes(inputData, 'symbol');
const symbol = ethers.toUtf8String(symbolBytes);

const price = await jsonPrecompile.extractAsUint256(inputData, 'price');
console.log(`${symbol}: ${price}`);
```

## Supported Types

| Function | Use Case |
|----------|----------|
| `extractAsBytes` | String values, nested objects |
| `extractAsBytesList` | JSON arrays |
| `extractAsUint256` | Numeric values |

## Deployment

```bash
npx hardhat run scripts/deploy.js --network sei-mainnet
```

## References

- [JSON Precompile Docs](https://docs.sei.io/evm/precompiles/json)
