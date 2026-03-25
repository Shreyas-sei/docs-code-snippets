# Thirdweb ERC-4337 Smart Wallet on Sei

Demonstrates EIP-4337 Account Abstraction on Sei EVM using the [thirdweb SDK v5](https://thirdweb.com/).

## What this example covers

- `inAppWallet` as the signer (social / email login)
- `smartWallet` wrapping the in-app wallet for ERC-4337 account abstraction
- Gasless (sponsored) transactions via thirdweb's bundler
- `readContract` / `prepareContractCall` + `TransactionButton` for contract interactions
- Deploying and interacting with a simple `Storage` contract on Sei

## Setup

1. Get a thirdweb Client ID from https://thirdweb.com/dashboard
2. Create a `.env` file:
   ```
   VITE_TEMPLATE_CLIENT_ID=your_thirdweb_client_id_here
   ```
3. Deploy `contracts/Storage.sol` to Sei testnet and update `CONTRACT_ADDRESS` in `src/App.tsx`
4. Install and run:
   ```bash
   npm install
   npm run dev
   ```

## Docs

- https://docs.sei.io/evm/wallet-integrations/thirdweb
- https://portal.thirdweb.com/typescript/v5/smartWallet
