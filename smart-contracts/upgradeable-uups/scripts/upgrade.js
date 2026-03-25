const { ethers, upgrades } = require("hardhat");

// Set the proxy address from the initial deploy script output
const PROXY_ADDRESS = process.env.PROXY_ADDRESS;

async function main() {
  if (!PROXY_ADDRESS) {
    throw new Error(
      "Please set PROXY_ADDRESS env variable to the proxy contract address.\n" +
      "Example: PROXY_ADDRESS=0x... npx hardhat run scripts/upgrade.js --network sei"
    );
  }

  const [deployer] = await ethers.getSigners();

  console.log("Upgrading proxy to MyTokenV2...");
  console.log("Deployer:", deployer.address);
  console.log("Proxy address:", PROXY_ADDRESS);

  // Confirm current version before upgrade
  const MyTokenV1 = await ethers.getContractFactory("MyTokenV1");
  const tokenV1 = MyTokenV1.attach(PROXY_ADDRESS);
  console.log("Current version:", await tokenV1.version());

  // Deploy V2 implementation and upgrade the proxy
  const MyTokenV2 = await ethers.getContractFactory("MyTokenV2");

  console.log("\nDeploying V2 implementation and upgrading proxy...");
  const tokenV2 = await upgrades.upgradeProxy(PROXY_ADDRESS, MyTokenV2, {
    kind: "uups",
    // Call initializeV2 as part of the upgrade
    call: {
      fn: "initializeV2",
      args: [
        ethers.parseEther("10000000"), // 10 million max supply cap
        ethers.parseEther("100000"),   // 100k max per-tx transfer limit
      ],
    },
  });

  await tokenV2.waitForDeployment();

  const newImplementationAddress = await upgrades.erc1967.getImplementationAddress(PROXY_ADDRESS);

  console.log("\nUpgrade Summary:");
  console.log("  Proxy address (unchanged):", PROXY_ADDRESS);
  console.log("  New implementation (V2):", newImplementationAddress);
  console.log("  Version:", await tokenV2.version());
  console.log(
    "  Total Supply (preserved):",
    ethers.formatEther(await tokenV2.totalSupply()),
    "MTK"
  );
  console.log(
    "  Max Supply Cap:",
    ethers.formatEther(await tokenV2.maxSupplyCap()),
    "MTK"
  );
  console.log(
    "  Transfer Limit:",
    ethers.formatEther(await tokenV2.transferLimit()),
    "MTK"
  );

  console.log("\nUpgrade successful! The proxy address remains the same for users.");
  console.log(`https://seitrace.com/address/${PROXY_ADDRESS}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
