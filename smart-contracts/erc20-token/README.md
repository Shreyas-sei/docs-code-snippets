# ERC20 Token on Sei EVM

This example demonstrates deploying a full-featured ERC20 token on the Sei EVM network using both Hardhat and Foundry.

## Contract Features

- Standard ERC20 transfers and approvals
- Mintable (owner only)
- Burnable (token holder)
- Pausable (owner only)
- ERC20Permit (gasless approvals via EIP-2612)
- Configurable decimals

## Hardhat Setup

### Install dependencies

```bash
npm install
```

### Configure environment

Create a `.env` file:

```
PRIVATE_KEY=your_private_key_here
SEITRACE_API_KEY=your_api_key_here
```

### Compile

```bash
npx hardhat compile
```

### Test

```bash
npx hardhat test
```

### Deploy to Sei Testnet

```bash
npx hardhat run scripts/deploy.js --network sei-testnet
```

### Deploy to Sei Mainnet

```bash
npx hardhat run scripts/deploy.js --network sei
```

### Verify on Seitrace

```bash
npx hardhat verify --network sei <CONTRACT_ADDRESS> "MyToken" "MTK" 18 1000000 <DEPLOYER_ADDRESS>
```

## Foundry Setup

```bash
cd foundry
forge install OpenZeppelin/openzeppelin-contracts
```

### Compile

```bash
forge build
```

### Test

```bash
forge test -vvv
```

### Deploy to Sei Testnet

```bash
forge script script/Deploy.s.sol:DeployMyToken \
  --rpc-url sei-testnet \
  --broadcast \
  --verify \
  -vvvv
```

### Deploy to Sei Mainnet

```bash
forge script script/Deploy.s.sol:DeployMyToken \
  --rpc-url sei \
  --broadcast \
  --verify \
  -vvvv
```

## Sei Network Details

| Network  | RPC URL                                   | Chain ID |
|----------|-------------------------------------------|----------|
| Mainnet  | https://evm-rpc.sei-apis.com             | 1329     |
| Testnet  | https://evm-rpc-testnet.sei-apis.com     | 1328   |

## Resources

- [Sei Hardhat Docs](https://docs.sei.io/evm/evm-hardhat)
- [Sei Foundry Docs](https://docs.sei.io/evm/evm-foundry)
- [OpenZeppelin ERC20](https://docs.openzeppelin.com/contracts/5.x/erc20)
- [Seitrace Explorer](https://seitrace.com)
