# The Graph Subgraph for Sei

Demonstrates how to build and deploy a subgraph on The Graph Network to index ERC-20 token events on Sei EVM.

## Overview

The Graph provides decentralised indexing for blockchain data. Subgraphs define which smart contract events to index and how to transform that data into a queryable GraphQL API.

## Files

| File | Description |
|------|-------------|
| `subgraph/subgraph.yaml` | Subgraph manifest with data sources and event handlers |
| `subgraph/schema.graphql` | GraphQL schema (Token, Transfer, Approval, AccountBalance, Protocol) |
| `subgraph/src/mapping.ts` | AssemblyScript event handlers with balance tracking |

## Setup

### 1. Install dependencies

```bash
npm install -g @graphprotocol/graph-cli
npm install @graphprotocol/graph-ts
```

### 2. Authenticate with The Graph Studio

```bash
graph auth --studio <YOUR_DEPLOY_KEY>
```

Get your deploy key from [The Graph Studio](https://thegraph.com/studio).

### 3. Configure the subgraph

Edit `subgraph/subgraph.yaml`:
- Set `source.address` to your contract address
- Set `source.startBlock` to your contract's deployment block

```bash
# Look up your contract's deployment block on Seitrace
open https://seitrace.com/address/YOUR_CONTRACT_ADDRESS
```

### 4. Generate types and build

```bash
graph codegen subgraph/subgraph.yaml
graph build subgraph/subgraph.yaml
```

### 5. Create and deploy

```bash
# Create the subgraph in Studio first, then:
graph deploy --studio my-sei-subgraph subgraph/subgraph.yaml
```

## Querying

```graphql
# Most recent transfers
{
  transfers(first: 10, orderBy: blockTimestamp, orderDirection: desc) {
    id
    from { id }
    to { id }
    amount
    blockTimestamp
    transactionHash
  }
}

# Top holders
{
  accountBalances(
    where: { amount_gt: "0" }
    orderBy: amount
    orderDirection: desc
    first: 50
  ) {
    account { id }
    amount
    token { symbol }
  }
}

# Protocol stats
{
  protocol(id: "protocol") {
    totalTransfers
    totalAccounts
    totalTokens
  }
}
```

## JavaScript Client

```typescript
import { GraphQLClient } from "graphql-request";

const client = new GraphQLClient(
  "https://api.studio.thegraph.com/query/<ID>/my-sei-subgraph/v0.0.1"
);

const data = await client.request(`
  {
    transfers(first: 5, orderBy: blockTimestamp, orderDirection: desc) {
      id
      from { id }
      to { id }
      amount
    }
  }
`);
```

## References

- [The Graph on Sei](https://docs.sei.io/evm/indexers/the-graph)
- [The Graph Studio](https://thegraph.com/studio)
- [Graph Protocol Docs](https://thegraph.com/docs)
