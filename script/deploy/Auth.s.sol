// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {console} from "@forge-std/console.sol";
import {Script} from "@forge-std/Script.sol";
import {Auth} from "src/user/Auth.sol";

/*
How to use:
forge script script/deploy/Auth.s.sol:DeployAuth \
    -vvvv \
    --rpc-url $ARBITRUM_RPC_URL \
    --broadcast
Make sure to set the PRIVATE_KEY environment variable in your .env file.
*/

contract DeployAuth is Script {
    function setUp() public {
        // No setup necessary for this script
    }

    function run() public {
        // Load the private key from the environment variables and store it as a uint256
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        // Start broadcasting transactions from the deployer's private key
        vm.startBroadcast(privateKey);

        // Deploy the Auth contract
        Auth auth = new Auth();

        console.log("Auth contract deployed at:", address(auth));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
