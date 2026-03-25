import '@rainbow-me/rainbowkit/styles.css';
import '@sei-js/sei-global-wallet/eip6963';

import { ConnectButton, getDefaultConfig, RainbowKitProvider } from '@rainbow-me/rainbowkit';
import { WagmiProvider } from 'wagmi';
import { sei, seiTestnet } from 'wagmi/chains';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useAccount, useBalance } from 'wagmi';

const config = getDefaultConfig({
  appName: 'My Sei dApp',
  projectId: 'YOUR_WALLETCONNECT_PROJECT_ID',
  chains: [sei, seiTestnet],
  ssr: false
});

const queryClient = new QueryClient();

function AccountInfo() {
  const { address, isConnected, chain } = useAccount();
  const { data: balance } = useBalance({ address });

  if (!isConnected) {
    return <p>Connect your wallet to see account details</p>;
  }

  return (
    <div className="account-info">
      <h3>Account Information</h3>
      <p><strong>Address:</strong> {address}</p>
      <p><strong>Chain:</strong> {chain?.name}</p>
      <p>
        <strong>Balance:</strong> {balance?.formatted} {balance?.symbol}
      </p>
    </div>
  );
}

function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          <div className="app">
            <h1>Sei dApp</h1>
            <ConnectButton />
            <AccountInfo />
          </div>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}

export default App;
