/**
 * handler.js
 *
 * Express webhook handler for Moralis Streams on Sei EVM.
 * Receives real-time blockchain event notifications and processes them.
 *
 * Usage:
 *   MORALIS_API_KEY=... MORALIS_STREAM_SECRET=... PORT=3000 node handler.js
 *
 * Set your webhook URL in the Moralis Stream to:
 *   https://your-domain.com/webhook
 */

const express = require("express");
const Moralis = require("moralis").default;
const crypto = require("crypto");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const MORALIS_API_KEY = process.env.MORALIS_API_KEY;
const MORALIS_STREAM_SECRET = process.env.MORALIS_STREAM_SECRET || "";

// ─────────────────────────────────────────────
// Signature verification
// ─────────────────────────────────────────────

/**
 * Verify the Moralis webhook signature to ensure authenticity
 * @param {string} body    Raw request body string
 * @param {string} signature  x-signature header value
 */
function verifyMoralisSignature(body, signature) {
  if (!MORALIS_STREAM_SECRET) {
    console.warn("Warning: MORALIS_STREAM_SECRET not set — skipping signature verification");
    return true;
  }
  const expectedSig = crypto
    .createHmac("sha3-256", MORALIS_STREAM_SECRET)
    .update(body)
    .digest("hex");
  return expectedSig === signature;
}

// ─────────────────────────────────────────────
// Event processors
// ─────────────────────────────────────────────

/**
 * Process ERC-20 Transfer events
 */
function processTransfers(body) {
  const { txs, logs, chainId, block } = body;

  if (!logs || logs.length === 0) return;

  console.log(`\n[Block ${block?.number}] Processing ${logs.length} log(s) on chain ${chainId}`);

  for (const log of logs) {
    // Moralis decodes event data based on the ABI provided during stream creation
    if (log.topic0 === "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef") {
      // Transfer(address,address,uint256)
      const from = "0x" + log.topic1?.slice(26);
      const to = "0x" + log.topic2?.slice(26);
      const value = BigInt("0x" + (log.data || "0"));

      console.log(`  Transfer: ${from} -> ${to}`);
      console.log(`  Amount:   ${value.toString()}`);
      console.log(`  Tx:       ${log.transactionHash}`);
      console.log(`  Contract: ${log.address}`);

      // TODO: persist to database, trigger notifications, update cache, etc.
    }

    if (log.topic0 === "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925") {
      // Approval(address,address,uint256)
      const owner = "0x" + log.topic1?.slice(26);
      const spender = "0x" + log.topic2?.slice(26);
      const value = BigInt("0x" + (log.data || "0"));

      console.log(`  Approval: ${owner} approved ${spender}`);
      console.log(`  Amount:   ${value.toString()}`);
    }
  }
}

/**
 * Process native SEI transactions
 */
function processNativeTransactions(body) {
  const { txs, chainId, block } = body;

  if (!txs || txs.length === 0) return;

  console.log(`\n[Block ${block?.number}] Processing ${txs.length} native tx(s)`);

  for (const tx of txs) {
    console.log(`  Tx:    ${tx.hash}`);
    console.log(`  From:  ${tx.fromAddress}`);
    console.log(`  To:    ${tx.toAddress}`);
    console.log(`  Value: ${tx.value} wei`);
    console.log(`  Gas:   ${tx.gasUsed} @ ${tx.gasPrice} gwei`);

    // TODO: add your business logic here
  }
}

/**
 * Process decoded EVM events (when ABI is provided in stream config)
 */
function processDecodedEvents(body) {
  if (!body.erc20Transfers || body.erc20Transfers.length === 0) return;

  console.log(`\nDecoded ERC-20 transfers:`);
  for (const transfer of body.erc20Transfers) {
    console.log(`  ${transfer.from} -> ${transfer.to}: ${transfer.value} ${transfer.tokenSymbol}`);
    console.log(`  Contract: ${transfer.contract}`);
    console.log(`  USD value: $${transfer.valueWithDecimals}`);
  }
}

// ─────────────────────────────────────────────
// Webhook route
// ─────────────────────────────────────────────

app.post("/webhook", (req, res) => {
  // Verify signature
  const signature = req.headers["x-signature"];
  const rawBody = JSON.stringify(req.body);

  if (!verifyMoralisSignature(rawBody, signature)) {
    console.error("Invalid webhook signature — rejecting request");
    return res.status(401).json({ error: "Invalid signature" });
  }

  const body = req.body;

  // Moralis sends a test event on stream creation — acknowledge it
  if (body.streamId && !body.block) {
    console.log("Received Moralis handshake event");
    return res.status(200).json({ success: true });
  }

  console.log("=".repeat(60));
  console.log(`Webhook received | Stream: ${body.streamId} | Tag: ${body.tag}`);
  console.log(`Chain: ${body.chainId} | Block: ${body.block?.number}`);

  try {
    processTransfers(body);
    processNativeTransactions(body);
    processDecodedEvents(body);

    // Always respond 200 quickly — Moralis will retry on failure
    res.status(200).json({ success: true });
  } catch (err) {
    console.error("Error processing webhook:", err);
    // Still return 200 to prevent Moralis retries for processing errors
    res.status(200).json({ success: false, error: err.message });
  }
});

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// ─────────────────────────────────────────────
// Start server
// ─────────────────────────────────────────────

async function startServer() {
  if (MORALIS_API_KEY) {
    await Moralis.start({ apiKey: MORALIS_API_KEY });
    console.log("Moralis SDK initialized");
  }

  app.listen(PORT, () => {
    console.log(`Webhook server running on port ${PORT}`);
    console.log(`Listening at http://localhost:${PORT}/webhook`);
    console.log("Use ngrok or similar to expose this to the internet for testing:");
    console.log(`  ngrok http ${PORT}`);
  });
}

startServer().catch((err) => {
  console.error(err);
  process.exit(1);
});

module.exports = app;
