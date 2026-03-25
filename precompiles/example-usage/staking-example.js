/**
 * staking-example.js
 *
 * Demonstrates delegating, undelegating, redelegating, and querying
 * staking state using the Sei staking precompile via ethers.js.
 *
 * Precompile address: 0x0000000000000000000000000000000000001005
 *
 * Install:
 *   npm install ethers @sei-js/evm
 *
 * Run:
 *   PRIVATE_KEY=your_key node staking-example.js
 */

import { ethers } from 'ethers';
import { STAKING_PRECOMPILE_ABI, STAKING_PRECOMPILE_ADDRESS } from '@sei-js/evm';

// ─── Provider & signer setup ─────────────────────────────────────────────────

const provider = new ethers.JsonRpcProvider('https://evm-rpc-testnet.sei-apis.com');
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

const staking = new ethers.Contract(STAKING_PRECOMPILE_ADDRESS, STAKING_PRECOMPILE_ABI, signer);

// ─── Amount helpers ───────────────────────────────────────────────────────────

/**
 * Convert SEI (human-readable) to wei for delegate().
 * delegate() accepts msg.value in 18-decimal wei.
 */
function seiToWeiForDelegate(seiAmount) {
  return ethers.parseUnits(Number(seiAmount).toFixed(6), 18);
}

/**
 * Convert SEI to usei (6 decimals) for undelegate() and redelegate().
 */
function seiToUseiForUndelegate(seiAmount) {
  return ethers.parseUnits(Number(seiAmount).toFixed(6), 6);
}

// ─── Delegate ─────────────────────────────────────────────────────────────────

/**
 * Delegate SEI to a validator.
 *
 * @param {string} validatorAddress - Bech32 validator address (seivaloper1...)
 * @param {number} seiAmount        - Amount in SEI
 */
async function delegate(validatorAddress, seiAmount) {
  const amountToDelegate = seiToWeiForDelegate(seiAmount);

  const tx = await staking.delegate(validatorAddress, {
    value: amountToDelegate,
    gasLimit: 300_000,
  });
  const receipt = await tx.wait();
  console.log('Delegation completed:', receipt.hash);
  return receipt;
}

// ─── Undelegate ───────────────────────────────────────────────────────────────

/**
 * Begin undelegating SEI from a validator.
 * Unbonding typically takes 21 days on Sei mainnet.
 *
 * @param {string} validatorAddress - Bech32 validator address
 * @param {number} seiAmount        - Amount in SEI
 */
async function undelegate(validatorAddress, seiAmount) {
  const amountToUndelegate = seiToUseiForUndelegate(seiAmount);

  const tx = await staking.undelegate(validatorAddress, amountToUndelegate);
  const receipt = await tx.wait();
  console.log('Undelegation started:', receipt.hash);
  return receipt;
}

// ─── Redelegate ───────────────────────────────────────────────────────────────

/**
 * Move a delegation from one validator to another (instant, no unbonding).
 *
 * @param {string} srcValidator - Source validator bech32 address
 * @param {string} dstValidator - Destination validator bech32 address
 * @param {number} seiAmount    - Amount in SEI
 */
async function redelegate(srcValidator, dstValidator, seiAmount) {
  const amountToRedelegate = seiToUseiForUndelegate(seiAmount);

  const tx = await staking.redelegate(srcValidator, dstValidator, amountToRedelegate);
  const receipt = await tx.wait();
  console.log('Redelegation completed:', receipt.hash);
  return receipt;
}

// ─── Queries ──────────────────────────────────────────────────────────────────

/**
 * Query delegation details for a delegator + validator pair.
 */
async function queryDelegation(delegatorAddress, validatorAddress) {
  try {
    const delegationInfo = await staking.delegation(delegatorAddress, validatorAddress);
    const amountSei = ethers.formatUnits(delegationInfo.balance.amount, 6);
    console.log('Delegation details:', {
      amount: `${amountSei} SEI`,
      denom: delegationInfo.balance.denom,
      shares: delegationInfo.delegation.shares.toString(),
      delegator: delegationInfo.delegation.delegator_address,
      validator: delegationInfo.delegation.validator_address,
    });
    return delegationInfo;
  } catch (error) {
    if (
      error.message.includes('delegation not found') ||
      error.message.includes('no delegation')
    ) {
      console.log('No delegation found for this validator.');
      return null;
    }
    throw error;
  }
}

/**
 * List all delegations for the current signer.
 */
async function listAllDelegations() {
  const delegator = await signer.getAddress();
  const result = await staking.delegatorDelegations(delegator, '0x');

  for (const del of result.delegations) {
    const amountSei = ethers.formatUnits(del.balance.amount, 6);
    console.log(`  ${del.delegation.validator_address}: ${amountSei} SEI`);
  }
  return result.delegations;
}

/**
 * List all pending unbonding delegations for the current signer.
 */
async function listUnbondingDelegations() {
  const delegator = await signer.getAddress();
  const result = await staking.delegatorUnbondingDelegations(delegator, '0x');

  for (const ud of result.unbondingDelegations) {
    console.log(`Unbonding from validator: ${ud.validatorAddress}`);
    for (const entry of ud.entries) {
      const completionDate = new Date(Number(entry.completionTime) * 1000);
      console.log(`  Amount: ${entry.balance}, Completes: ${completionDate.toISOString()}`);
    }
  }
  return result.unbondingDelegations;
}

/**
 * Query the on-chain staking pool stats.
 */
async function queryPool() {
  const pool = await staking.pool();
  console.log('Staking Pool:', {
    bondedTokens: pool.bondedTokens,
    notBondedTokens: pool.notBondedTokens,
  });
  return pool;
}

// ─── Event listeners ─────────────────────────────────────────────────────────

staking.on('Delegate', (delegator, validator, amount) => {
  console.log(`[Event] ${delegator} delegated ${amount} to ${validator}`);
});

staking.on('Undelegate', (delegator, validator, amount) => {
  console.log(`[Event] ${delegator} undelegated ${amount} from ${validator}`);
});

staking.on('Redelegate', (delegator, srcValidator, dstValidator, amount) => {
  console.log(
    `[Event] ${delegator} redelegated ${amount} from ${srcValidator} to ${dstValidator}`
  );
});

// ─── Main demo ────────────────────────────────────────────────────────────────

async function main() {
  const delegator = await signer.getAddress();
  const validatorAddress = 'seivaloper1xyz...'; // replace with real address

  console.log('\n--- Checking existing delegations ---');
  await listAllDelegations();

  console.log('\n--- Delegating 1 SEI ---');
  await delegate(validatorAddress, 1);

  console.log('\n--- Querying delegation ---');
  await queryDelegation(delegator, validatorAddress);

  console.log('\n--- Undelegating 0.5 SEI ---');
  await undelegate(validatorAddress, 0.5);

  console.log('\n--- Staking pool ---');
  await queryPool();
}

main().catch(console.error);
