// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {zip001 as zip} from "@proposals/zips/zip001.sol"; // zip001 already loaded for next mainNet deployment
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
    Addresses private addresses;
    uint256 public privateKey;

    bool private DO_DEPLOY;
    bool private DO_AFTER_DEPLOY;
    bool private DO_AFTER_DEPLOY_SETUP;
    bool private DO_BUILD;
    bool private DO_RUN;
    bool private DO_TEARDOWN;
    bool private DO_VALIDATE;
    bool private DO_PRINT;
    uint256 private ETH_PRIVATE_KEY;

    function setUp() public {
        // Default behavior: use Anvil 0 private key
        ETH_PRIVATE_KEY = uint256(vm.envOr("ETH_PRIVATE_KEY", bytes32(type(uint256).max)));

        DEBUG = vm.envOr("DEBUG", true);
        DO_DEPLOY = vm.envOr("DO_DEPLOY", true);
        DO_AFTER_DEPLOY = vm.envOr("DO_AFTER_DEPLOY", true);
        DO_AFTER_DEPLOY_SETUP = vm.envOr("DO_AFTER_DEPLOY_SETUP", true);
        DO_BUILD = vm.envOr("DO_BUILD", true);
        DO_RUN = vm.envOr("DO_RUN", true);
        DO_TEARDOWN = vm.envOr("DO_TEARDOWN", true);
        DO_VALIDATE = vm.envOr("DO_VALIDATE", true);
        DO_PRINT = vm.envOr("DO_PRINT", true);

        addresses = new Addresses();
    }

    function run() public {
        addresses.resetRecordingAddresses();

        address deployerAddress = vm.addr(ETH_PRIVATE_KEY);

        console.log("deployerAddress: ", deployerAddress);

        vm.startBroadcast(ETH_PRIVATE_KEY);
        if (DO_DEPLOY) deploy(addresses, deployerAddress);
        if (DO_AFTER_DEPLOY) afterDeploy(addresses, deployerAddress);
        vm.stopBroadcast();

        if (DO_BUILD) build(addresses, deployerAddress);
        if (DO_RUN) run(addresses, deployerAddress);
        if (DO_TEARDOWN) teardown(addresses, deployerAddress);
        if (DO_VALIDATE) validate(addresses, deployerAddress);
        if (DO_PRINT) {
            printProposalActionSteps();
        }

        if (DO_DEPLOY) {
            (string[] memory recordedNames, address[] memory recordedAddresses) = addresses.getRecordedAddresses();
            for (uint256 i = 0; i < recordedNames.length; i++) {
                console.log("Deployed", recordedAddresses[i], recordedNames[i]);
            }

            console.log();

            for (uint256 i = 0; i < recordedNames.length; i++) {
                console.log('_addAddress("%s",', recordedNames[i]);
                console.log(block.chainid);
                console.log(", ");
                console.log(recordedAddresses[i]);
                console.log(");");
            }
        }
    }
}
