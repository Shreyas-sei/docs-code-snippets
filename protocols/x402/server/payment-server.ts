/**
 * payment-server.ts
 *
 * x402 Payment Server for Sei EVM.
 *
 * x402 is an HTTP payment protocol that uses HTTP 402 "Payment Required" responses
 * to gate content/API access behind on-chain micropayments in USDC or other ERC-20 tokens.
 *
 * Flow:
 *   1. Client requests a resource
 *   2. Server returns 402 with payment requirements
 *   3. Client submits an on-chain payment and retries with proof
 *   4. Server verifies the payment and returns the resource
 *
 * Usage:
 *   PRIVATE_KEY=0x... PORT=3000 ts-node server/payment-server.ts
 *
 * x402 Docs: https://docs.x402.org
 * Sei x402 Docs: https://docs.sei.io/evm/x402
 */

import express, { Request, Response, NextFunction } from "express";
import { paymentMiddleware, Resource, PaymentRequirements } from "x402-express";
import { ethers } from "ethers";

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;

// ─────────────────────────────────────────────
// Sei network configuration
// ─────────────────────────────────────────────

const SEI_MAINNET = {
  rpcUrl: "https://evm-rpc.sei-apis.com",
  chainId: 1329,
  usdcAddress: "0x3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F1",
};

const SEI_TESTNET = {
  rpcUrl: "https://evm-rpc-testnet.sei-apis.com",
  chainId: 1328,
  usdcAddress: "0x0000000000000000000000000000000000000000", // update with testnet USDC
};

const network = process.env.USE_TESTNET === "true" ? SEI_TESTNET : SEI_MAINNET;

// ─────────────────────────────────────────────
// Facilitator / payment receiver wallet
// ─────────────────────────────────────────────

const PRIVATE_KEY = process.env.PRIVATE_KEY;
if (!PRIVATE_KEY) {
  console.error("Error: PRIVATE_KEY environment variable is required");
  process.exit(1);
}

const provider = new ethers.JsonRpcProvider(network.rpcUrl);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
const PAYMENT_ADDRESS = wallet.address;

console.log(`Payment receiver: ${PAYMENT_ADDRESS}`);
console.log(`Network: ${network.rpcUrl} (chain ${network.chainId})`);

// ─────────────────────────────────────────────
// x402 payment middleware setup
// ─────────────────────────────────────────────

/**
 * Creates x402 payment requirements for a given price in USDC.
 * @param priceUsdCents Price in US cents (e.g. 1 = $0.01, 100 = $1.00)
 * @param resource      Resource identifier (URL path)
 */
function createPaymentRequirements(
  priceUsdCents: number,
  resource: string
): PaymentRequirements {
  // USDC has 6 decimals: $0.01 = 10000 raw units
  const amount = BigInt(priceUsdCents) * BigInt(10000); // 1 cent = 10000 USDC units

  return {
    scheme: "exact",
    network: `eip155:${network.chainId}`,
    maxAmountRequired: amount.toString(),
    resource,
    description: `Payment of $${(priceUsdCents / 100).toFixed(2)} USDC required`,
    mimeType: "application/json",
    payTo: PAYMENT_ADDRESS,
    maxTimeoutSeconds: 300, // 5 minute payment window
    asset: network.usdcAddress,
    extra: {
      name: "USD Coin",
      version: "2",
    },
  };
}

// ─────────────────────────────────────────────
// Routes — free (no payment required)
// ─────────────────────────────────────────────

app.get("/", (req: Request, res: Response) => {
  res.json({
    message: "x402 Payment Server on Sei",
    network: `Sei ${process.env.USE_TESTNET ? "Testnet" : "Mainnet"} (chain ${network.chainId})`,
    paymentAddress: PAYMENT_ADDRESS,
    routes: {
      free: "GET /",
      paid_1cent: "GET /api/data",
      paid_10cents: "GET /api/premium",
      paid_1dollar: "GET /api/exclusive",
    },
  });
});

app.get("/health", (_req: Request, res: Response) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// ─────────────────────────────────────────────
// Routes — paid ($0.01 per request)
// ─────────────────────────────────────────────

app.get(
  "/api/data",
  paymentMiddleware(
    createPaymentRequirements(1, "/api/data"), // $0.01
    wallet
  ),
  async (req: Request, res: Response) => {
    // Payment verified — serve the paid content
    const blockNumber = await provider.getBlockNumber();
    res.json({
      message: "You've successfully paid for this data!",
      data: {
        seiBlockNumber: blockNumber,
        timestamp: new Date().toISOString(),
        randomNumber: Math.floor(Math.random() * 1000000),
        paymentReceived: true,
      },
    });
  }
);

// ─────────────────────────────────────────────
// Routes — premium ($0.10 per request)
// ─────────────────────────────────────────────

app.get(
  "/api/premium",
  paymentMiddleware(
    createPaymentRequirements(10, "/api/premium"), // $0.10
    wallet
  ),
  async (req: Request, res: Response) => {
    const block = await provider.getBlock("latest");
    res.json({
      message: "Premium endpoint accessed!",
      premium_data: {
        blockNumber: block?.number,
        blockHash: block?.hash,
        blockTimestamp: block?.timestamp,
        gasLimit: block?.gasLimit?.toString(),
        transactions: block?.transactions?.length,
      },
    });
  }
);

// ─────────────────────────────────────────────
// Routes — exclusive ($1.00 per request)
// ─────────────────────────────────────────────

app.get(
  "/api/exclusive",
  paymentMiddleware(
    createPaymentRequirements(100, "/api/exclusive"), // $1.00
    wallet
  ),
  async (req: Request, res: Response) => {
    res.json({
      message: "You've unlocked exclusive content!",
      exclusive: {
        secret: "The SEI blockchain is blazingly fast",
        networkDetails: {
          rpc: network.rpcUrl,
          chainId: network.chainId,
          usdcAddress: network.usdcAddress,
        },
        accessGrantedAt: new Date().toISOString(),
      },
    });
  }
);

// ─────────────────────────────────────────────
// Route — streaming content ($0.05 per request)
// ─────────────────────────────────────────────

app.get(
  "/api/stream",
  paymentMiddleware(
    createPaymentRequirements(5, "/api/stream"), // $0.05
    wallet
  ),
  async (req: Request, res: Response) => {
    res.setHeader("Content-Type", "text/event-stream");
    res.setHeader("Cache-Control", "no-cache");
    res.setHeader("Connection", "keep-alive");

    let count = 0;
    const interval = setInterval(async () => {
      const blockNumber = await provider.getBlockNumber();
      res.write(`data: ${JSON.stringify({ blockNumber, count: ++count })}\n\n`);
      if (count >= 10) {
        clearInterval(interval);
        res.end();
      }
    }, 1000);

    req.on("close", () => clearInterval(interval));
  }
);

// ─────────────────────────────────────────────
// Error handler
// ─────────────────────────────────────────────

app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error("Server error:", err);
  res.status(500).json({ error: "Internal server error" });
});

// ─────────────────────────────────────────────
// Start
// ─────────────────────────────────────────────

app.listen(PORT, () => {
  console.log(`\nx402 Payment Server running on port ${PORT}`);
  console.log(`\nEndpoints:`);
  console.log(`  FREE:    GET http://localhost:${PORT}/`);
  console.log(`  $0.01:   GET http://localhost:${PORT}/api/data`);
  console.log(`  $0.10:   GET http://localhost:${PORT}/api/premium`);
  console.log(`  $1.00:   GET http://localhost:${PORT}/api/exclusive`);
  console.log(`  $0.05:   GET http://localhost:${PORT}/api/stream`);
});

export default app;
