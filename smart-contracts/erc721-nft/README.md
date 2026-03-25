# ERC721 NFT Collection on Sei EVM

This example demonstrates deploying an ERC721 NFT collection on the Sei EVM network using both Hardhat and Foundry.

## Contract Features

- Standard ERC721 transfers and approvals
- Enumerable (on-chain token listing)
- URI storage per token
- Pausable transfers (owner only)
- Burnable
- Public mint with configurable price
- Owner airdrop (free mint)
- Withdraw collected mint fees
- Configurable max supply and base URI

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
npx hardhat verify --network sei <CONTRACT_ADDRESS> \
  "MyNFT Collection" "MNFT" 10000 10000000000000000 \
  "https://api.example.com/metadata/" <DEPLOYER_ADDRESS>
```

## Foundry Setup

```bash
cd foundry
forge install OpenZeppelin/openzeppelin-contracts
```

### Deploy to Sei Testnet

```bash
forge script script/Deploy.s.sol:DeployMyNFT \
  --rpc-url sei-testnet \
  --broadcast \
  --verify \
  -vvvv
```

## Sei Network Details

| Network  | RPC URL                                   | Chain ID |
|----------|-------------------------------------------|----------|
| Mainnet  | https://evm-rpc.sei-apis.com             | 1329     |
| Testnet  | https://evm-rpc-testnet.sei-apis.com     | 713715   |

## Resources

- [Sei Hardhat Docs](https://docs.sei.io/evm/evm-hardhat)
- [Sei Foundry Docs](https://docs.sei.io/evm/evm-foundry)
- [OpenZeppelin ERC721](https://docs.openzeppelin.com/contracts/5.x/erc721)
- [Seitrace Explorer](https://seitrace.com)
