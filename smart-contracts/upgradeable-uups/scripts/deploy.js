const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying MyTokenV1 (UUPS Proxy) with account:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "SEI");

  const MyTokenV1 = await ethers.getContractFactory("MyTokenV1");

  // Deploy the UUPS proxy with V1 implementation
  const token = await upgrades.deployProxy(
    MyTokenV1,
    ["MyToken", "MTK", deployer.address],
    {
      initializer: "initialize",
      kind: "uups",
    }
  );

  await token.waitForDeployment();

  const proxyAddress = await token.getAddress();
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);

  console.log("\nDeployment Summary:");
  console.log("  Proxy address:", proxyAddress);
  console.log("  Implementation (V1):", implementationAddress);
  console.log("  Version:", await token.version());
  console.log(
    "  Total Supply:",
    ethers.formatEther(await token.totalSupply()),
    "MTK"
  );

  console.log("\nSave this proxy address — it never changes after upgrades.");
  console.log(`https://seitrace.com/address/${proxyAddress}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
