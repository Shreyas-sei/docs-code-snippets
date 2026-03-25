// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MyNFT} from "../src/MyNFT.sol";

contract DeployMyNFT is Script {
    string constant NAME = "MyNFT Collection";
    string constant SYMBOL = "MNFT";
    uint256 constant MAX_SUPPLY = 10_000;
    uint256 constant MINT_PRICE = 0.01 ether; // 0.01 SEI
    string constant BASE_URI = "https://api.example.com/metadata/";

    function run() external returns (MyNFT nft) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying MyNFT...");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        nft = new MyNFT(
            NAME,
            SYMBOL,
            MAX_SUPPLY,
            MINT_PRICE,
            BASE_URI,
            deployer
        );

        vm.stopBroadcast();

        console.log("MyNFT deployed to:", address(nft));
        console.log("Name:", nft.name());
        console.log("Symbol:", nft.symbol());
        console.log("Max Supply:", nft.maxSupply());
        console.log("Mint Price:", nft.mintPrice());
    }
}
