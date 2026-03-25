# Sei MCP Server for AI Assistants

Configures the Model Context Protocol (MCP) server for Sei, enabling AI assistants (Claude Desktop, Cursor, Continue) to interact directly with the Sei blockchain.

## Overview

The [Model Context Protocol](https://modelcontextprotocol.io) allows AI assistants to access external tools and data sources. The Sei MCP server provides blockchain-aware tools so you can ask an AI assistant questions like:

- "What is the SEI balance of 0xAbc...?"
- "Decode this Sei transaction: 0x..."
- "What is the total supply of this ERC-20 token?"
- "Look up the Sei cosmos address for this EVM address"

## Files

| File | Description |
|------|-------------|
| `config/mcp-config.json` | MCP server config for Claude Desktop / Cursor / Continue |

## Setup

### Claude Desktop

1. Open Claude Desktop settings
2. Navigate to: **Developer → Edit Config**
   - macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Windows: `%APPDATA%\Claude\claude_desktop_config.json`

3. Add the MCP server entry:

```json
{
  "mcpServers": {
    "sei-evm": {
      "command": "npx",
      "args": ["-y", "@sei-js/mcp-server"],
      "env": {
        "SEI_RPC_URL": "https://evm-rpc.sei-apis.com",
        "SEI_CHAIN_ID": "1329",
        "SEI_NETWORK": "mainnet"
      }
    }
  }
}
```

4. Restart Claude Desktop

### Cursor

Add to `.cursor/mcp.json` in your project root or `~/.cursor/mcp.json` globally:

```json
{
  "mcpServers": {
    "sei-evm": {
      "command": "npx",
      "args": ["-y", "@sei-js/mcp-server"],
      "env": {
        "SEI_RPC_URL": "https://evm-rpc.sei-apis.com",
        "SEI_CHAIN_ID": "1329"
      }
    }
  }
}
```

### Continue (VS Code / JetBrains)

Add to `~/.continue/config.json`:

```json
{
  "mcpServers": [
    {
      "name": "sei-evm",
      "command": "npx -y @sei-js/mcp-server",
      "env": {
        "SEI_RPC_URL": "https://evm-rpc.sei-apis.com"
      }
    }
  ]
}
```

## Available Tools (provided by the MCP server)

Once configured, the AI assistant gains access to tools including:

| Tool | Description |
|------|-------------|
| `get_balance` | Get SEI or ERC-20 token balance for an address |
| `get_transaction` | Look up transaction details by hash |
| `get_block` | Get block information by number or hash |
| `call_contract` | Read-only contract call (view functions) |
| `get_sei_address` | Convert EVM address to Sei cosmos address |
| `get_evm_address` | Convert Sei cosmos address to EVM address |
| `query_erc20` | Get ERC-20 token metadata and balances |

## Example Prompts

After setup, you can ask your AI assistant:

```
What is the current SEI balance of 0xYourAddress?

Decode this failed Sei transaction: 0xAbcDef...

What ERC-20 tokens does this address hold on Sei mainnet?

Convert this Sei cosmos address to its EVM equivalent: sei1abc...
```

## Network Configuration

| Parameter | Mainnet | Testnet |
|-----------|---------|---------|
| RPC URL | `https://evm-rpc.sei-apis.com` | `https://evm-rpc-testnet.sei-apis.com` |
| Chain ID | `1329` | `1328` |
| Explorer | `https://seitrace.com` | `https://seitrace.com/?chain=atlantic-2` |

## References

- [Sei MCP Server](https://docs.sei.io/evm/ai-tooling/mcp-server)
- [Model Context Protocol](https://modelcontextprotocol.io)
- [Sei JS MCP Package](https://www.npmjs.com/package/@sei-js/mcp-server)
