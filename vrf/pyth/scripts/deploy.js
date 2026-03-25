/**
 * deploy.js
 *
 * Deploys the SeiEntropyDemo dice game contract to Sei using Pyth Entropy for VRF.
 *
 * Usage:
 *   PRIVATE_KEY=0x... npx hardhat run scripts/deploy.js --network sei
 *   PRIVATE_KEY=0x... npx hardhat run scripts/deploy.js --network seiTestnet
 *
 * After deployment, fund the contract with SEI to act as house bankroll:
 *   cast send <CONTRACT_ADDRESS> --value 10ether --rpc-url https://evm-rpc.sei-apis.com --private-key $PRIVATE_KEY
 */

const { ethers } = require("hardhat");

// ─────────────────────────────────────────────
// Pyth Entropy contract addresses
// ─────────────────────────────────────────────

const ENTROPY_ADDRESSES = {
  // Sei Mainnet (chain ID 1329)
  1329: "0x98046Bd286715D3B0BC227Dd7a956b83D8978603",
  // Sei Testnet (chain ID 1328)
  1328: "0x98046Bd286715D3B0BC227Dd7a956b83D8978603",
};

async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);

  console.log("=".repeat(60));
  console.log("SeiEntropyDemo Deployment");
  console.log("=".repeat(60));
  console.log(`Network:    ${network.name} (chain ID: ${chainId})`);
  console.log(`Deployer:   ${deployer.address}`);
  console.log(
    `Balance:    ${ethers.formatEther(await ethers.provider.getBalance(deployer.address))} SEI`
  );

  // Resolve entropy contract address
  const entropyAddress = ENTROPY_ADDRESSES[chainId];
  if (!entropyAddress) {
    throw new Error(
      `No Pyth Entropy address configured for chain ID ${chainId}. ` +
        `Supported chains: ${Object.keys(ENTROPY_ADDRESSES).join(", ")}`
    );
  }
  console.log(`Pyth Entropy: ${entropyAddress}`);

  // ── Deploy ──────────────────────────────────────────────────────────
  console.log("\nDeploying SeiEntropyDemo...");
  const SeiEntropyDemo = await ethers.getContractFactory("SeiEntropyDemo");

  const contract = await SeiEntropyDemo.deploy(entropyAddress, {
    gasLimit: 3_000_000,
  });

  await contract.waitForDeployment();
  const contractAddress = await contract.getAddress();

  console.log(`\nSeiEntropyDemo deployed to: ${contractAddress}`);

  // ── Verify deployment ───────────────────────────────────────────────
  const fee = await contract.getRequestFee();
  console.log(`Current Pyth Entropy fee: ${ethers.formatEther(fee)} SEI`);

  // ── Fund the house bankroll ─────────────────────────────────────────
  const houseDeposit = ethers.parseEther("1.0"); // 1 SEI initial bankroll
  const balance = await ethers.provider.getBalance(deployer.address);

  if (balance > houseDeposit + ethers.parseEther("0.1")) {
    console.log(`\nFunding house bankroll with 1 SEI...`);
    const fundTx = await deployer.sendTransaction({
      to: contractAddress,
      value: houseDeposit,
    });
    await fundTx.wait();
    console.log(`House funded. Contract balance: ${ethers.formatEther(
      await ethers.provider.getBalance(contractAddress)
    )} SEI`);
  } else {
    console.log("\nInsufficient balance to fund house bankroll — fund manually:");
    console.log(
      `  cast send ${contractAddress} --value 1ether --rpc-url <RPC_URL> --private-key $PRIVATE_KEY`
    );
  }

  // ── Print summary ────────────────────────────────────────────────────
  console.log("\n" + "=".repeat(60));
  console.log("Deployment Summary");
  console.log("=".repeat(60));
  console.log(`Contract Address:  ${contractAddress}`);
  console.log(`Entropy Address:   ${entropyAddress}`);
  console.log(`Chain ID:          ${chainId}`);
  console.log("\nTo play a game:");
  console.log(`  const contract = await ethers.getContractAt("SeiEntropyDemo", "${contractAddress}");`);
  console.log(`  const fee = await contract.getRequestFee();`);
  console.log(`  const tx = await contract.playDiceGame(3, { value: fee });  // bet on 3`);
  console.log("\nSave this address to .env:");
  console.log(`  SEI_ENTROPY_DEMO=${contractAddress}`);

  return contractAddress;
}

main()
  .then((address) => {
    console.log(`\nDone. Contract: ${address}`);
    process.exit(0);
  })
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
