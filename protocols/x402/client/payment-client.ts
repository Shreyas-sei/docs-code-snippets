/**
 * payment-client.ts
 *
 * x402 Payment Client for Sei EVM.
 *
 * Demonstrates how a client handles the x402 payment flow:
 *   1. Make a request to a paid endpoint
 *   2. Receive a 402 response with payment requirements
 *   3. Submit the required USDC payment on Sei
 *   4. Retry the request with payment proof in the header
 *   5. Receive the paid content
 *
 * Usage:
 *   PRIVATE_KEY=0x... SERVER_URL=http://localhost:3000 ts-node client/payment-client.ts
 */

import { wrapFetchWithPayment, createX402Client } from "x402-fetch";
import { ethers } from "ethers";
import axios from "axios";

// ─────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────

const PRIVATE_KEY = process.env.PRIVATE_KEY!;
const SERVER_URL = process.env.SERVER_URL || "http://localhost:3000";
const USE_TESTNET = process.env.USE_TESTNET === "true";

const SEI_RPC = USE_TESTNET
  ? "https://evm-rpc-testnet.sei-apis.com"
  : "https://evm-rpc.sei-apis.com";

const SEI_CHAIN_ID = USE_TESTNET ? 713715 : 1329;

const USDC_ADDRESS = USE_TESTNET
  ? "0x0000000000000000000000000000000000000000" // replace with testnet USDC
  : "0x3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F1";

if (!PRIVATE_KEY) {
  console.error("Error: PRIVATE_KEY environment variable is required");
  process.exit(1);
}

// ─────────────────────────────────────────────
// Wallet setup
// ─────────────────────────────────────────────

const provider = new ethers.JsonRpcProvider(SEI_RPC);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

// ─────────────────────────────────────────────
// Helper: print balances
// ─────────────────────────────────────────────

async function printBalances() {
  const seiBalance = await provider.getBalance(wallet.address);
  console.log(`Wallet: ${wallet.address}`);
  console.log(`SEI balance: ${ethers.formatEther(seiBalance)} SEI`);

  // Read USDC balance
  const usdcAbi = ["function balanceOf(address) view returns (uint256)"];
  const usdc = new ethers.Contract(USDC_ADDRESS, usdcAbi, provider);
  try {
    const usdcBalance = await usdc.balanceOf(wallet.address);
    console.log(`USDC balance: ${ethers.formatUnits(usdcBalance, 6)} USDC`);
  } catch {
    console.log("USDC balance: unable to read (check contract address)");
  }
}

// ─────────────────────────────────────────────
// Method 1: Using x402-fetch wrapper (recommended)
// ─────────────────────────────────────────────

async function fetchWithX402() {
  console.log("\n── Method 1: x402-fetch wrapper ─────────────────────────");

  // Create a fetch client that automatically handles x402 payments
  const fetchWithPayment = wrapFetchWithPayment(fetch, wallet);

  // The wrapper automatically:
  //   1. Makes the initial request
  //   2. If 402, reads payment requirements from the response
  //   3. Approves and transfers USDC on-chain
  //   4. Retries the request with payment proof header

  try {
    console.log("Requesting /api/data ($0.01)...");
    const response = await fetchWithPayment(`${SERVER_URL}/api/data`);

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const data = await response.json();
    console.log("Response:", JSON.stringify(data, null, 2));
  } catch (err) {
    console.error("Error:", (err as Error).message);
  }
}

// ─────────────────────────────────────────────
// Method 2: Manual x402 flow (for debugging/custom logic)
// ─────────────────────────────────────────────

async function fetchManually() {
  console.log("\n── Method 2: Manual x402 flow ───────────────────────────");

  const usdcAbi = [
    "function approve(address spender, uint256 amount) returns (bool)",
    "function allowance(address owner, address spender) view returns (uint256)",
    "function balanceOf(address account) view returns (uint256)",
    "function transfer(address to, uint256 amount) returns (bool)",
  ];
  const usdc = new ethers.Contract(USDC_ADDRESS, usdcAbi, wallet);

  // Step 1: Make initial request
  console.log("\nStep 1: Initial request to /api/premium...");
  let response: any;
  try {
    response = await axios.get(`${SERVER_URL}/api/premium`, {
      validateStatus: () => true, // Don't throw on 4xx
    });
  } catch (err) {
    console.error("Request failed:", (err as Error).message);
    return;
  }

  if (response.status !== 402) {
    console.log(`Unexpected status: ${response.status}`);
    console.log(response.data);
    return;
  }

  // Step 2: Parse payment requirements from 402 response
  console.log("\nStep 2: Received 402 Payment Required");
  const paymentRequirements = response.data;
  console.log("Payment required:", JSON.stringify(paymentRequirements, null, 2));

  const { maxAmountRequired, payTo, asset, maxTimeoutSeconds } = paymentRequirements;

  // Step 3: Check USDC balance
  console.log("\nStep 3: Checking USDC balance...");
  const balance = await usdc.balanceOf(wallet.address);
  const required = BigInt(maxAmountRequired);
  console.log(`Required: ${ethers.formatUnits(required, 6)} USDC`);
  console.log(`Available: ${ethers.formatUnits(balance, 6)} USDC`);

  if (balance < required) {
    console.error("Insufficient USDC balance!");
    return;
  }

  // Step 4: Transfer USDC to the payment address
  console.log(`\nStep 4: Transferring ${ethers.formatUnits(required, 6)} USDC to ${payTo}...`);
  const transferTx = await usdc.transfer(payTo, required);
  const receipt = await transferTx.wait();
  console.log(`Payment confirmed: ${receipt.hash} (block ${receipt.blockNumber})`);

  // Step 5: Build payment proof header
  const paymentProof = {
    txHash: receipt.hash,
    chainId: SEI_CHAIN_ID,
    amount: required.toString(),
    asset: USDC_ADDRESS,
    payer: wallet.address,
    timestamp: Math.floor(Date.now() / 1000),
  };

  const proofHeader = Buffer.from(JSON.stringify(paymentProof)).toString("base64");

  // Step 6: Retry request with payment proof
  console.log("\nStep 5: Retrying request with payment proof...");
  const paidResponse = await axios.get(`${SERVER_URL}/api/premium`, {
    headers: {
      "X-PAYMENT": proofHeader,
    },
  });

  console.log("\nPremium content received:");
  console.log(JSON.stringify(paidResponse.data, null, 2));
}

// ─────────────────────────────────────────────
// Method 3: x402 client for multiple requests
// ─────────────────────────────────────────────

async function batchRequests() {
  console.log("\n── Method 3: Multiple paid requests ─────────────────────");

  const client = createX402Client({
    wallet,
    maxPaymentPerRequest: ethers.parseUnits("1.00", 6).toString(), // $1.00 max per request
  });

  const endpoints = [
    { path: "/api/data", description: "$0.01" },
    { path: "/api/data", description: "$0.01 again" },
    { path: "/api/premium", description: "$0.10" },
  ];

  for (const endpoint of endpoints) {
    try {
      console.log(`\nFetching ${endpoint.path} (${endpoint.description})...`);
      const response = await client.fetch(`${SERVER_URL}${endpoint.path}`);
      const data = await response.json();
      console.log(`Success: ${JSON.stringify(data).substring(0, 100)}...`);
    } catch (err) {
      console.error(`Failed: ${(err as Error).message}`);
    }
  }
}

// ─────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────

async function main() {
  console.log("=".repeat(60));
  console.log("x402 Payment Client — Sei EVM");
  console.log("=".repeat(60));

  await printBalances();

  // Check server is running
  try {
    const healthResponse = await axios.get(`${SERVER_URL}/health`);
    console.log(`\nServer status: ${healthResponse.data.status}`);
  } catch {
    console.error(`\nError: Cannot reach server at ${SERVER_URL}`);
    console.error("Start the server first: ts-node server/payment-server.ts");
    process.exit(1);
  }

  await fetchWithX402();
  await fetchManually();
  await batchRequests();

  console.log("\n" + "=".repeat(60));
  console.log("All requests complete");
  console.log("=".repeat(60));

  // Print final balances
  await printBalances();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
