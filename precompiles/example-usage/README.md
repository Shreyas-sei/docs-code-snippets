# Precompile Example Usage

JavaScript examples showing how to set up ethers.js and interact with the most
common Sei EVM precompiles from both browser and Node.js environments.

## Files

| File | Description |
|------|-------------|
| `setup-ethers.js` | Provider and signer initialisation for browser and Node.js |
| `staking-example.js` | Delegate, undelegate, redelegate, and query staking state |
| `governance-example.js` | Cast votes and submit governance proposals |

## Prerequisites

```bash
npm install ethers @sei-js/evm
```

## Quick Start

### Browser

```js
import { ethers } from 'ethers';

const provider = new ethers.BrowserProvider(window.ethereum);
await provider.send('eth_requestAccounts', []);
const signer = await provider.getSigner();
```

### Node.js

```js
const provider = new ethers.JsonRpcProvider('https://evm-rpc-testnet.sei-apis.com');
const signer = new ethers.Wallet('YOUR_PRIVATE_KEY', provider);
```

## Running the Examples

```bash
# Staking
PRIVATE_KEY=0x... node staking-example.js

# Governance
PRIVATE_KEY=0x... node governance-example.js
```

## Network RPC Endpoints

| Network | RPC URL |
|---------|---------|
| Mainnet | `https://evm-rpc.sei-apis.com` |
| Testnet | `https://evm-rpc-testnet.sei-apis.com` |

## Key Precompile Addresses

| Precompile | Address |
|------------|---------|
| Staking | `0x0000000000000000000000000000000000001005` |
| Governance | `0x0000000000000000000000000000000000001006` |
| Distribution | `0x0000000000000000000000000000000000001007` |
| Oracle | `0x0000000000000000000000000000000000001008` |
| JSON | `0x0000000000000000000000000000000000001003` |

## References

- [Sei Precompile Docs](https://docs.sei.io/evm/precompiles/example-usage)
- [@sei-js/evm](https://www.npmjs.com/package/@sei-js/evm)
