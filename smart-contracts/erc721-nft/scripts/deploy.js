const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying MyNFT with account:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "SEI");

  // NFT collection parameters
  const name = "MyNFT Collection";
  const symbol = "MNFT";
  const maxSupply = 10_000;
  const mintPrice = ethers.parseEther("0.01"); // 0.01 SEI per mint
  const baseURI = "https://api.example.com/metadata/";

  const MyNFT = await ethers.getContractFactory("MyNFT");
  const nft = await MyNFT.deploy(
    name,
    symbol,
    maxSupply,
    mintPrice,
    baseURI,
    deployer.address
  );

  await nft.waitForDeployment();

  const address = await nft.getAddress();
  console.log("MyNFT deployed to:", address);
  console.log("Name:", await nft.name());
  console.log("Symbol:", await nft.symbol());
  console.log("Max Supply:", await nft.maxSupply());
  console.log("Mint Price:", ethers.formatEther(await nft.mintPrice()), "SEI");

  console.log("\nVerify on Seitrace:");
  console.log(`https://seitrace.com/address/${address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
