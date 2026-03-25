# x402 HTTP Payments on Sei

Demonstrates the x402 HTTP payment protocol on Sei EVM — a standard for gating API access behind on-chain micropayments using USDC.

## Overview

x402 extends HTTP by using the existing `402 Payment Required` status code to implement machine-readable payment flows:

1. **Client** requests a resource
2. **Server** returns `402` with payment requirements (amount, token, recipient)
3. **Client** submits an on-chain USDC payment on Sei
4. **Client** retries with payment proof in the `X-PAYMENT` header
5. **Server** verifies payment and returns the content

This enables pay-per-use APIs, content gating, and AI agent payments with no subscriptions or API keys.

## Files

| File | Description |
|------|-------------|
| `server/payment-server.ts` | Express server with x402 payment middleware for multiple price tiers |
| `client/payment-client.ts` | Client demonstrating three payment approaches |

## Setup

```bash
npm install x402-express x402-fetch express ethers axios
npm install -D typescript ts-node @types/express @types/node
```

### Environment Variables

```env
# Server
PRIVATE_KEY=0xYourPrivateKey    # Payment receiver wallet
PORT=3000
USE_TESTNET=true                 # Optional

# Client
PRIVATE_KEY=0xYourPrivateKey    # Payer wallet (needs USDC)
SERVER_URL=http://localhost:3000
USE_TESTNET=true
```

## Running

### Start the server

```bash
PRIVATE_KEY=0x... ts-node server/payment-server.ts
```

### Run the client

```bash
PRIVATE_KEY=0x... SERVER_URL=http://localhost:3000 ts-node client/payment-client.ts
```

## Server Endpoints

| Endpoint | Price | Description |
|----------|-------|-------------|
| `GET /` | Free | Server info |
| `GET /health` | Free | Health check |
| `GET /api/data` | $0.01 | Current block number |
| `GET /api/premium` | $0.10 | Block details |
| `GET /api/exclusive` | $1.00 | Exclusive content |
| `GET /api/stream` | $0.05 | Server-sent events |

## Payment Flow Diagram

```
Client                          Sei Blockchain             Server
  │                                   │                       │
  │  GET /api/data                    │                       │
  │──────────────────────────────────────────────────────────►│
  │                                   │                       │
  │  402 Payment Required             │                       │
  │◄──────────────────────────────────────────────────────────│
  │  { amount: "10000", payTo: "0x...", asset: "USDC" }       │
  │                                   │                       │
  │  usdc.transfer(payTo, 10000)      │                       │
  │──────────────────────────────────►│                       │
  │                                   │                       │
  │  txHash: 0xabc...                 │                       │
  │◄──────────────────────────────────│                       │
  │                                   │                       │
  │  GET /api/data                    │                       │
  │  X-PAYMENT: <base64 proof>        │                       │
  │──────────────────────────────────────────────────────────►│
  │                                   │  verify payment       │
  │                                   │◄──────────────────────│
  │  200 OK { data }                  │                       │
  │◄──────────────────────────────────────────────────────────│
```

## Using x402-fetch (Automatic Payment Handling)

```typescript
import { wrapFetchWithPayment } from "x402-fetch";
import { ethers } from "ethers";

const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
const fetchWithPayment = wrapFetchWithPayment(fetch, wallet);

// Automatically pays and retries if 402 is received
const response = await fetchWithPayment("https://api.example.com/paid-endpoint");
const data = await response.json();
```

## AI Agent Integration

x402 is particularly useful for AI agents that need to autonomously pay for API access:

```typescript
// Give your AI agent a wallet and it can pay for any x402-gated API
const agentWallet = new ethers.Wallet(AGENT_PRIVATE_KEY, provider);
const agentFetch = wrapFetchWithPayment(fetch, agentWallet);

// Agent can now access any paid endpoint
const priceData = await agentFetch("https://data-provider.com/sei/prices");
```

## References

- [x402 on Sei](https://docs.sei.io/evm/x402)
- [x402 Protocol Spec](https://docs.x402.org)
- [x402 npm packages](https://www.npmjs.com/package/x402-express)
