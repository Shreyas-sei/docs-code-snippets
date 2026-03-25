/**
 * setup-ethers.js
 *
 * Initializes ethers.js providers and signers for interacting with
 * Sei EVM precompiles from both browser and Node.js environments.
 *
 * Install dependencies:
 *   npm install ethers @sei-js/evm
 */

import { ethers } from 'ethers';

// ─── Browser (MetaMask / injected wallet) ────────────────────────────────────

/**
 * Returns a signer backed by the browser's injected wallet (e.g. MetaMask).
 * Call this inside an async function triggered by a user action.
 */
export async function getBrowserSigner() {
  if (!window.ethereum) {
    throw new Error('No injected wallet found. Please install MetaMask.');
  }

  const provider = new ethers.BrowserProvider(window.ethereum);
  await provider.send('eth_requestAccounts', []);
  const signer = await provider.getSigner();
  return { provider, signer };
}

// ─── Node.js (private key) ───────────────────────────────────────────────────

const SEI_MAINNET_RPC = 'https://evm-rpc.sei-apis.com';
const SEI_TESTNET_RPC = 'https://evm-rpc-testnet.sei-apis.com';

/**
 * Returns a signer for Node.js scripts.
 * Reads PRIVATE_KEY from the environment.
 *
 * Usage:
 *   PRIVATE_KEY=0x... node your-script.js
 */
export function getNodeSigner(rpcUrl = SEI_TESTNET_RPC) {
  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey) {
    throw new Error('PRIVATE_KEY environment variable is not set.');
  }

  const provider = new ethers.JsonRpcProvider(rpcUrl);
  const signer = new ethers.Wallet(privateKey, provider);
  return { provider, signer };
}

// ─── Multi-precompile demo ────────────────────────────────────────────────────

/**
 * Complete working demo that connects to both the staking and governance
 * precompiles in a single Node.js script.
 *
 * Run:
 *   PRIVATE_KEY=your_key node setup-ethers.js
 */
import {
  STAKING_PRECOMPILE_ABI,
  STAKING_PRECOMPILE_ADDRESS,
  GOVERNANCE_PRECOMPILE_ABI,
  GOVERNANCE_PRECOMPILE_ADDRESS,
} from '@sei-js/evm';

async function main() {
  const { signer } = getNodeSigner(SEI_MAINNET_RPC);

  const staking = new ethers.Contract(
    STAKING_PRECOMPILE_ADDRESS,
    STAKING_PRECOMPILE_ABI,
    signer
  );

  const governance = new ethers.Contract(
    GOVERNANCE_PRECOMPILE_ADDRESS,
    GOVERNANCE_PRECOMPILE_ABI,
    signer
  );

  // Query current delegation (replace with a real validator address)
  const validatorAddress = 'seivaloper1...';
  try {
    const delegation = await staking.delegation(signer.address, validatorAddress);
    console.log('Current delegation:', delegation.balance.amount.toString());
  } catch (err) {
    console.log('No existing delegation found for this validator.');
  }

  // Cast a governance vote (replace with a real proposal ID)
  const tx = await governance.vote(1, 1 /* YES */);
  await tx.wait();
  console.log('Vote cast successfully');
}

main().catch(console.error);
