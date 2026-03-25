# Staking Precompile

Solidity contracts and JavaScript examples for delegating, undelegating,
redelegating, and querying staking state on Sei via the staking precompile.

**Precompile address:** `0x0000000000000000000000000000000000001005`

## Files

| File | Description |
|------|-------------|
| `interfaces/IStaking.sol` | Full interface including all structs, events, and functions |
| `StakingManager.sol` | Managed staking contract wrapping precompile calls |

## Interface Overview

```solidity
// Delegate — msg.value in 18-decimal wei
function delegate(string memory valAddress) external payable returns (bool);

// Undelegate / Redelegate — amount in usei (6 decimals)
function undelegate(string memory valAddress, uint256 amount) external returns (bool);
function redelegate(string memory src, string memory dst, uint256 amount) external returns (bool);

// Queries
function delegation(address delegator, string memory valAddress) external view returns (Delegation memory);
function delegatorDelegations(address delegator, bytes memory nextKey) external view returns (DelegationsResponse memory);
```

## Decimal Reference

| Operation | Unit | Decimals |
|-----------|------|----------|
| `delegate()` msg.value | wei | 18 |
| `undelegate()` amount | usei | 6 |
| `redelegate()` amount | usei | 6 |
| `delegation().balance.amount` | usei | 6 |
| `delegation().delegation.shares` | shares | 18 |

## Usage Examples

### Delegate (Solidity)

```solidity
bool success = ISTAKING(0x0000000000000000000000000000000000001005)
    .delegate{value: msg.value}(validatorAddress);
require(success, "Delegation failed");
```

### Delegate (JavaScript)

```js
import { STAKING_PRECOMPILE_ABI, STAKING_PRECOMPILE_ADDRESS } from '@sei-js/evm';

const staking = new ethers.Contract(STAKING_PRECOMPILE_ADDRESS, STAKING_PRECOMPILE_ABI, signer);

const amountToDelegate = ethers.parseUnits('1', 18); // 1 SEI in wei
const tx = await staking.delegate(validatorAddress, { value: amountToDelegate });
await tx.wait();
```

### Query Delegation (JavaScript)

```js
const delegation = await staking.delegation(await signer.getAddress(), validatorAddress);
const amountSei = ethers.formatUnits(delegation.balance.amount, 6);
console.log('Delegation amount (SEI):', amountSei);
```

## Deployment

```bash
npx hardhat run scripts/deploy.js --network sei-mainnet
```

## References

- [Staking Precompile Docs](https://docs.sei.io/evm/precompiles/staking)
