// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {zip000 as zip} from "@proposals/zips/zip000.sol";
import {Script} from "@forge-std/Script.sol";
import {Addresses} from "@proposals/Addresses.sol";

/*
How to use:
forge script script/deploy/DeployProposal.s.sol:DeployProposal \
    -vvvv \
    --rpc-url $ETH_RPC_URL \
    --broadcast
Remove --broadcast if you want to try locally first, without paying any gas.
*/

contract DeployProposal is Script, zip {
    uint256 public privateKey;
    bool public doDeploy;
    bool public doAfterdeploy;
    bool public doValidate;
    bool public doTeardown;

    function setUp() public {
        // Default behavior: do debug prints
        DEBUG = vm.envOr("DEBUG", true);
        privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        // Default behavior: do deploy
        doDeploy = vm.envOr("DO_DEPLOY", true);
        // Default behavior: do after-deploy
        doAfterdeploy = vm.envOr("DO_AFTERDEPLOY", true);
        // Default behavior: do validate
        doValidate = vm.envOr("DO_VALIDATE", true);
        // Default behavior: don't do teardown
        doTeardown = vm.envOr("DO_TEARDOWN", false);
    }

    function run() public {
        Addresses addresses = new Addresses();
        addresses.resetRecordingAddresses();

        /// Run the deploy OnChain deployment workflow
        deployOnChain(addresses, privateKey);

        (string[] memory recordedNames, address[] memory recordedAddresses) = addresses.getRecordedAddresses();
        for (uint256 i = 0; i < recordedNames.length; i++) {
            // solhint-disable-next-line
            console.log("Deployed", recordedAddresses[i], recordedNames[i]);
        }
    }
}
