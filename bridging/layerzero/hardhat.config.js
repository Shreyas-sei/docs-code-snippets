require('@nomicfoundation/hardhat-toolbox');
require('dotenv').config();

/** @type {import('hardhat/config').HardhatUserConfig} */
module.exports = {
  solidity: {
    version: '0.8.22',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  networks: {
    // Sei mainnet
    sei: {
      url: 'https://evm-rpc.sei-apis.com',
      chainId: 1329,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },

    // Sei testnet (atlantic-2)
    seiTestnet: {
      url: 'https://evm-rpc-testnet.sei-apis.com',
      chainId: 1328,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },

    // Ethereum Sepolia (for cross-chain testing)
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || 'https://rpc.sepolia.org',
      chainId: 11155111,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
  },

  etherscan: {
    apiKey: {
      sei: process.env.SEITRACE_API_KEY || 'your-api-key',
    },
    customChains: [
      {
        network: 'sei',
        chainId: 1329,
        urls: {
          apiURL: 'https://seitrace.com/api',
          browserURL: 'https://seitrace.com',
        },
      },
    ],
  },
};
