/**
 * updateAndRead.js
 *
 * Demonstrates the full Pyth price feed workflow on Sei EVM:
 *   1. Fetch a fresh price update VAA from the Pyth Hermes API
 *   2. Submit the update on-chain
 *   3. Read the updated price from the PythPriceFeed contract
 *
 * Usage:
 *   PRIVATE_KEY=0x... npx hardhat run scripts/updateAndRead.js --network sei
 *
 * Environment variables:
 *   PRIVATE_KEY            Deployer / caller private key
 *   PYTH_CONTRACT          Address of the deployed PythPriceFeed contract (optional if deploying fresh)
 */

const { ethers } = require("hardhat");
const axios = require("axios");

// ─────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────

// Pyth contract address — same on Sei mainnet and testnet
const PYTH_ADDRESS = "0xA2aa501b19aff244D90cc15a4Cf739D2725B5729";

// Price feed IDs (bytes32) — from https://pyth.network/developers/price-feed-ids
const PRICE_FEED_IDS = {
  SEI_USD: "0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace",
  ETH_USD: "0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace",
  BTC_USD: "0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43",
};

// Hermes API endpoint for price update VAAs
const HERMES_API = "https://hermes.pyth.network/api/latest_vaas";

// Maximum acceptable age for a price in seconds
const MAX_AGE_SECONDS = 60;

// ─────────────────────────────────────────────
// Helper: fetch price update data from Hermes
// ─────────────────────────────────────────────

async function fetchPriceUpdateData(feedIds) {
  console.log("Fetching price update VAAs from Pyth Hermes API...");
  const params = new URLSearchParams();
  feedIds.forEach((id) => params.append("ids[]", id));

  const response = await axios.get(`${HERMES_API}?${params.toString()}`);
  // Hermes returns base64-encoded VAAs; convert to hex bytes for on-chain submission
  const updateData = response.data.map((vaa) => {
    const buf = Buffer.from(vaa, "base64");
    return "0x" + buf.toString("hex");
  });
  console.log(`Fetched ${updateData.length} VAA(s)`);
  return updateData;
}

// ─────────────────────────────────────────────
// Helper: format a raw Pyth price
// ─────────────────────────────────────────────

function formatPythPrice(price, conf, expo, publishTime) {
  const scalar = Math.pow(10, Math.abs(expo));
  const priceUsd = Number(price) / scalar;
  const confUsd = Number(conf) / scalar;
  const date = new Date(Number(publishTime) * 1000).toISOString();
  return { priceUsd, confUsd, publishTime: date };
}

// ─────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────

async function main() {
  const [signer] = await ethers.getSigners();
  console.log(`Using account: ${signer.address}`);
  console.log(`Balance: ${ethers.formatEther(await ethers.provider.getBalance(signer.address))} SEI`);

  // ── Step 1: Deploy PythPriceFeed (or attach to existing) ──────────────
  let contract;
  const contractAddress = process.env.PYTH_CONTRACT;

  const feedIdArray = Object.values(PRICE_FEED_IDS);

  if (contractAddress) {
    console.log(`\nAttaching to existing PythPriceFeed at ${contractAddress}`);
    const PythPriceFeed = await ethers.getContractFactory("PythPriceFeed");
    contract = PythPriceFeed.attach(contractAddress);
  } else {
    console.log("\nDeploying PythPriceFeed...");
    const PythPriceFeed = await ethers.getContractFactory("PythPriceFeed");
    contract = await PythPriceFeed.deploy(PYTH_ADDRESS, feedIdArray);
    await contract.waitForDeployment();
    console.log(`PythPriceFeed deployed to: ${await contract.getAddress()}`);
  }

  // ── Step 2: Fetch fresh VAAs from Hermes ──────────────────────────────
  const updateData = await fetchPriceUpdateData(feedIdArray);

  // ── Step 3: Get the required update fee ───────────────────────────────
  const fee = await contract.getUpdateFee(updateData);
  console.log(`\nRequired update fee: ${ethers.formatEther(fee)} SEI`);

  // ── Step 4: Submit the price update on-chain ──────────────────────────
  console.log("Submitting price update transaction...");
  const tx = await contract.updatePriceFeeds(updateData, { value: fee });
  const receipt = await tx.wait();
  console.log(`Price update confirmed in block ${receipt.blockNumber} (tx: ${receipt.hash})`);

  // ── Step 5: Read updated prices ───────────────────────────────────────
  console.log("\n── Updated Prices ──────────────────────────────────────────");

  for (const [name, feedId] of Object.entries(PRICE_FEED_IDS)) {
    try {
      const [price, conf, expo, publishTime] = await contract.getPriceNoOlderThan(
        feedId,
        MAX_AGE_SECONDS
      );
      const formatted = formatPythPrice(price, conf, expo, publishTime);
      console.log(
        `${name}: $${formatted.priceUsd.toFixed(4)} ± $${formatted.confUsd.toFixed(4)} (published: ${formatted.publishTime})`
      );
    } catch (err) {
      console.log(`${name}: Failed to read — ${err.message}`);
    }
  }

  // ── Step 6: Demonstrate atomic updateAndGetPrice ──────────────────────
  console.log("\n── Atomic updateAndGetPrice (SEI/USD) ──────────────────────");
  const freshVaas = await fetchPriceUpdateData([PRICE_FEED_IDS.SEI_USD]);
  const freshFee = await contract.getUpdateFee(freshVaas);

  const [atomicPrice, atomicConf, atomicExpo, atomicPublishTime] =
    await contract.updateAndGetPrice.staticCall(
      PRICE_FEED_IDS.SEI_USD,
      freshVaas,
      MAX_AGE_SECONDS,
      { value: freshFee }
    );
  const atomicFormatted = formatPythPrice(atomicPrice, atomicConf, atomicExpo, atomicPublishTime);
  console.log(
    `SEI/USD (atomic): $${atomicFormatted.priceUsd.toFixed(6)} ± $${atomicFormatted.confUsd.toFixed(6)}`
  );

  // ── Step 7: Get price as uint256 scaled to 18 decimals ─────────────────
  const price18 = await contract.getPriceAsUint256(PRICE_FEED_IDS.SEI_USD, MAX_AGE_SECONDS);
  console.log(`\nSEI/USD (18 decimals): ${ethers.formatEther(price18)} USD`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
