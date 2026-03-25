# Pyth Entropy (VRF) on Sei — Dice Game

Demonstrates on-chain verifiable random number generation using Pyth Entropy on Sei EVM. The example implements a dice game where outcomes are determined by cryptographically secure randomness.

## Overview

Pyth Entropy provides a two-phase commit-reveal VRF:

1. **Request** — contract calls `entropy.requestV2()` with a user-supplied random commitment
2. **Callback** — Pyth calls `entropyCallback()` on your contract with the fulfilled random number

This model prevents front-running because the final randomness is the hash of both the user's and provider's random values.

## Files

| File | Description |
|------|-------------|
| `contracts/SeiEntropyDemo.sol` | Dice game contract implementing `IEntropyConsumer` |
| `scripts/deploy.js` | Deploy script with automatic house bankroll funding |

## Contract Addresses

| Network | Pyth Entropy Contract |
|---------|----------------------|
| Sei Mainnet (1329) | `0x98046Bd286715D3B0BC227Dd7a956b83D8978603` |
| Sei Testnet (1328) | `0x98046Bd286715D3B0BC227Dd7a956b83D8978603` |

## Setup

```bash
npm install @pythnetwork/entropy-sdk-solidity hardhat @nomicfoundation/hardhat-toolbox dotenv
```

### hardhat.config.js

```js
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.19",
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
  },
};
```

## Deploying

```bash
# Deploy to testnet
PRIVATE_KEY=0x... npx hardhat run scripts/deploy.js --network seiTestnet

# Deploy to mainnet
PRIVATE_KEY=0x... npx hardhat run scripts/deploy.js --network sei
```

## Playing the Game

```typescript
import { ethers } from "ethers";

const provider = new ethers.JsonRpcProvider("https://evm-rpc-testnet.sei-apis.com");
const signer = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);
const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);

// Get the required entropy fee
const fee = await contract.getRequestFee();

// Place a bet on dice number 4
const tx = await contract.playDiceGame(4, {
  value: fee, // just the fee for a zero-value bet, or fee + betAmount
});
const receipt = await tx.wait();

// Listen for the GameResolved event (emitted in the callback)
const filter = contract.filters.GameResolved();
contract.on(filter, (sequenceNumber, player, won, diceRoll) => {
  console.log(`Dice rolled: ${diceRoll}, Won: ${won}`);
});
```

## How the Randomness Works

1. Player calls `playDiceGame(targetNumber)` with `msg.value >= entropyFee`
2. Contract generates a `userRandom` commitment from block data + counter
3. Contract calls `entropy.requestV2(provider, userRandom)` — gets a `sequenceNumber`
4. Pyth network fulfills the request and calls `entropyCallback(sequenceNumber, provider, randomNumber)`
5. Contract derives `diceRoll = (uint256(randomNumber) % 6) + 1`
6. If `diceRoll == targetNumber`, player wins 5x their bet

## References

- [Pyth Entropy on Sei](https://docs.sei.io/evm/vrf/pyth-network-vrf)
- [Pyth Entropy SDK](https://github.com/pyth-network/pyth-crosschain/tree/main/entropy_sdk/solidity)
- [IEntropyConsumer Interface](https://github.com/pyth-network/pyth-crosschain/blob/main/target_chains/ethereum/entropy_sdk/solidity/IEntropyConsumer.sol)
