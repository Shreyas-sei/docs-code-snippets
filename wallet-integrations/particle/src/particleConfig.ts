import { AuthCoreContextProvider, PromptSettingType } from '@particle-network/authkit';
import type { ComponentProps } from 'react';

// Sei mainnet chain ID: 1329
// Sei testnet (atlantic-2) chain ID: 1328
export const SEI_CHAIN_ID = 1329;
export const SEI_TESTNET_CHAIN_ID = 1328;

// ─── Particle Auth kit config ─────────────────────────────────────────────────
// Set these values from your Particle dashboard (https://dashboard.particle.network)

export const PARTICLE_PROJECT_ID = import.meta.env.VITE_PARTICLE_PROJECT_ID as string;
export const PARTICLE_CLIENT_KEY = import.meta.env.VITE_PARTICLE_CLIENT_KEY as string;
export const PARTICLE_APP_ID = import.meta.env.VITE_PARTICLE_APP_ID as string;

// ─── AuthCoreContextProvider props ───────────────────────────────────────────

export const particleAuthConfig: ComponentProps<typeof AuthCoreContextProvider>['options'] = {
  projectId: PARTICLE_PROJECT_ID,
  clientKey: PARTICLE_CLIENT_KEY,
  appId: PARTICLE_APP_ID,

  // Embedded wallet display — show within dApp
  erc4337: {
    // Use Biconomy's AA paymaster/bundler on Sei; replace with your preferred bundler URL
    name: 'BICONOMY',
    version: '2.0.0',
  },

  wallet: {
    visible: true,
    customStyle: {
      supportChains: [
        { id: SEI_CHAIN_ID, name: 'Sei' },
        { id: SEI_TESTNET_CHAIN_ID, name: 'Sei Testnet' },
      ],
    },
  },

  // Prompt users to set a payment password on first use
  promptSettingConfig: {
    promptPaymentPasswordSettingWhenSign: PromptSettingType.first,
    promptMasterPasswordSettingWhenLogin: PromptSettingType.first,
  },
};
