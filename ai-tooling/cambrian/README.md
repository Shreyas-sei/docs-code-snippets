# Cambrian Agent Kit on Sei

Demonstrates how to build AI agents that interact with the Sei blockchain using the Cambrian Agent Kit, integrated with LangChain and OpenAI.

## Overview

The [Cambrian Agent Kit](https://docs.cambrian.ai) provides a set of blockchain-aware tools for AI agents. Combined with LangChain's ReAct agent pattern, it enables natural language interaction with the Sei blockchain.

## Files

| File | Description |
|------|-------------|
| `src/agent.ts` | Full agent setup with LangChain ReAct agent + Cambrian tools |
| `package.json` | Dependencies and scripts |

## Setup

```bash
npm install
```

### Environment Variables

```env
PRIVATE_KEY=0xYourPrivateKey
OPENAI_API_KEY=sk-...
USE_TESTNET=true       # optional, defaults to mainnet
```

## Running

```bash
# Interactive mode
npm start

# Demo mode (runs predefined prompts)
npm run demo
```

## What the Agent Can Do

With the Cambrian toolkit enabled, the agent can:

- **Check balances**: "What is the SEI balance of 0xAbc...?"
- **ERC-20 operations**: "Transfer 10 USDC to 0xDef..."
- **Contract queries**: "What is the total supply of this token?"
- **DeFi interactions**: "Swap 1 SEI for USDC on DragonSwap"
- **Address lookups**: "Convert this Sei cosmos address to EVM format"

## Example Session

```
You: What is the native SEI balance of my wallet?
Agent: Your wallet (0xYourAddress) has a balance of 42.5 SEI on Sei Mainnet.

You: What ERC-20 tokens do I hold?
Agent: Your wallet holds:
  - 100.0 USDC (0x3894...)
  - 0.05 WETH (0x...)

You: Check the total supply of USDC on Sei
Agent: The USDC token at 0x3894... has a total supply of 50,000,000 USDC.
```

## Architecture

```
User Input → LangChain ReAct Agent → LLM (GPT-4o)
                                          ↓
                              Tool Selection & Calls
                                          ↓
                              Cambrian Tools → Sei EVM RPC
                                          ↓
                              Parse Result → LLM Response
                                          ↓
                                 User-Facing Answer
```

## Network Configuration

| Network | RPC URL | Chain ID |
|---------|---------|----------|
| Mainnet | `https://evm-rpc.sei-apis.com` | `1329` |
| Testnet | `https://evm-rpc-testnet.sei-apis.com` | `713715` |

## References

- [Cambrian on Sei](https://docs.sei.io/evm/ai-tooling/cambrian)
- [Cambrian Agent Kit Docs](https://docs.cambrian.ai)
- [LangChain ReAct Agent](https://js.langchain.com/docs/how_to/migrate_agent)
