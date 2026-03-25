# Docs Code Snippets

Curated repository of complete, runnable code examples extracted from the [Sei EVM documentation](https://docs.sei.io/evm). Structured for developers who want working code fast, and AI/LLM systems that need tagged, machine-readable examples to generate accurate answers about building on Sei.

## Quick Start

```bash
git clone https://github.com/your-org/docs-code-snippets
cd docs-code-snippets
```

Pick an example, install its dependencies, and run it:

```bash
cd smart-contracts/erc20-token
npm install
npx hardhat run scripts/deploy.js --network sei-testnet
```

## Network Details

| Network                  | Chain ID | RPC                                  | Explorer                               |
| ------------------------ | -------- | ------------------------------------ | -------------------------------------- |
| Sei Mainnet              | 1329     | https://evm-rpc.sei-apis.com         | https://seitrace.com                   |
| Sei Testnet (atlantic-2) | 1328     | https://evm-rpc-testnet.sei-apis.com | https://seitrace.com/?chain=atlantic-2 |

## Repository Structure

```
docs-code-snippets/
├── llms.txt                        # AI-friendly index of all examples
├── manifest.json                   # Machine-readable registry (tags, metadata, chain info)
├── README.md                       # This file
│
├── smart-contracts/
│   ├── getting-started/            # Coin.sol (Solidity), Auction.vy (Vyper)
│   ├── erc20-token/                # ERC20 — Hardhat + Foundry variants
│   ├── erc721-nft/                 # ERC721 — Hardhat + Foundry variants
│   ├── upgradeable-uups/           # UUPS proxy V1+V2, deploy + upgrade scripts
│   ├── counter/                    # Foundry starter with fuzz tests
│   └── verification/               # Seitrace verify guide (Hardhat + Foundry)
│
├── precompiles/
│   ├── example-usage/              # ethers.js quickstart for all precompiles
│   ├── distribution/               # YieldAggregator, ValidatorCommissionManager
│   ├── staking/                    # StakingManager — delegate/undelegate/redelegate
│   ├── governance/                 # GovernanceVoter — vote + submit proposals
│   ├── oracle/                     # OraclePriceFeed — prices + TWAP
│   ├── json/                       # JsonParser — on-chain JSON parsing
│   ├── p256/                       # P256 sig verification (EIP-7212 / WebAuthn)
│   └── cosmos/                     # addr, bank, CosmWasm, IBC, pointer precompiles
│
├── frontend/
│   ├── connect-wallet/             # RainbowKit + wagmi + Sei Global Wallet
│   ├── read-write-contract/        # wagmi hooks — useReadContract/useWriteContract
│   └── in-app-swaps/               # Token swap UI + DEX integration pattern
│
├── wallet-integrations/
│   ├── particle/                   # Particle Auth + ERC-4337 Smart Account
│   ├── pimlico/                    # Pimlico bundler + paymaster (ERC-4337)
│   ├── thirdweb-4337/              # Thirdweb ERC-4337 smart wallet
│   └── thirdweb-7702/              # Thirdweb EIP-7702 wallet delegation
│
├── bridging/
│   ├── layerzero/                  # OFT bridge contract + deployment
│   └── thirdweb/                   # Thirdweb PayEmbed cross-chain bridge
│
├── oracles/
│   ├── chainlink/                  # Chainlink AggregatorV3 price feed consumer
│   ├── pyth/                       # Pyth pull oracle + Hermes VAA fetcher
│   ├── redstone/                   # RedStone Classic calldata-injection oracle
│   └── api3/                       # API3 dAPI proxy consumer
│
├── vrf/
│   └── pyth/                       # Pyth Entropy dice game (IEntropyConsumer)
│
├── indexers/
│   ├── goldsky/                    # Goldsky subgraph (manifest + schema + mappings)
│   ├── the-graph/                  # The Graph subgraph
│   └── moralis/                    # Moralis Streams + webhook handler
│
├── ai-tooling/
│   ├── mcp-server/                 # MCP server config for Claude Desktop / Cursor
│   └── cambrian/                   # Cambrian Agent Kit + LangChain ReAct agent
│
└── protocols/
    ├── usdc/                       # USDC integration patterns + contract addresses
    └── x402/                       # x402 HTTP payment protocol server + client
```

## Design Principles

- **Function-based taxonomy** — Examples organized by what the code does, not by docs nav structure.
- **Complete and runnable** — Only full contracts, scripts, and configs. No isolated snippets.
- **Docs link preserved** — Every example links back to its source via `docs_urls` in `metadata.json`.
- **AI-ingestible** — Root `manifest.json` indexes every example with tags, descriptions, difficulty, tooling, and chain info. `llms.txt` provides a plain-text entry point for AI crawlers.
- **Per-example metadata** — Each folder has `metadata.json` with title, description, tags, `docs_urls`, dependencies, tooling, and `last_verified` date.

## Example Index

| Example                                                 | Difficulty   | Tooling           | Category        |
| ------------------------------------------------------- | ------------ | ----------------- | --------------- |
| [Getting Started](smart-contracts/getting-started/)     | Beginner     | solc, vyper       | Smart Contracts |
| [ERC20 Token](smart-contracts/erc20-token/)             | Beginner     | Hardhat, Foundry  | Smart Contracts |
| [ERC721 NFT](smart-contracts/erc721-nft/)               | Intermediate | Hardhat, Foundry  | Smart Contracts |
| [UUPS Upgradeable](smart-contracts/upgradeable-uups/)   | Advanced     | Hardhat           | Smart Contracts |
| [Counter + Fuzz Tests](smart-contracts/counter/)        | Beginner     | Foundry           | Smart Contracts |
| [Contract Verification](smart-contracts/verification/)  | Beginner     | Hardhat, Foundry  | Smart Contracts |
| [Precompile Examples (JS)](precompiles/example-usage/)  | Beginner     | ethers.js         | Precompiles     |
| [Distribution Precompile](precompiles/distribution/)    | Intermediate | Hardhat           | Precompiles     |
| [Staking Precompile](precompiles/staking/)              | Intermediate | Hardhat           | Precompiles     |
| [Governance Precompile](precompiles/governance/)        | Beginner     | Hardhat           | Precompiles     |
| [Oracle Precompile](precompiles/oracle/)                | Intermediate | Hardhat           | Precompiles     |
| [JSON Precompile](precompiles/json/)                    | Intermediate | Hardhat           | Precompiles     |
| [P256 Precompile (EIP-7212)](precompiles/p256/)         | Advanced     | Hardhat           | Precompiles     |
| [Cosmos Precompiles](precompiles/cosmos/)               | Advanced     | Hardhat           | Precompiles     |
| [Connect Wallet](frontend/connect-wallet/)              | Beginner     | wagmi, RainbowKit | Frontend        |
| [Read/Write Contract](frontend/read-write-contract/)    | Beginner     | wagmi             | Frontend        |
| [In-App Swaps](frontend/in-app-swaps/)                  | Intermediate | wagmi             | Frontend        |
| [Particle Auth + AA](wallet-integrations/particle/)     | Intermediate | Particle Network  | Wallet          |
| [Pimlico ERC-4337](wallet-integrations/pimlico/)        | Intermediate | Pimlico           | Wallet          |
| [Thirdweb ERC-4337](wallet-integrations/thirdweb-4337/) | Intermediate | Thirdweb          | Wallet          |
| [Thirdweb EIP-7702](wallet-integrations/thirdweb-7702/) | Intermediate | Thirdweb          | Wallet          |
| [LayerZero OFT Bridge](bridging/layerzero/)             | Intermediate | LayerZero v2      | Bridging        |
| [Thirdweb Bridge](bridging/thirdweb/)                   | Beginner     | Thirdweb          | Bridging        |
| [Chainlink Oracle](oracles/chainlink/)                  | Beginner     | Chainlink         | Oracles         |
| [Pyth Price Feeds](oracles/pyth/)                       | Intermediate | Pyth              | Oracles         |
| [RedStone Oracle](oracles/redstone/)                    | Intermediate | RedStone          | Oracles         |
| [API3 dAPI](oracles/api3/)                              | Beginner     | API3              | Oracles         |
| [Pyth VRF Dice Game](vrf/pyth/)                         | Intermediate | Pyth Entropy      | VRF             |
| [Goldsky Subgraph](indexers/goldsky/)                   | Intermediate | Goldsky CLI       | Indexers        |
| [The Graph Subgraph](indexers/the-graph/)               | Intermediate | Graph CLI         | Indexers        |
| [Moralis Streams](indexers/moralis/)                    | Beginner     | Moralis           | Indexers        |
| [Sei MCP Server](ai-tooling/mcp-server/)                | Beginner     | MCP               | AI Tooling      |
| [Cambrian Agent Kit](ai-tooling/cambrian/)              | Intermediate | LangChain         | AI Tooling      |
| [USDC Integration](protocols/usdc/)                     | Beginner     | Hardhat           | Protocols       |
| [x402 Payments](protocols/x402/)                        | Intermediate | Express           | Protocols       |

## Per-Example Structure

Every example folder follows this layout:

```
example-name/
├── README.md          # Overview, prerequisites, usage instructions, docs link
├── metadata.json      # Machine-readable metadata (tags, difficulty, docs_urls, etc.)
└── [source files]     # Contracts, scripts, configs, components — all complete and runnable
```

### metadata.json schema

```json
{
  "title": "Example Name",
  "description": "What this example demonstrates",
  "tags": ["erc20", "hardhat", "sei", "deploy"],
  "difficulty": "beginner | intermediate | advanced",
  "tooling": ["hardhat", "foundry", "ethers"],
  "chain": "sei-mainnet",
  "docs_urls": ["https://docs.sei.io/evm/..."],
  "dependencies": ["@openzeppelin/contracts"],
  "last_verified": "2025-03-25"
}
```

## AI / LLM Usage

This repo is structured for AI ingestion:

- **`llms.txt`** — Plain-text index of all examples with file descriptions and tags. Entry point for AI crawlers.
- **`manifest.json`** — Full machine-readable registry with tags, difficulty, tooling, docs URLs, and file lists for all 35 examples.
- Each `metadata.json` provides structured per-example context for RAG/embedding pipelines.

## Contributing

1. Fork the repo
2. Create a new example folder under the appropriate category
3. Include `README.md`, `metadata.json`, and complete runnable source files
4. Ensure `docs_urls` in `metadata.json` points to the canonical Sei docs page
5. Add your example to `manifest.json` and `llms.txt`
6. Open a pull request

### Contribution checklist

- [ ] Example is complete and runnable (not just a snippet)
- [ ] `metadata.json` follows the schema above
- [ ] `docs_urls` are valid and point to https://docs.sei.io/evm/...
- [ ] README has prerequisites, setup steps, and expected output
- [ ] No hardcoded private keys or API keys
- [ ] `last_verified` is set to today's date

## License

MIT
