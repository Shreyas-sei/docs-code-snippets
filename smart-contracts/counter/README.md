# Counter Contract — Foundry on Sei EVM

A simple counter contract demonstrating the Foundry development workflow on Sei EVM. This is the canonical "hello world" for Foundry, extended with fuzz tests and a full Sei deployment script.

## Contract Features

- `setNumber(uint256)` — set an arbitrary value
- `increment()` — add 1
- `decrement()` — subtract 1 (reverts at 0)
- `add(uint256)` — add any amount
- `subtract(uint256)` — subtract any amount (reverts on underflow)
- `reset()` — set back to 0

## Setup

### Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Configure environment

Create a `.env` file:

```
PRIVATE_KEY=your_private_key_here
SEITRACE_API_KEY=your_api_key_here
```

## Compile

```bash
forge build
```

## Test (with fuzz testing)

```bash
# Run all tests including fuzz tests (256 runs each)
forge test -vvv

# Run with more fuzz iterations
FOUNDRY_PROFILE=ci forge test -vvv

# Run a specific test
forge test --match-test testFuzz_SetNumber -vvv

# Run tests with gas report
forge test --gas-report
```

## Deploy to Sei Testnet

```bash
forge script script/Deploy.s.sol:DeployCounter \
  --rpc-url sei-testnet \
  --broadcast \
  --verify \
  -vvvv
```

## Deploy to Sei Mainnet

```bash
forge script script/Deploy.s.sol:DeployCounter \
  --rpc-url sei \
  --broadcast \
  --verify \
  -vvvv
```

## Verify Manually on Seitrace

```bash
forge verify-contract <CONTRACT_ADDRESS> src/Counter.sol:Counter \
  --chain 1329 \
  --verifier-url https://seitrace.com/api \
  --etherscan-api-key $SEITRACE_API_KEY
```

## Sei Network Details

| Network  | RPC URL                                   | Chain ID |
|----------|-------------------------------------------|----------|
| Mainnet  | https://evm-rpc.sei-apis.com             | 1329     |
| Testnet  | https://evm-rpc-testnet.sei-apis.com     | 1328   |

## Resources

- [Sei Foundry Docs](https://docs.sei.io/evm/evm-foundry)
- [Foundry Book](https://book.getfoundry.sh)
- [Seitrace Explorer](https://seitrace.com)
