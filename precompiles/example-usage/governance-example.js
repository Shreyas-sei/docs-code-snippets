/**
 * governance-example.js
 *
 * Demonstrates casting votes and submitting proposals using the
 * Sei governance precompile via ethers.js.
 *
 * Precompile address: 0x0000000000000000000000000000000000001006
 *
 * Install:
 *   npm install ethers @sei-js/evm
 *
 * Run:
 *   PRIVATE_KEY=your_key node governance-example.js
 */

import { ethers } from 'ethers';
import {
  GOVERNANCE_PRECOMPILE_ABI,
  GOVERNANCE_PRECOMPILE_ADDRESS,
} from '@sei-js/evm';

// ─── Vote option constants ────────────────────────────────────────────────────
// These map to the Cosmos SDK VoteOption enum.
const VOTE_OPTION = {
  YES: 1,
  ABSTAIN: 2,
  NO: 3,
  NO_WITH_VETO: 4,
};

// ─── Provider & signer setup ─────────────────────────────────────────────────

const provider = new ethers.JsonRpcProvider('https://evm-rpc-testnet.sei-apis.com');
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

const governance = new ethers.Contract(
  GOVERNANCE_PRECOMPILE_ADDRESS,
  GOVERNANCE_PRECOMPILE_ABI,
  signer
);

// ─── Vote ─────────────────────────────────────────────────────────────────────

/**
 * Cast a vote on an active governance proposal.
 *
 * @param {number} proposalId  - On-chain proposal ID
 * @param {number} voteOption  - One of the VOTE_OPTION values above
 */
async function vote(proposalId, voteOption) {
  try {
    const tx = await governance.vote(proposalId, voteOption, {
      gasLimit: 200_000,
    });
    await tx.wait();
    console.log(`Vote cast successfully on proposal #${proposalId}`);
  } catch (error) {
    console.error('Vote failed:', error.message);
    throw error;
  }
}

// ─── Submit proposal ─────────────────────────────────────────────────────────

/**
 * Submit a text governance proposal with an initial deposit.
 *
 * @param {object} proposalContent - Object describing the proposal
 * @param {bigint} depositAmount   - Initial deposit in wei (18 decimals)
 */
async function submitProposal(proposalContent, depositAmount) {
  const proposalJSON = JSON.stringify(proposalContent);

  const tx = await governance.submitProposal(proposalJSON, {
    value: depositAmount,
    gasLimit: 500_000,
  });
  const receipt = await tx.wait();
  console.log('Proposal submitted:', receipt.hash);
  return receipt;
}

// ─── Batch operations ────────────────────────────────────────────────────────

/**
 * Vote YES on multiple proposals sequentially (write operations cannot be
 * parallelised with a single signer due to nonce management).
 *
 * @param {number[]} proposalIds - Array of proposal IDs
 */
async function batchVoteYes(proposalIds) {
  for (const proposalId of proposalIds) {
    try {
      await vote(proposalId, VOTE_OPTION.YES);
    } catch (error) {
      console.error(`Failed to vote on proposal #${proposalId}:`, error.message);
    }
  }
}

// ─── Gas estimation example ───────────────────────────────────────────────────

/**
 * Estimate and log gas for a vote transaction before sending.
 */
async function estimateVoteGas(proposalId, voteOption) {
  const gas = await governance.vote.estimateGas(proposalId, voteOption);
  console.log(`Estimated gas for vote: ${gas.toString()}`);
  return gas;
}

// ─── Main demo ────────────────────────────────────────────────────────────────

async function main() {
  const proposalId = 1; // replace with an active proposal ID

  console.log('\n--- Estimating gas ---');
  await estimateVoteGas(proposalId, VOTE_OPTION.YES);

  console.log('\n--- Voting YES on proposal ---');
  await vote(proposalId, VOTE_OPTION.YES);

  console.log('\n--- Voting on multiple proposals ---');
  await batchVoteYes([1, 2, 3]);
}

main().catch(console.error);
