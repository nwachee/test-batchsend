// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MockToken} from "../src/MockToken.sol";
import {BatchSend} from "../src/BatchSend.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy BatchSend
        BatchSend batchSend = new BatchSend();
        console.log("BatchSend deployed to:", address(batchSend));

        // Deploy MockToken
        MockToken token = new MockToken();
        console.log("MockToken deployed to:", address(token));

        vm.stopBroadcast();

        console.log("\nAdd these to your constants file:");
        console.log("MOCK_TOKEN_ADDRESS:", address(token));
        console.log("BATCHSEND_ADDRESS:", address(batchSend));
    }
}
