import '@rainbow-me/rainbowkit/styles.css';
import '@sei-js/sei-global-wallet/eip6963';

import { ConnectButton, getDefaultConfig, RainbowKitProvider } from '@rainbow-me/rainbowkit';
import { WagmiProvider } from 'wagmi';
import { sei, seiTestnet } from 'wagmi/chains';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ContractInteraction } from './ContractInteraction';

const config = getDefaultConfig({
  appName: 'Sei Read/Write Contract',
  projectId: 'YOUR_WALLETCONNECT_PROJECT_ID',
  chains: [sei, seiTestnet],
  ssr: false,
});

const queryClient = new QueryClient();

function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          <div className="app">
            <h1>Read &amp; Write Contract on Sei</h1>
            <ConnectButton />
            <ContractInteraction />
          </div>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}

export default App;
