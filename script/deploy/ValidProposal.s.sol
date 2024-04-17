// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {zip004 as zip} from "@proposals/zips/zip004.sol";
import {Script} from "@forge-std/Script.sol";
import {Addresses} from "@proposals/Addresses.sol";
import {TimelockProposal} from "@proposals/proposalTypes/TimelockProposal.sol";

/*
How to use:
forge script script/deploy/ValidProposal.s.sol:ValidProposal \
    -vvvv \
    --rpc-url $ETH_RPC_URL \
    --broadcast
Remove --broadcast if you want to try locally first, without paying any gas.
*/

contract ValidProposal is Script {
    TimelockProposal timeLock;

    function setUp() public {
        // Default behavior: do debug prints
        bool debug = vm.envOr("DEBUG", true);

        timeLock = new zip();
        timeLock.setDebug(debug);
    }

    function run() public {
        /// Run the deploy OnChain workflow
        timeLock.run();
    }
}
