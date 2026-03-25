import { createPublicClient, createWalletClient, http } from 'viem';
import { sei } from 'viem/chains';
import { createSmartAccountClient } from 'permissionless';
import { toSimpleSmartAccount } from 'permissionless/accounts';
import { createPimlicoClient } from 'permissionless/clients/pimlico';

// ─── Configuration ────────────────────────────────────────────────────────────

// Pimlico API key from https://dashboard.pimlico.io
export const PIMLICO_API_KEY = import.meta.env.VITE_PIMLICO_API_KEY as string;

// Sei mainnet Pimlico bundler/paymaster endpoint
// Check https://docs.pimlico.io/infra/bundler for the latest Sei endpoint
export const PIMLICO_BUNDLER_URL =
  `https://api.pimlico.io/v2/${sei.id}/rpc?apikey=${PIMLICO_API_KEY}`;

// ─── Public client (Sei RPC) ──────────────────────────────────────────────────

export const publicClient = createPublicClient({
  chain: sei,
  transport: http('https://evm-rpc.sei-apis.com'),
});

// ─── Pimlico bundler + paymaster client ───────────────────────────────────────

export const pimlicoClient = createPimlicoClient({
  transport: http(PIMLICO_BUNDLER_URL),
  entryPoint: {
    address: '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789', // EntryPoint v0.6
    version: '0.6',
  },
});

// ─── Factory: create a Simple Smart Account for a given owner signer ─────────

export async function createSeiSmartAccount(
  ownerWalletClient: ReturnType<typeof createWalletClient>
) {
  const smartAccount = await toSimpleSmartAccount({
    client: publicClient,
    owner: ownerWalletClient,
    // SimpleAccount factory deployed on Sei mainnet
    // Verify at https://docs.pimlico.io/infra/bundler/reference/supported-chains
    factoryAddress: '0x9406Cc6185a346906296840746125a0E44976454',
    entryPoint: {
      address: '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789',
      version: '0.6',
    },
  });

  const smartAccountClient = createSmartAccountClient({
    account: smartAccount,
    chain: sei,
    bundlerTransport: http(PIMLICO_BUNDLER_URL),
    paymaster: pimlicoClient, // sponsor gas via Pimlico verifying paymaster
    userOperation: {
      estimateFeesPerGas: async () => (await pimlicoClient.getUserOperationGasPrice()).fast,
    },
  });

  return { smartAccount, smartAccountClient };
}
