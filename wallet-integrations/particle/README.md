# Particle Auth + Smart Account on Sei

Demonstrates social login and ERC-4337 Smart Account creation on Sei EVM using [Particle Network](https://particle.network/).

## What this example covers

- Social login (Google) via Particle Auth Core
- Creating a Biconomy v2 Smart Account wrapping the Particle EOA
- Reading the smart account address and SEI balance
- `AAWrapProvider` to expose the smart account as an ethers.js provider

## Setup

1. Create an app in the [Particle Dashboard](https://dashboard.particle.network) and note your `projectId`, `clientKey`, and `appId`.
2. Create a `.env` file:
   ```
   VITE_PARTICLE_PROJECT_ID=your_project_id
   VITE_PARTICLE_CLIENT_KEY=your_client_key
   VITE_PARTICLE_APP_ID=your_app_id
   ```
3. Install and run:
   ```bash
   npm install
   npm run dev
   ```

## Docs

- https://docs.sei.io/evm/wallet-integrations/particle
- https://developers.particle.network/
