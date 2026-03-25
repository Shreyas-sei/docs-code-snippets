# Thirdweb EIP-7702 Wallet on Sei

Demonstrates EIP-7702 wallet delegation on Sei EVM using the [thirdweb SDK v5](https://thirdweb.com/).

## What this example covers

- `inAppWallet` configured with `executionMode: { mode: "EIP7702", sponsorGas: true }`
- How EIP-7702 differs from ERC-4337: the EOA address is preserved while temporarily gaining smart contract capabilities
- Gasless (sponsored) transactions through the delegated EOA
- Contract read/write with `readContract` / `prepareContractCall` + `TransactionButton`

## EIP-7702 vs ERC-4337

| Feature | ERC-4337 | EIP-7702 |
|---------|----------|----------|
| Account address | New smart contract address | Same EOA address |
| Compatibility | Requires bundler + EntryPoint | Native EVM support |
| Gas sponsorship | Via paymaster | Via delegation |

## Setup

1. Get a thirdweb Client ID from https://thirdweb.com/dashboard
2. Create a `.env` file:
   ```
   VITE_TEMPLATE_CLIENT_ID=your_thirdweb_client_id_here
   ```
3. Deploy `Storage.sol` to Sei testnet and update `CONTRACT_ADDRESS` in `src/App.tsx`
4. Install and run:
   ```bash
   npm install
   npm run dev
   ```

## Docs

- https://docs.sei.io/evm/wallet-integrations/thirdweb-7702
- https://portal.thirdweb.com/typescript/v5/inAppWallet
