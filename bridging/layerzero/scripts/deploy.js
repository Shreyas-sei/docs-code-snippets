const { ethers } = require('hardhat');

// ─── LayerZero V2 endpoint addresses ─────────────────────────────────────────
// Full list: https://docs.layerzero.network/v2/deployments/deployed-contracts

const LZ_ENDPOINTS = {
  sei: '0x1a44076050125825900e736c501f859c50fE728c',       // Sei mainnet  (EID 30280)
  seiTestnet: '0x6EDCE65403992e310A62460808c4b910D972f10f', // Sei testnet  (EID 40280)
  sepolia: '0x6EDCE65403992e310A62460808c4b910D972f10f',    // ETH Sepolia  (EID 40161)
};

async function main() {
  const network = hre.network.name;
  console.log(`\nDeploying MyOFT to ${network}…`);

  // ── Signer ──────────────────────────────────────────────────────────────────
  const [deployer] = await ethers.getSigners();
  console.log(`Deployer: ${deployer.address}`);
  console.log(`Balance:  ${ethers.formatEther(await deployer.provider.getBalance(deployer.address))} ETH/SEI\n`);

  // ── Endpoint ─────────────────────────────────────────────────────────────────
  const lzEndpoint = LZ_ENDPOINTS[network];
  if (!lzEndpoint) {
    throw new Error(`No LayerZero endpoint configured for network: ${network}`);
  }

  // ── Deploy ────────────────────────────────────────────────────────────────────
  const MyOFT = await ethers.getContractFactory('MyOFT');
  const oft = await MyOFT.deploy(
    'My OFT Token',    // _name
    'MOFT',            // _symbol
    lzEndpoint,        // _lzEndpoint
    deployer.address   // _delegate (owner)
  );

  await oft.waitForDeployment();
  const address = await oft.getAddress();
  console.log(`MyOFT deployed at: ${address}`);

  // ── Mint initial supply (optional) ───────────────────────────────────────────
  const INITIAL_SUPPLY = ethers.parseEther('1000000'); // 1,000,000 tokens
  console.log(`\nMinting ${ethers.formatEther(INITIAL_SUPPLY)} MOFT to deployer…`);
  const mintTx = await oft.mint(deployer.address, INITIAL_SUPPLY);
  await mintTx.wait();
  console.log('Mint complete.');

  // ── Next steps ────────────────────────────────────────────────────────────────
  console.log(`
Next steps:
  1. Deploy MyOFT on the destination chain (e.g. Sepolia)
  2. Call setPeer() on both contracts to link them:
     await oft.setPeer(<destEid>, ethers.zeroPadValue(<destAddress>, 32))
  3. Send tokens cross-chain:
     See https://docs.layerzero.network/v2/developers/evm/oft/quickstart#send-tokens
`);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
