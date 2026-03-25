import { useState } from 'react';
import {
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
  useAccount,
} from 'wagmi';
import { parseAbi } from 'viem';

// Simple Storage contract ABI — matches contracts/Storage.sol
const STORAGE_ABI = parseAbi([
  'function store(uint256 num) public',
  'function retrieve() public view returns (uint256)',
]);

// Replace with your deployed Storage contract address on Sei
const CONTRACT_ADDRESS = '0xYourDeployedContractAddress' as `0x${string}`;

export function ContractInteraction() {
  const { isConnected } = useAccount();
  const [inputValue, setInputValue] = useState('');

  // ─── Read ───────────────────────────────────────────────────────────────────

  const {
    data: storedValue,
    isLoading: isReading,
    refetch,
  } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: STORAGE_ABI,
    functionName: 'retrieve',
  });

  // ─── Write ──────────────────────────────────────────────────────────────────

  const { writeContract, data: txHash, isPending: isWritePending } = useWriteContract();

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash: txHash,
  });

  const handleStore = () => {
    if (!inputValue) return;
    writeContract({
      address: CONTRACT_ADDRESS,
      abi: STORAGE_ABI,
      functionName: 'store',
      args: [BigInt(inputValue)],
    });
  };

  if (!isConnected) {
    return <p>Please connect your wallet to interact with the contract.</p>;
  }

  return (
    <div className="contract-interaction">
      <h2>Storage Contract</h2>

      {/* Read */}
      <section>
        <h3>Read stored value</h3>
        {isReading ? (
          <p>Loading…</p>
        ) : (
          <p>
            Stored value: <strong>{storedValue?.toString() ?? '—'}</strong>
          </p>
        )}
        <button onClick={() => refetch()}>Refresh</button>
      </section>

      {/* Write */}
      <section>
        <h3>Store a new value</h3>
        <input
          type="number"
          placeholder="Enter a number"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
        />
        <button onClick={handleStore} disabled={isWritePending || isConfirming}>
          {isWritePending ? 'Confirm in wallet…' : isConfirming ? 'Confirming tx…' : 'Store'}
        </button>

        {txHash && (
          <p>
            Transaction hash:{' '}
            <a
              href={`https://seitrace.com/tx/${txHash}`}
              target="_blank"
              rel="noreferrer"
            >
              {txHash}
            </a>
          </p>
        )}
        {isConfirmed && <p>Value stored successfully!</p>}
      </section>
    </div>
  );
}
