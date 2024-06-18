// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {console} from "@forge-std/console.sol";
import {zip020 as zip} from "proposals/zips/zip020.sol";
import {Script} from "@forge-std/Script.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {TimelockProposal} from "@forge-proposal-simulator/src/proposals/TimelockProposal.sol";

/*
How to use:
forge script script/deploy/DeployProposal.s.sol:DeployProposal \
    -vvvv \
    --rpc-url $ETH_RPC_URL \
    --broadcast
Remove --broadcast if you want to try locally first, without paying any gas.
*/

contract DeployProposal is Script {
    TimelockProposal newProposal;
    Addresses addresses;
    
    function setUp() public {
        string memory environment = vm.envOr("ENVIRONMENT", string("localnet"));
        string memory addressPath = string(abi.encodePacked("proposals/Addresses/", environment, ".json"));
        addresses = new Addresses(addressPath);

        newProposal = new zip();
    }

    function run() public {
        /// Run the proposal workflow
        newProposal.run();
    }
}
