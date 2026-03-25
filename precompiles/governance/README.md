# Governance Precompile

Solidity contracts for participating in Sei on-chain governance — casting votes
and submitting proposals via the governance precompile.

**Precompile address:** `0x0000000000000000000000000000000000001006`

## Files

| File | Description |
|------|-------------|
| `interfaces/IGovernance.sol` | Governance precompile interface |
| `GovernanceVoter.sol` | Vote caster and proposal submitter contract |

## Vote Options

| Value | Meaning |
|-------|---------|
| `1` | YES |
| `2` | ABSTAIN |
| `3` | NO |
| `4` | NO_WITH_VETO |

## Interface Overview

```solidity
interface IGovernance {
    function vote(uint64 proposalId, int32 option) external returns (bool);
    function submitProposal(string memory proposalJSON) external payable returns (bool);
}
```

## Usage Examples

### Vote (Solidity)

```solidity
IGovernance constant GOVERNANCE = IGovernance(0x0000000000000000000000000000000000001006);

bool success = GOVERNANCE.vote(proposalId, 1 /* YES */);
require(success, "Vote failed");
```

### Vote (JavaScript)

```js
import { GOVERNANCE_PRECOMPILE_ABI, GOVERNANCE_PRECOMPILE_ADDRESS } from '@sei-js/evm';

const governance = new ethers.Contract(
    GOVERNANCE_PRECOMPILE_ADDRESS,
    GOVERNANCE_PRECOMPILE_ABI,
    signer
);

const proposalId = 1;
const voteOption = 1; // YES

const tx = await governance.vote(proposalId, voteOption);
await tx.wait();
console.log('Vote cast successfully');
```

## Deployment

```bash
npx hardhat run scripts/deploy.js --network sei-mainnet
```

## References

- [Governance Precompile Docs](https://docs.sei.io/evm/precompiles/governance)
