/**
 * createStream.js
 *
 * Sets up a Moralis Stream to watch ERC-20 Transfer events on Sei EVM and
 * deliver them to a webhook endpoint in real-time.
 *
 * Usage:
 *   MORALIS_API_KEY=... WEBHOOK_URL=https://... node createStream.js
 *
 * Moralis Streams API docs: https://docs.moralis.io/streams-api/evm
 *
 * Sei chain ID in Moralis:
 *   Mainnet: 0x531 (1329 decimal)
 *   Testnet: 0xAE6B3 (713715 decimal)
 */

const Moralis = require("moralis").default;
const { EvmChain } = require("@moralisweb3/common-evm-utils");

// ─────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────

const MORALIS_API_KEY = process.env.MORALIS_API_KEY;
const WEBHOOK_URL = process.env.WEBHOOK_URL || "https://your-server.com/webhook";

if (!MORALIS_API_KEY) {
  console.error("Error: MORALIS_API_KEY environment variable is required");
  process.exit(1);
}

// Target contract to watch (set to your contract address)
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS || "0x0000000000000000000000000000000000000000";

// Sei mainnet chain ID
const SEI_CHAIN_ID = "0x531"; // 1329

// ─────────────────────────────────────────────
// ERC-20 Transfer ABI (minimal, for event decoding)
// ─────────────────────────────────────────────

const ERC20_TRANSFER_ABI = [
  {
    anonymous: false,
    inputs: [
      { indexed: true, name: "from", type: "address" },
      { indexed: true, name: "to", type: "address" },
      { indexed: false, name: "value", type: "uint256" },
    ],
    name: "Transfer",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, name: "owner", type: "address" },
      { indexed: true, name: "spender", type: "address" },
      { indexed: false, name: "value", type: "uint256" },
    ],
    name: "Approval",
    type: "event",
  },
];

// ─────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────

async function main() {
  console.log("Initializing Moralis...");
  await Moralis.start({ apiKey: MORALIS_API_KEY });

  // ── Create ERC-20 Transfer stream ────────────────────────────────────
  console.log("\nCreating ERC-20 Transfer stream on Sei...");

  const transferStream = await Moralis.Streams.add({
    chains: [SEI_CHAIN_ID],
    description: "Sei ERC-20 Transfer Events",
    tag: "sei-erc20-transfers",
    webhookUrl: WEBHOOK_URL,
    includeNativeTxs: false,
    includeContractLogs: true,
    includeInternalTxs: false,
    abi: ERC20_TRANSFER_ABI,
    topic0: ["Transfer(address,address,uint256)"],
    advancedOptions: [
      {
        topic0: "Transfer(address,address,uint256)",
        filter: {
          // Only include transfers with value > 0
          "gt": ["$value", "0"],
        },
        includeNativeTxs: false,
      },
    ],
  });

  const transferStreamId = transferStream.toJSON().id;
  console.log(`Transfer stream created: ${transferStreamId}`);

  // ── Add the specific contract address to watch ────────────────────────
  if (CONTRACT_ADDRESS !== "0x0000000000000000000000000000000000000000") {
    console.log(`\nAdding contract address: ${CONTRACT_ADDRESS}`);
    await Moralis.Streams.addAddress({
      id: transferStreamId,
      address: [CONTRACT_ADDRESS],
    });
    console.log("Contract address added to stream");
  }

  // ── Create a native transaction stream (optional) ─────────────────────
  console.log("\nCreating native SEI transaction stream...");

  const nativeTxStream = await Moralis.Streams.add({
    chains: [SEI_CHAIN_ID],
    description: "Sei Native Transactions",
    tag: "sei-native-txs",
    webhookUrl: WEBHOOK_URL + "/native",
    includeNativeTxs: true,
    includeContractLogs: false,
    includeInternalTxs: false,
  });

  const nativeStreamId = nativeTxStream.toJSON().id;
  console.log(`Native TX stream created: ${nativeStreamId}`);

  // ── List all streams ──────────────────────────────────────────────────
  console.log("\n── Active Streams ───────────────────────────────────────");
  const streams = await Moralis.Streams.getAll({ limit: 100 });
  for (const stream of streams.toJSON().result) {
    console.log(`[${stream.id}] ${stream.tag} → ${stream.webhookUrl}`);
    console.log(`  Status: ${stream.status}, Chains: ${stream.chains.join(", ")}`);
  }

  // ── Print management commands ─────────────────────────────────────────
  console.log("\n── Management ───────────────────────────────────────────");
  console.log("Pause stream:   Moralis.Streams.update({ id, status: 'paused' })");
  console.log("Delete stream:  Moralis.Streams.delete({ id })");
  console.log("Get history:    Moralis.Streams.getHistory({ id })");
  console.log("\nSave these stream IDs to your .env:");
  console.log(`  MORALIS_TRANSFER_STREAM_ID=${transferStreamId}`);
  console.log(`  MORALIS_NATIVE_STREAM_ID=${nativeStreamId}`);
}

// ─────────────────────────────────────────────
// Stream management utilities
// ─────────────────────────────────────────────

async function pauseStream(streamId) {
  await Moralis.start({ apiKey: MORALIS_API_KEY });
  await Moralis.Streams.update({ id: streamId, status: "paused" });
  console.log(`Stream ${streamId} paused`);
}

async function deleteStream(streamId) {
  await Moralis.start({ apiKey: MORALIS_API_KEY });
  await Moralis.Streams.delete({ id: streamId });
  console.log(`Stream ${streamId} deleted`);
}

async function getStreamHistory(streamId, limit = 100) {
  await Moralis.start({ apiKey: MORALIS_API_KEY });
  const history = await Moralis.Streams.getHistory({ id: streamId, limit });
  return history.toJSON();
}

module.exports = { pauseStream, deleteStream, getStreamHistory };

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
