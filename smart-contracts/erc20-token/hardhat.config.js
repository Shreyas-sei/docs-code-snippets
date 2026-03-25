require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY || "0x0000000000000000000000000000000000000000000000000000000000000001";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    // Sei Mainnet
    sei: {
      url: "https://evm-rpc.sei-apis.com",
      chainId: 1329,
      accounts: [PRIVATE_KEY],
    },
    // Sei Testnet (Atlantic-2)
    "sei-testnet": {
      url: "https://evm-rpc-testnet.sei-apis.com",
      chainId: 1328,
      accounts: [PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: {
      sei: process.env.SEITRACE_API_KEY || "placeholder",
      "sei-testnet": process.env.SEITRACE_API_KEY || "placeholder",
    },
    customChains: [
      {
        network: "sei",
        chainId: 1329,
        urls: {
          apiURL: "https://seitrace.com/api",
          browserURL: "https://seitrace.com",
        },
      },
      {
        network: "sei-testnet",
        chainId: 1328,
        urls: {
          apiURL: "https://seitrace.com/api?chain=atlantic-2",
          browserURL: "https://testnet.seitrace.com",
        },
      },
    ],
  },
  sourcify: {
    enabled: false,
  },
};
