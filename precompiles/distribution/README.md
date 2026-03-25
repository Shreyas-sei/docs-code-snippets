# Distribution Precompile

Solidity contracts demonstrating how to interact with the Sei Distribution
precompile to withdraw staking rewards and validator commissions.

**Precompile address:** `0x0000000000000000000000000000000000001007`

## Files

| File | Description |
|------|-------------|
| `interfaces/IDistribution.sol` | Full interface for the distribution precompile |
| `YieldAggregator.sol` | Harvest rewards from multiple validators |
| `ValidatorCommissionManager.sol` | Validator operator commission management |

## Interface Overview

```solidity
interface IDistribution {
    function setWithdrawAddress(address withdrawAddr) external returns (bool);
    function withdrawDelegationRewards(string memory validator) external returns (bool);
    function withdrawMultipleDelegationRewards(string[] memory validators) external returns (bool);
    function withdrawValidatorCommission() external returns (bool);
    function rewards(address delegatorAddress) external view returns (Rewards memory);
}
```

## Key Decimal Notes

| Operation | Precision |
|-----------|-----------|
| `rewards()` return values | 18 decimals |
| Withdrawn amounts in events | 6 decimals (usei) |

## Usage Examples

### Check Pending Rewards (Solidity)

```solidity
IDistribution constant DISTR = IDistribution(0x0000000000000000000000000000000000001007);

IDistribution.Rewards memory userRewards = DISTR.rewards(msg.sender);

for (uint i = 0; i < userRewards.total.length; i++) {
    IDistribution.Coin memory coin = userRewards.total[i];
    // coin.amount is in 18-decimal precision
    uint256 displayAmount = coin.amount / (10 ** coin.decimals);
}
```

### Withdraw from Multiple Validators (Solidity)

```solidity
string[] memory validators = new string[](3);
validators[0] = "seivaloper1abc...";
validators[1] = "seivaloper1def...";
validators[2] = "seivaloper1ghi...";

bool success = DISTR.withdrawMultipleDelegationRewards(validators);
require(success, "Failed to withdraw multiple rewards");
```

### JavaScript: Listen for Withdrawal Events

```js
distrContract.on('DelegationRewardsWithdrawn', (delegator, validator, amount) => {
    const seiAmount = Number(amount) / 1e6; // event amounts are 6 decimals
    console.log(`${delegator} withdrew ${seiAmount} SEI from ${validator}`);
});
```

## Deployment

```bash
npx hardhat run scripts/deploy.js --network sei-mainnet
```

## References

- [Distribution Precompile Docs](https://docs.sei.io/evm/precompiles/distribution)
