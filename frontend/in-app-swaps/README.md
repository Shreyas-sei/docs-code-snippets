# In-App Swaps on Sei

Demonstrates how to build an in-app token swap UI on Sei EVM. The component handles token selection, balance display, and ERC-20 approval — the pattern required before executing a swap through any DEX router.

## What this example covers

- Token selector UI for Sei native tokens (SEI, USDC, WSEI)
- Reading token balances with `useBalance`
- ERC-20 `approve` transaction via `useWriteContract`
- Transaction confirmation with `useWaitForTransactionReceipt`
- Pattern for integrating with a DEX router (e.g. DragonSwap) on Sei

## Getting started

```bash
npm install
npm run dev
```

Replace `ROUTER_ADDRESS` in `src/SwapComponent.tsx` with the DEX router address you want to use, then add the router's swap function call after the approval step.

## Docs

- https://docs.sei.io/evm/in-app-swaps
- https://docs.sei.io/evm/building-a-frontend
