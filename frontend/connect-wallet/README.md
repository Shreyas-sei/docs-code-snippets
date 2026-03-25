# Connect Wallet — RainbowKit + Sei Global Wallet

Demonstrates how to connect a wallet on Sei EVM using [RainbowKit](https://www.rainbowkit.com/), [wagmi](https://wagmi.sh/), and the [Sei Global Wallet](https://docs.sei.io/evm/sei-global-wallet) (EIP-6963).

## What this example covers

- Registering Sei Global Wallet via EIP-6963 (`@sei-js/sei-global-wallet/eip6963`)
- Configuring wagmi with `getDefaultConfig` for Sei mainnet and testnet
- Rendering a RainbowKit `<ConnectButton />`
- Reading connected account address, chain, and native balance with `useAccount` / `useBalance`

## Getting started

```bash
npm install
npm run dev
```

Set your WalletConnect project ID in `src/App.tsx` (replace `YOUR_WALLETCONNECT_PROJECT_ID`).

## Docs

- https://docs.sei.io/evm/sei-global-wallet
- https://docs.sei.io/evm/building-a-frontend
