# Read & Write Contract — wagmi hooks on Sei

Demonstrates reading from and writing to a Solidity contract on Sei EVM using wagmi v2 hooks.

## What this example covers

- `useReadContract` — read a value from a deployed contract
- `useWriteContract` — send a write transaction
- `useWaitForTransactionReceipt` — poll for confirmation and show tx hash
- Linking to Seitrace (Sei block explorer) for transaction inspection

## Contract

This example targets the simple `Storage` contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage {
    uint256 private value;

    function store(uint256 num) public { value = num; }
    function retrieve() public view returns (uint256) { return value; }
}
```

Deploy it to Sei testnet and paste the address into `CONTRACT_ADDRESS` in `src/ContractInteraction.tsx`.

## Getting started

```bash
npm install
npm run dev
```

## Docs

- https://docs.sei.io/evm/building-a-frontend
- https://wagmi.sh/react/api/hooks/useReadContract
- https://wagmi.sh/react/api/hooks/useWriteContract
