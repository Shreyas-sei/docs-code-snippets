# USDC Integration on Sei

Demonstrates common patterns for integrating USDC (USD Coin by Circle) on Sei EVM, including deposits, withdrawals, permit-based transfers, and direct payments.

## Overview

USDC on Sei is a native Circle-issued ERC-20 token with 6 decimal places. It follows the standard `FiatTokenV2` interface used by Circle across all EVM chains.

## Files

| File | Description |
|------|-------------|
| `contracts/USDCIntegration.sol` | Integration patterns: deposit, permit, withdraw, payment |
| `config/addresses.json` | USDC contract addresses on Sei mainnet and testnet |

## USDC Contract Addresses

| Network | Address |
|---------|---------|
| Sei Mainnet | `0x3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F1` |
| Sei Testnet | See [docs.sei.io/evm/usdc](https://docs.sei.io/evm/usdc) |

## Key Characteristics

| Property | Value |
|----------|-------|
| Decimals | `6` |
| 1 USDC in raw units | `1_000_000` (1e6) |
| Standard | ERC-20 + EIP-2612 (permit) |
| Issuer | Circle |

## Integration Patterns

### Pattern 1: Approve + TransferFrom (Standard)

```solidity
// Frontend
await usdc.approve(contractAddress, parseUnits("10.00", 6));
await myContract.deposit(parseUnits("10.00", 6));
```

### Pattern 2: EIP-2612 Permit (Gasless Approval)

```typescript
import { ethers } from "ethers";

// Sign the permit off-chain
const domain = {
  name: "USD Coin",
  version: "2",
  chainId: 1329,
  verifyingContract: USDC_ADDRESS,
};

const types = {
  Permit: [
    { name: "owner", type: "address" },
    { name: "spender", type: "address" },
    { name: "value", type: "uint256" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" },
  ],
};

const deadline = Math.floor(Date.now() / 1000) + 3600;
const nonce = await usdc.nonces(signer.address);

const signature = await signer.signTypedData(domain, types, {
  owner: signer.address,
  spender: contractAddress,
  value: parseUnits("10.00", 6),
  nonce,
  deadline,
});

const { v, r, s } = ethers.Signature.from(signature);
await myContract.depositWithPermit(parseUnits("10.00", 6), deadline, v, r, s);
```

### Pattern 3: Direct Transfer (sending to EOA)

```solidity
// Direct transfer — no approval needed
await usdc.transfer(recipientAddress, parseUnits("5.00", 6));
```

## Amounts and Decimals

```javascript
import { parseUnits, formatUnits } from "ethers";

// Human-readable → raw units
const raw = parseUnits("10.50", 6);  // 10500000

// Raw units → human-readable
const display = formatUnits(10500000n, 6);  // "10.5"
```

## Blacklist Check

Circle can blacklist addresses; always check before transferring:

```solidity
require(!usdc.isBlacklisted(recipient), "Recipient is blacklisted");
```

## References

- [USDC on Sei](https://docs.sei.io/evm/usdc)
- [Circle USDC Docs](https://developers.circle.com/stablecoins/docs/usdc-on-main-blockchains)
- [FiatTokenV2 Contract](https://github.com/circlefin/stablecoin-evm)
