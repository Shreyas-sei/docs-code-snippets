# LayerZero OFT Bridge on Sei

Demonstrates deploying a [LayerZero V2 OFT (Omnichain Fungible Token)](https://docs.layerzero.network/v2/developers/evm/oft/quickstart) on Sei and bridging tokens to another chain.

## What this example covers

- `MyOFT.sol` — minimal OFT contract inheriting from LayerZero's `OFT` base
- Deploying on Sei mainnet, Sei testnet, or Ethereum Sepolia with Hardhat
- Minting an initial token supply
- Instructions to `setPeer()` on both chains and send cross-chain transfers

## LayerZero on Sei

| Network | Endpoint Address | EID |
|---------|-----------------|-----|
| Sei mainnet | `0x1a44076050125825900e736c501f859c50fE728c` | 30280 |
| Sei testnet | `0x6EDCE65403992e310A62460808c4b910D972f10f` | 40280 |

## Setup

1. Create a `.env` file:
   ```
   PRIVATE_KEY=your_deployer_private_key
   SEPOLIA_RPC_URL=https://rpc.sepolia.org   # optional
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Deploy on Sei testnet:
   ```bash
   npx hardhat run scripts/deploy.js --network seiTestnet
   ```

4. Deploy on Sepolia (for cross-chain testing):
   ```bash
   npx hardhat run scripts/deploy.js --network sepolia
   ```

5. Link the two OFTs with `setPeer()` on each contract, then call `send()`.

## Docs

- https://docs.sei.io/evm/bridging/layerzero
- https://docs.layerzero.network/v2/developers/evm/oft/quickstart
