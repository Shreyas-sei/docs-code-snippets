# Getting Started with Smart Contracts on Sei

This directory contains introductory smart contract examples demonstrating the basics of writing and deploying contracts on the Sei EVM.

## Examples

### Coin.sol

A basic Solidity contract demonstrating:
- State variables and mappings
- Access control with `require`
- Events
- Token minting and transfer

### Auction.vy

A Vyper Open Auction contract demonstrating:
- Bidding with ETH/SEI
- The withdrawal pattern (avoiding reentrancy)
- Auction lifecycle management
- Timed state transitions

## Sei Network Details

| Network  | RPC URL                                   | Chain ID |
|----------|-------------------------------------------|----------|
| Mainnet  | https://evm-rpc.sei-apis.com             | 1329     |
| Testnet  | https://evm-rpc-testnet.sei-apis.com     | 1328   |

## Resources

- [Sei EVM General Docs](https://docs.sei.io/evm/evm-general)
- [Sei Developer Portal](https://docs.sei.io)
- [Seitrace Explorer](https://seitrace.com)
