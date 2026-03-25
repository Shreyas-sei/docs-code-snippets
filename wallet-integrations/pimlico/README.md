# Pimlico ERC-4337 on Sei

Demonstrates ERC-4337 Account Abstraction on Sei EVM using [Pimlico](https://pimlico.io/) as the bundler and paymaster (gas sponsorship).

## What this example covers

- Creating a `SimpleSmartAccount` from an EOA signer using `permissionless.js`
- Connecting to the Pimlico bundler on Sei via `createPimlicoClient`
- Sponsoring a `UserOperation` with the Pimlico verifying paymaster
- Sending a gas-free transaction from the smart account

## Setup

1. Get a Pimlico API key from https://dashboard.pimlico.io
2. Create a `.env` file:
   ```
   VITE_PIMLICO_API_KEY=your_pimlico_api_key
   ```
3. Install and run:
   ```bash
   npm install
   npm run dev
   ```

## Docs

- https://docs.sei.io/evm/wallet-integrations/pimlico
- https://docs.pimlico.io/permissionless/how-to/accounts/use-simple-account
