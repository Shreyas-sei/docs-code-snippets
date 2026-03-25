# Goldsky Subgraph for Sei

Demonstrates how to build and deploy a Goldsky subgraph to index ERC-20 token events (Transfer, Approval) on Sei EVM.

## Overview

[Goldsky](https://goldsky.com) is the recommended indexing solution for Sei and supports direct subgraph deployments with no Graph Node setup required. It also supports mirror pipelines for streaming blockchain data to databases.

## Files

| File | Description |
|------|-------------|
| `subgraph/subgraph.yaml` | Goldsky subgraph manifest pointing to Sei mainnet |
| `subgraph/schema.graphql` | GraphQL schema for Token, Transfer, Approval, AccountBalance entities |
| `subgraph/src/mapping.ts` | AssemblyScript event handlers |

## Setup

### 1. Install Goldsky CLI

```bash
curl https://goldsky.com/install | sh
goldsky login
```

### 2. Install subgraph dependencies

```bash
npm install -g @graphprotocol/graph-cli
npm install @graphprotocol/graph-ts
```

### 3. Configure your contract

Edit `subgraph/subgraph.yaml` and set:
- `source.address` — your ERC-20 contract address
- `source.startBlock` — the deployment block number of your contract

### 4. Generate types

```bash
graph codegen subgraph/subgraph.yaml
graph build subgraph/subgraph.yaml
```

### 5. Deploy to Goldsky

```bash
goldsky subgraph deploy my-sei-token/1.0.0 --path ./subgraph
```

## Querying

After deployment, Goldsky provides a GraphQL endpoint:

```graphql
# Get recent transfers
{
  transfers(first: 20, orderBy: blockTimestamp, orderDirection: desc) {
    id
    from { id }
    to { id }
    amount
    blockTimestamp
    transactionHash
  }
}

# Get token holders
{
  accountBalances(
    where: { amount_gt: "0" }
    orderBy: amount
    orderDirection: desc
    first: 100
  ) {
    account { id }
    amount
  }
}

# Get token stats
{
  token(id: "0xyourcontractaddress") {
    name
    symbol
    totalSupply
    transferCount
    holderCount
  }
}
```

## Mirror Pipelines (Streaming)

Goldsky also supports streaming data to Postgres, Kafka, or S3:

```bash
goldsky pipeline create my-pipeline --definition pipeline.yaml
```

## References

- [Goldsky on Sei](https://docs.sei.io/evm/indexers/goldsky)
- [Goldsky Documentation](https://docs.goldsky.com)
- [Goldsky Subgraph Deploy](https://docs.goldsky.com/subgraphs/deploying-subgraphs)
