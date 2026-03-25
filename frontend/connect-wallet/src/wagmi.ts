import '@sei-js/sei-global-wallet/eip6963';

import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { sei, seiTestnet } from 'wagmi/chains';

export const config = getDefaultConfig({
  appName: 'My Sei dApp',
  projectId: 'YOUR_WALLETCONNECT_PROJECT_ID',
  chains: [sei, seiTestnet],
  ssr: false
});
