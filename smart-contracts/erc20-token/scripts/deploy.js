const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying MyToken with account:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "SEI");

  // Token parameters
  const name = "MyToken";
  const symbol = "MTK";
  const decimals = 18;
  const initialSupply = 1_000_000; // 1 million tokens

  const MyToken = await ethers.getContractFactory("MyToken");
  const token = await MyToken.deploy(
    name,
    symbol,
    decimals,
    initialSupply,
    deployer.address
  );

  await token.waitForDeployment();

  const address = await token.getAddress();
  console.log("MyToken deployed to:", address);
  console.log("Name:", await token.name());
  console.log("Symbol:", await token.symbol());
  console.log("Decimals:", await token.decimals());
  console.log(
    "Total Supply:",
    ethers.formatUnits(await token.totalSupply(), decimals),
    symbol
  );

  console.log("\nVerify on Seitrace:");
  console.log(`https://seitrace.com/address/${address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
