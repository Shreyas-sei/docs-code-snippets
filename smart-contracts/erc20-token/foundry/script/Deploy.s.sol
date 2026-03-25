// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";

contract DeployMyToken is Script {
    // Token configuration
    string constant NAME = "MyToken";
    string constant SYMBOL = "MTK";
    uint8 constant DECIMALS = 18;
    uint256 constant INITIAL_SUPPLY = 1_000_000; // 1 million tokens

    function run() external returns (MyToken token) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying MyToken...");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        token = new MyToken(
            NAME,
            SYMBOL,
            DECIMALS,
            INITIAL_SUPPLY,
            deployer
        );

        vm.stopBroadcast();

        console.log("MyToken deployed to:", address(token));
        console.log("Name:", token.name());
        console.log("Symbol:", token.symbol());
        console.log("Total Supply:", token.totalSupply());
    }
}
