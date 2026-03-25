# UUPS Upgradeable Token on Sei EVM

This example demonstrates the UUPS (Universal Upgradeable Proxy Standard) upgrade pattern for ERC20 tokens on Sei EVM.

## What is UUPS?

UUPS is an upgradeable contract pattern where the upgrade logic lives in the implementation contract itself (rather than the proxy). This means:

- The proxy contract is simpler and cheaper to deploy
- The owner can upgrade to a new implementation via `upgradeTo()`
- State is preserved across upgrades (proxy storage is never cleared)
- The proxy address never changes — users always interact with the same address

## Contracts

### MyTokenV1

Version 1 features:
- Standard ERC20 (transfer, approve, transferFrom)
- Mintable (owner only)
- Burnable
- Pausable
- ERC20Permit (gasless approvals)
- UUPS upgrade authorization

### MyTokenV2

Version 2 adds:
- Configurable supply cap (`maxSupplyCap`)
- Per-transaction transfer limit (`transferLimit`)
- `initializeV2()` re-initializer called during upgrade

## Setup

### Install dependencies

```bash
npm install
```

### Configure environment

Create a `.env` file:

```
PRIVATE_KEY=your_private_key_here
SEITRACE_API_KEY=your_api_key_here
```

## Deploy V1

```bash
npx hardhat run scripts/deploy.js --network sei-testnet
```

This outputs a proxy address. **Save this address** — it is the permanent address users interact with.

## Upgrade to V2

```bash
PROXY_ADDRESS=0xYourProxyAddress npx hardhat run scripts/upgrade.js --network sei-testnet
```

## Verify Contracts on Seitrace

Verify the implementation contracts (not the proxy directly):

```bash
# Verify V1 implementation
npx hardhat verify --network sei <IMPLEMENTATION_V1_ADDRESS>

# Verify V2 implementation
npx hardhat verify --network sei <IMPLEMENTATION_V2_ADDRESS>
```

## Key UUPS Principles

1. **Never change existing storage variable order** — only append new variables in upgrades
2. **Use `_disableInitializers()` in constructor** — prevents direct initialization of implementation
3. **Use `reinitializer(N)` for upgrade init** — allows running upgrade-specific initialization once
4. **`_authorizeUpgrade` must check ownership** — prevents unauthorized upgrades

## Sei Network Details

| Network  | RPC URL                                   | Chain ID |
|----------|-------------------------------------------|----------|
| Mainnet  | https://evm-rpc.sei-apis.com             | 1329     |
| Testnet  | https://evm-rpc-testnet.sei-apis.com     | 1328   |

## Resources

- [Sei Hardhat Docs](https://docs.sei.io/evm/evm-hardhat)
- [OpenZeppelin UUPS Guide](https://docs.openzeppelin.com/contracts/5.x/api/proxy#UUPSUpgradeable)
- [Seitrace Explorer](https://seitrace.com)
