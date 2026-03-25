# Contract Verification with Hardhat on Sei

This guide covers verifying smart contracts on Sei using Hardhat and the `hardhat-verify` plugin (part of `@nomicfoundation/hardhat-toolbox`).

## Prerequisites

- Contract deployed on Sei mainnet or testnet
- Contract source code available locally
- `@nomicfoundation/hardhat-toolbox` installed

## Hardhat Config for Seitrace

Add the following to your `hardhat.config.js`:

```js
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    sei: {
      url: "https://evm-rpc.sei-apis.com",
      chainId: 1329,
      accounts: [process.env.PRIVATE_KEY],
    },
    "sei-testnet": {
      url: "https://evm-rpc-testnet.sei-apis.com",
      chainId: 713715,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: {
      sei: process.env.SEITRACE_API_KEY || "placeholder",
      "sei-testnet": process.env.SEITRACE_API_KEY || "placeholder",
    },
    customChains: [
      {
        network: "sei",
        chainId: 1329,
        urls: {
          apiURL: "https://seitrace.com/api",
          browserURL: "https://seitrace.com",
        },
      },
      {
        network: "sei-testnet",
        chainId: 713715,
        urls: {
          apiURL: "https://seitrace.com/api?chain=atlantic-2",
          browserURL: "https://testnet.seitrace.com",
        },
      },
    ],
  },
  sourcify: {
    enabled: false,
  },
};
```

## Verify a Contract

### Basic verification (no constructor arguments)

```bash
npx hardhat verify --network sei <CONTRACT_ADDRESS>
```

### With constructor arguments

```bash
npx hardhat verify --network sei <CONTRACT_ADDRESS> \
  "Argument1" "Argument2" 123
```

### ERC20 Token example

```bash
npx hardhat verify --network sei <CONTRACT_ADDRESS> \
  "MyToken" "MTK" 18 1000000 <OWNER_ADDRESS>
```

### ERC721 NFT example

```bash
npx hardhat verify --network sei <CONTRACT_ADDRESS> \
  "MyNFT Collection" "MNFT" 10000 10000000000000000 \
  "https://api.example.com/metadata/" <OWNER_ADDRESS>
```

### Using a constructor arguments file

For complex arguments, create `arguments.js`:

```js
module.exports = [
  "MyToken",
  "MTK",
  18,
  1000000,
  "0xYourOwnerAddress"
];
```

Then run:

```bash
npx hardhat verify --network sei <CONTRACT_ADDRESS> \
  --constructor-args arguments.js
```

## Verify on Sei Testnet

Replace `--network sei` with `--network sei-testnet`:

```bash
npx hardhat verify --network sei-testnet <CONTRACT_ADDRESS> \
  "MyToken" "MTK" 18 1000000 <OWNER_ADDRESS>
```

## Check Verification Status

After verification, view the contract on Seitrace:

- **Mainnet:** `https://seitrace.com/address/<CONTRACT_ADDRESS>`
- **Testnet:** `https://testnet.seitrace.com/address/<CONTRACT_ADDRESS>`

## Common Issues

### "Already verified"

The contract is already verified. No action needed.

### "Bytecode does not match"

- Ensure your local compiler settings (version, optimizer runs) match what was used during deployment
- Check `hardhat.config.js` optimizer settings

### "Contract source code could not be retrieved"

- Ensure you are verifying on the correct network
- Wait a few seconds after deployment before verifying

### Multiple files / imports

Hardhat automatically handles multi-file contracts and imports via source flattening. No manual steps needed.

## Resources

- [Sei Verify Contracts Docs](https://docs.sei.io/evm/evm-verify-contracts)
- [Seitrace Explorer](https://seitrace.com)
- [hardhat-verify Plugin Docs](https://hardhat.org/hardhat-runner/plugins/nomicfoundation-hardhat-verify)
