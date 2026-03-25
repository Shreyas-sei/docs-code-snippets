import '@rainbow-me/rainbowkit/styles.css';
import '@sei-js/sei-global-wallet/eip6963';

import { ConnectButton, getDefaultConfig, RainbowKitProvider } from '@rainbow-me/rainbowkit';
import { WagmiProvider } from 'wagmi';
import { sei, seiTestnet } from 'wagmi/chains';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { SwapComponent } from './SwapComponent';

const config = getDefaultConfig({
  appName: 'Sei In-App Swap',
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
            <h1>In-App Swaps on Sei</h1>
            <ConnectButton />
            <SwapComponent />
          </div>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}

export default App;
