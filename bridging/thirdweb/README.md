# Thirdweb Universal Bridge on Sei

Demonstrates cross-chain token bridging to Sei using [thirdweb's Universal Bridge](https://thirdweb.com/bridge) and the `PayEmbed` component.

## What this example covers

- `PayEmbed` component in `bridge` mode — bridge tokens from any chain to Sei
- `PayEmbed` component in `buy` mode — buy SEI or Sei tokens with a credit card or crypto
- Supports 350+ chains and 20,000+ tokens out of the box

## Setup

1. Get a thirdweb Client ID from https://thirdweb.com/dashboard
2. Create a `.env` file:
   ```
   VITE_TEMPLATE_CLIENT_ID=your_thirdweb_client_id_here
   ```
3. Install and run:
   ```bash
   npm install
   npm run dev
   ```

## Customisation

To bridge to a specific ERC-20 token (e.g. USDC on Sei), uncomment the `token` block in `src/BridgeComponent.tsx` and update the token address.

## Docs

- https://docs.sei.io/evm/bridging/thirdweb
- https://portal.thirdweb.com/typescript/v5/components/PayEmbed
