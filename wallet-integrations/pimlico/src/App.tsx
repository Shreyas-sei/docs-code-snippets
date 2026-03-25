import React, { useState } from 'react';
import { createWalletClient, custom, parseEther } from 'viem';
import { sei } from 'viem/chains';
import { createSeiSmartAccount } from './pimlicoClient';

declare global {
  interface Window {
    ethereum?: {
      request: (args: { method: string; params?: unknown[] }) => Promise<unknown>;
    };
  }
}

// ─── Component ────────────────────────────────────────────────────────────────

function App() {
  const [smartAccountAddress, setSmartAccountAddress] = useState<string | null>(null);
  const [txHash, setTxHash] = useState<string | null>(null);
  const [status, setStatus] = useState('');
  const [toAddress, setToAddress] = useState('');
  const [amount, setAmount] = useState('');

  // ── Connect wallet + deploy/get smart account ────────────────────────────

  const handleConnect = async () => {
    if (!window.ethereum) {
      setStatus('No injected wallet found. Install MetaMask or Sei Global Wallet.');
      return;
    }

    setStatus('Connecting wallet…');
    const [account] = (await window.ethereum.request({
      method: 'eth_requestAccounts',
    })) as `0x${string}`[];

    const ownerWalletClient = createWalletClient({
      account,
      chain: sei,
      transport: custom(window.ethereum),
    });

    setStatus('Deriving smart account address…');
    const { smartAccount } = await createSeiSmartAccount(ownerWalletClient);
    setSmartAccountAddress(smartAccount.address);
    setStatus('Smart account ready.');
  };

  // ── Send a sponsored UserOperation ───────────────────────────────────────

  const handleSendTx = async () => {
    if (!window.ethereum || !toAddress || !amount) return;

    setStatus('Preparing UserOperation…');
    const [account] = (await window.ethereum.request({
      method: 'eth_requestAccounts',
    })) as `0x${string}`[];

    const ownerWalletClient = createWalletClient({
      account,
      chain: sei,
      transport: custom(window.ethereum),
    });

    const { smartAccountClient } = await createSeiSmartAccount(ownerWalletClient);

    setStatus('Sending UserOperation via Pimlico bundler…');
    const hash = await smartAccountClient.sendTransaction({
      to: toAddress as `0x${string}`,
      value: parseEther(amount),
      data: '0x',
    });

    setTxHash(hash);
    setStatus('Transaction sent!');
  };

  return (
    <div className="app">
      <h1>Pimlico ERC-4337 on Sei</h1>

      <section>
        <button onClick={handleConnect}>Connect &amp; Load Smart Account</button>
        {smartAccountAddress && (
          <p>
            <strong>Smart Account:</strong> {smartAccountAddress}
          </p>
        )}
        {status && <p className="status">{status}</p>}
      </section>

      {smartAccountAddress && (
        <section>
          <h2>Send Sponsored Transaction</h2>
          <input
            placeholder="Recipient address (0x…)"
            value={toAddress}
            onChange={(e) => setToAddress(e.target.value)}
          />
          <input
            placeholder="Amount in SEI (e.g. 0.01)"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
          />
          <button onClick={handleSendTx}>Send UserOperation</button>

          {txHash && (
            <p>
              Tx hash:{' '}
              <a
                href={`https://seitrace.com/tx/${txHash}`}
                target="_blank"
                rel="noreferrer"
              >
                {txHash}
              </a>
            </p>
          )}
        </section>
      )}
    </div>
  );
}

export default App;
