# Moralis Streams for Sei

Demonstrates how to set up Moralis Streams to receive real-time blockchain event webhooks from Sei EVM, and how to process those events in an Express webhook handler.

## Overview

Moralis Streams is a webhook-based system for streaming blockchain data in real time:

1. **Create a stream** — specify which chain, contracts, and events to watch
2. **Receive webhooks** — Moralis POSTs event data to your URL as blocks are confirmed
3. **Process events** — decode and handle Transfer, Approval, and other events

## Files

| File | Description |
|------|-------------|
| `streams/createStream.js` | Moralis stream setup for Sei ERC-20 events |
| `webhooks/handler.js` | Express server that receives and processes Moralis webhooks |

## Sei Chain IDs in Moralis

| Network | Hex Chain ID | Decimal |
|---------|-------------|---------|
| Sei Mainnet | `0x531` | 1329 |
| Sei Testnet | `0xAE6B3` | 713715 |

## Setup

```bash
npm install moralis @moralisweb3/common-evm-utils express
```

### Environment Variables

```env
MORALIS_API_KEY=your_moralis_api_key
MORALIS_STREAM_SECRET=your_stream_secret
WEBHOOK_URL=https://your-domain.com/webhook
CONTRACT_ADDRESS=0xYourContractAddress
PORT=3000
```

Get your API key from [admin.moralis.io](https://admin.moralis.io).

## Creating a Stream

```bash
node streams/createStream.js
```

This creates two streams:
1. ERC-20 Transfer/Approval events for your contract
2. Native SEI transaction stream

## Running the Webhook Handler

```bash
node webhooks/handler.js
```

For local development, expose with ngrok:

```bash
ngrok http 3000
# Copy the https:// URL as your WEBHOOK_URL
```

## Moralis REST API (alternative to SDK)

```bash
# Create stream via REST
curl -X POST https://api.moralis-streams.com/streams/evm \
  -H "x-api-key: $MORALIS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "chains": ["0x531"],
    "description": "Sei ERC-20 Transfers",
    "tag": "sei-transfers",
    "webhookUrl": "https://your-server.com/webhook",
    "includeContractLogs": true,
    "topic0": ["Transfer(address,address,uint256)"]
  }'
```

## Example Webhook Payload

```json
{
  "confirmed": true,
  "chainId": "0x531",
  "streamId": "abc123",
  "tag": "sei-erc20-transfers",
  "block": { "number": "12345678", "hash": "0x...", "timestamp": "1711234567" },
  "logs": [{
    "address": "0xTokenContract",
    "topic0": "0xddf252ad...",
    "topic1": "0x000...fromAddress",
    "topic2": "0x000...toAddress",
    "data": "0x0000...amount",
    "transactionHash": "0x..."
  }],
  "erc20Transfers": [{
    "from": "0xFromAddress",
    "to": "0xToAddress",
    "value": "1000000000000000000",
    "tokenSymbol": "SEI",
    "contract": "0xTokenContract"
  }]
}
```

## References

- [Moralis on Sei](https://docs.sei.io/evm/indexers/moralis)
- [Moralis Streams API](https://docs.moralis.io/streams-api/evm)
- [Moralis EVM Chains](https://docs.moralis.io/supported-chains)
