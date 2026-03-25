import { AuthCoreContextProvider, useConnect, useAuthCore, useEthereum } from '@particle-network/authkit';
import { AAWrapProvider, SmartAccount } from '@particle-network/aa';
import { ethers } from 'ethers';
import { particleAuthConfig, SEI_CHAIN_ID } from './particleConfig';

// ─── Smart Account setup ──────────────────────────────────────────────────────

function useSmartAccount() {
  const { provider } = useEthereum();

  const smartAccount = new SmartAccount(provider, {
    projectId: import.meta.env.VITE_PARTICLE_PROJECT_ID,
    clientKey: import.meta.env.VITE_PARTICLE_CLIENT_KEY,
    appId: import.meta.env.VITE_PARTICLE_APP_ID,
    aaOptions: {
      accountContracts: {
        BICONOMY: [{ chainIds: [SEI_CHAIN_ID], version: '2.0.0' }],
      },
    },
  });

  const wrappedProvider = new ethers.BrowserProvider(
    new AAWrapProvider(smartAccount) as ethers.Eip1193Provider
  );

  return { smartAccount, wrappedProvider };
}

// ─── Wallet Info ──────────────────────────────────────────────────────────────

function WalletInfo() {
  const { userInfo } = useAuthCore();
  const { address } = useEthereum();
  const { smartAccount } = useSmartAccount();
  const [aaAddress, setAaAddress] = React.useState<string | null>(null);
  const [balance, setBalance] = React.useState<string | null>(null);

  React.useEffect(() => {
    if (!address) return;
    smartAccount.getAddress().then((addr: string) => {
      setAaAddress(addr);
    });
  }, [address]);

  React.useEffect(() => {
    if (!aaAddress) return;
    const { wrappedProvider } = useSmartAccount();
    wrappedProvider.getBalance(aaAddress).then((bal: bigint) => {
      setBalance(ethers.formatEther(bal));
    });
  }, [aaAddress]);

  if (!userInfo) return null;

  return (
    <div className="wallet-info">
      <h3>Account</h3>
      <p><strong>Name:</strong> {userInfo.name}</p>
      <p><strong>EOA:</strong> {address}</p>
      <p><strong>Smart Account:</strong> {aaAddress ?? 'Loading…'}</p>
      <p><strong>Balance:</strong> {balance ? `${balance} SEI` : 'Loading…'}</p>
    </div>
  );
}

// ─── Connect ──────────────────────────────────────────────────────────────────

function ConnectSection() {
  const { connect, disconnect } = useConnect();
  const { userInfo } = useAuthCore();

  return (
    <div className="connect-section">
      {!userInfo ? (
        <button
          onClick={() =>
            connect({
              socialType: 'google',
              chain: { id: SEI_CHAIN_ID, name: 'Sei' },
            })
          }
        >
          Sign in with Google
        </button>
      ) : (
        <>
          <WalletInfo />
          <button onClick={() => disconnect()}>Disconnect</button>
        </>
      )}
    </div>
  );
}

// ─── Root ─────────────────────────────────────────────────────────────────────

import React from 'react';

function App() {
  return (
    <AuthCoreContextProvider options={particleAuthConfig}>
      <div className="app">
        <h1>Particle Auth + Smart Account on Sei</h1>
        <ConnectSection />
      </div>
    </AuthCoreContextProvider>
  );
}

export default App;
