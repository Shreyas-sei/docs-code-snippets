/**
 * agent.ts
 *
 * Cambrian Agent Kit setup for Sei EVM.
 * Demonstrates building an AI agent that can interact with the Sei blockchain —
 * checking balances, transferring tokens, querying contracts, and executing DeFi operations.
 *
 * Cambrian Agent Kit: https://docs.cambrian.ai
 * Sei EVM Docs: https://docs.sei.io/evm/ai-tooling/cambrian
 *
 * Usage:
 *   OPENAI_API_KEY=... PRIVATE_KEY=0x... ts-node src/agent.ts
 */

import { CambrianAgentKit, CambrianToolkit } from "@cambrian-ai/agent-kit";
import { ChatOpenAI } from "@langchain/openai";
import { createReactAgent } from "@langchain/langgraph/prebuilt";
import { HumanMessage } from "@langchain/core/messages";
import { ethers } from "ethers";

// ─────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────

const SEI_MAINNET_RPC = "https://evm-rpc.sei-apis.com";
const SEI_TESTNET_RPC = "https://evm-rpc-testnet.sei-apis.com";

const PRIVATE_KEY = process.env.PRIVATE_KEY!;
const OPENAI_API_KEY = process.env.OPENAI_API_KEY!;
const USE_TESTNET = process.env.USE_TESTNET === "true";

if (!PRIVATE_KEY || !OPENAI_API_KEY) {
  console.error("Error: PRIVATE_KEY and OPENAI_API_KEY environment variables are required");
  process.exit(1);
}

// ─────────────────────────────────────────────
// Initialise Cambrian Agent Kit with Sei
// ─────────────────────────────────────────────

async function createSeiAgent() {
  const rpcUrl = USE_TESTNET ? SEI_TESTNET_RPC : SEI_MAINNET_RPC;
  const chainId = USE_TESTNET ? 713715 : 1329;

  console.log(`Initialising Cambrian Agent Kit on Sei ${USE_TESTNET ? "Testnet" : "Mainnet"}`);
  console.log(`RPC: ${rpcUrl} | Chain ID: ${chainId}`);

  // ── 1. Create the Cambrian Agent Kit instance ──────────────────────
  const agentKit = await CambrianAgentKit.create({
    privateKey: PRIVATE_KEY,
    rpcUrl,
    chainId,
    // Optional: specify which tool categories to enable
    tools: {
      erc20: true,       // ERC-20 read/write operations
      balance: true,     // Native token balance queries
      contracts: true,   // Generic contract interaction
      defi: true,        // DeFi protocol interactions (swaps, liquidity)
      nft: false,        // ERC-721/1155 operations
    },
  });

  const walletAddress = await agentKit.getAddress();
  console.log(`Agent wallet: ${walletAddress}`);

  // ── 2. Load the toolkit (LangChain-compatible tools) ───────────────
  const toolkit = new CambrianToolkit({ agentKit });
  const tools = toolkit.getTools();

  console.log(`Loaded ${tools.length} tools: ${tools.map((t) => t.name).join(", ")}`);

  // ── 3. Create the LLM ──────────────────────────────────────────────
  const llm = new ChatOpenAI({
    model: "gpt-4o",
    temperature: 0,
    apiKey: OPENAI_API_KEY,
  });

  // ── 4. Create the ReAct agent ──────────────────────────────────────
  const agent = createReactAgent({
    llm,
    tools,
    messageModifier: `
You are a helpful AI assistant that can interact with the Sei blockchain.
You have access to tools for:
- Checking native SEI balances
- Reading and transferring ERC-20 tokens
- Querying smart contracts
- Executing DeFi operations

Always confirm transaction details with the user before executing state-changing operations.
When reporting balances or amounts, always include the token symbol and format with appropriate decimals.
The current network is Sei ${USE_TESTNET ? "Testnet (chain ID 713715)" : "Mainnet (chain ID 1329)"}.
Your wallet address is: ${walletAddress}
    `.trim(),
  });

  return { agent, agentKit, walletAddress };
}

// ─────────────────────────────────────────────
// Example agent interactions
// ─────────────────────────────────────────────

async function runDemoInteractions(agent: ReturnType<typeof createReactAgent>) {
  const prompts = [
    "What is the native SEI balance of my wallet?",
    "What is the total supply of the USDC token at 0x3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F1?",
    "Check the ETH balance of vitalik.eth on Sei",
  ];

  for (const prompt of prompts) {
    console.log("\n" + "─".repeat(60));
    console.log(`Prompt: ${prompt}`);
    console.log("─".repeat(60));

    const response = await agent.invoke({
      messages: [new HumanMessage(prompt)],
    });

    const lastMessage = response.messages[response.messages.length - 1];
    console.log(`Response: ${lastMessage.content}`);
  }
}

// ─────────────────────────────────────────────
// Interactive mode
// ─────────────────────────────────────────────

async function runInteractiveMode(agent: ReturnType<typeof createReactAgent>) {
  const readline = require("readline");
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  console.log('\nInteractive mode started. Type "exit" to quit.');
  console.log('─'.repeat(60));

  const askQuestion = () => {
    rl.question("\nYou: ", async (input: string) => {
      if (input.toLowerCase() === "exit") {
        console.log("Goodbye!");
        rl.close();
        return;
      }

      try {
        const response = await agent.invoke({
          messages: [new HumanMessage(input)],
        });
        const lastMessage = response.messages[response.messages.length - 1];
        console.log(`\nAgent: ${lastMessage.content}`);
      } catch (err) {
        console.error(`Error: ${(err as Error).message}`);
      }

      askQuestion();
    });
  };

  askQuestion();
}

// ─────────────────────────────────────────────
// Direct agent kit usage (without LLM)
// ─────────────────────────────────────────────

async function demonstrateDirectUsage(agentKit: CambrianAgentKit) {
  console.log("\n── Direct AgentKit Usage (no LLM) ───────────────────────");

  // Check native balance
  const balance = await agentKit.getBalance();
  console.log(`Native SEI balance: ${ethers.formatEther(balance)} SEI`);

  // Get ERC-20 token info
  const usdcAddress = "0x3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F1"; // USDC on Sei testnet
  try {
    const tokenInfo = await agentKit.getERC20Info(usdcAddress);
    console.log(`Token: ${tokenInfo.name} (${tokenInfo.symbol}), decimals: ${tokenInfo.decimals}`);

    const tokenBalance = await agentKit.getERC20Balance(usdcAddress);
    console.log(`USDC balance: ${ethers.formatUnits(tokenBalance, tokenInfo.decimals)}`);
  } catch (err) {
    console.log("Could not fetch USDC info (may not exist on this network)");
  }
}

// ─────────────────────────────────────────────
// Main entry point
// ─────────────────────────────────────────────

async function main() {
  console.log("=".repeat(60));
  console.log("Cambrian Agent Kit — Sei EVM");
  console.log("=".repeat(60));

  const { agent, agentKit, walletAddress } = await createSeiAgent();

  // Run direct usage demo
  await demonstrateDirectUsage(agentKit);

  // Run demo prompts
  if (process.argv.includes("--demo")) {
    await runDemoInteractions(agent);
  } else {
    // Start interactive mode
    await runInteractiveMode(agent);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
