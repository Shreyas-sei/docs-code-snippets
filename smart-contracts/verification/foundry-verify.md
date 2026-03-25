# Contract Verification with Foundry on Sei

This guide covers verifying smart contracts on Sei using `forge verify-contract`.

## Prerequisites

- Contract deployed on Sei mainnet or testnet
- Foundry installed (`forge --version`)
- Contract source code available locally

## foundry.toml Configuration

Add Sei network endpoints and etherscan config to `foundry.toml`:

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc = "0.8.20"
optimizer = true
optimizer_runs = 200

[rpc_endpoints]
sei = "https://evm-rpc.sei-apis.com"
sei-testnet = "https://evm-rpc-testnet.sei-apis.com"

[etherscan]
sei = { key = "${SEITRACE_API_KEY}", url = "https://seitrace.com/api", chain = 1329 }
sei-testnet = { key = "${SEITRACE_API_KEY}", url = "https://seitrace.com/api?chain=atlantic-2", chain = 713715 }
```

## Verify During Deployment

The easiest way is to pass `--verify` to `forge script`:

```bash
forge script script/Deploy.s.sol:DeployMyToken \
  --rpc-url sei \
  --broadcast \
  --verify \
  -vvvv
```

For testnet:

```bash
forge script script/Deploy.s.sol:DeployMyToken \
  --rpc-url sei-testnet \
  --broadcast \
  --verify \
  -vvvv
```

## Manual Verification

### Basic contract (no constructor arguments)

```bash
forge verify-contract <CONTRACT_ADDRESS> src/Counter.sol:Counter \
  --chain 1329 \
  --verifier-url https://seitrace.com/api \
  --etherscan-api-key $SEITRACE_API_KEY
```

### With constructor arguments (ABI-encoded)

```bash
forge verify-contract <CONTRACT_ADDRESS> src/MyToken.sol:MyToken \
  --chain 1329 \
  --verifier-url https://seitrace.com/api \
  --etherscan-api-key $SEITRACE_API_KEY \
  --constructor-args $(cast abi-encode "constructor(string,string,uint8,uint256,address)" \
    "MyToken" "MTK" 18 1000000 <OWNER_ADDRESS>)
```

### Using a constructor args file

Create `constructor-args.txt` with hex-encoded ABI data:

```bash
cast abi-encode "constructor(string,string,uint8,uint256,address)" \
  "MyToken" "MTK" 18 1000000 <OWNER_ADDRESS> > constructor-args.txt
```

Then verify:

```bash
forge verify-contract <CONTRACT_ADDRESS> src/MyToken.sol:MyToken \
  --chain 1329 \
  --verifier-url https://seitrace.com/api \
  --etherscan-api-key $SEITRACE_API_KEY \
  --constructor-args-path constructor-args.txt
```

## Verify on Sei Testnet (Chain ID 713715)

```bash
forge verify-contract <CONTRACT_ADDRESS> src/Counter.sol:Counter \
  --chain 713715 \
  --verifier-url "https://seitrace.com/api?chain=atlantic-2" \
  --etherscan-api-key $SEITRACE_API_KEY
```

## Checking Verification Status

```bash
forge verify-check <SUBMISSION_GUID> \
  --chain 1329 \
  --verifier-url https://seitrace.com/api \
  --etherscan-api-key $SEITRACE_API_KEY
```

## Show Compiler Settings Used in Deployment

To find the exact compiler settings used:

```bash
forge inspect src/MyToken.sol:MyToken metadata
```

## Common Flags

| Flag | Description |
|------|-------------|
| `--chain` | Chain ID (1329 for mainnet, 713715 for testnet) |
| `--verifier-url` | Seitrace API URL |
| `--etherscan-api-key` | Your Seitrace API key |
| `--constructor-args` | ABI-encoded constructor arguments |
| `--compiler-version` | Override compiler version (e.g. `0.8.20`) |
| `--optimizer-runs` | Override optimizer runs (e.g. `200`) |
| `--watch` | Poll for verification result |
| `--flatten` | Use a flattened source file |

## Explorer Links After Verification

- **Mainnet:** `https://seitrace.com/address/<CONTRACT_ADDRESS>`
- **Testnet:** `https://testnet.seitrace.com/address/<CONTRACT_ADDRESS>`

## Resources

- [Sei Verify Contracts Docs](https://docs.sei.io/evm/evm-verify-contracts)
- [Sei Foundry Docs](https://docs.sei.io/evm/evm-foundry)
- [Foundry forge verify-contract docs](https://book.getfoundry.sh/reference/forge/forge-verify-contract)
- [Seitrace Explorer](https://seitrace.com)
