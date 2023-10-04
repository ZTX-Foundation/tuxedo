//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {Test} from "@forge-std/Test.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";

import {zip000} from "@proposals/zips/zip000.sol";
import {zip999} from "@proposals/zips/zip999.sol";

/*
How to use:
forge test --fork-url $ETH_RPC_URL --match-contract TestProposals -vvv

Or, from another Solidity file (for post-proposal integration testing):
    TestProposals proposals = new TestProposals();
    proposals.setUp();
    proposals.setDebug(false); // don't console.log
    proposals.testProposals();
    Addresses addresses = proposals.addresses();
*/

contract TestProposals is Test {
    Addresses public addresses;
    Proposal[] public proposals;
    uint256 public nProposals;
    bool public debug;
    bool public doDeploy;
    bool public doAfterDeploy;
    bool public doBuild;
    bool public doRun;
    bool public doTeardown;
    bool public doValidate;

    address public deployer = address(0x00000108);

    function setUp() public {
        // debug = vm.envOr("DEBUG", true);
        // doDeploy = vm.envOr("DO_DEPLOY", true);
        // doAfterDeploy = vm.envOr("DO_AFTER_DEPLOY", true);
        // doBuild = vm.envOr("DO_BUILD", true);
        // doRun = vm.envOr("DO_RUN", true);
        // doTeardown = vm.envOr("DO_TEARDOWN", true);
        // doValidate = vm.envOr("DO_VALIDATE", true);
        addresses = new Addresses();

        // Load proposals
        proposals.push(Proposal(address(new zip000())));
        proposals.push(Proposal(address(new zip999())));

        nProposals = proposals.length;
    }

    function setDebug(bool value) public {
        debug = value;
        for (uint256 i = 0; i < proposals.length; i++) {
            proposals[i].setDebug(value);
        }
    }

    function testProposals() public returns (uint256[] memory postProposalVmSnapshots) {
        if (debug) {
            console.log("TestProposals: running", proposals.length, "proposals.");
        }

        /// evm snapshot array
        postProposalVmSnapshots = new uint256[](proposals.length);

        for (uint256 i = 0; i < proposals.length; i++) {
            string memory name = proposals[i].name();
            console.log("Proposal", name, "deploy()");
            addresses.resetRecordingAddresses();

            // Deploy step
            proposals[i].deployForTestingOnly(addresses, deployer);

            /// output deployed contract addresses and names
            (string[] memory recordedNames, address[] memory recordedAddresses) = addresses.getRecordedAddresses();
            for (uint256 j = 0; j < recordedNames.length; j++) {
                console.log("  Deployed", recordedAddresses[j], recordedNames[j]);
            }

            /// take new snapshot
            postProposalVmSnapshots[i] = vm.snapshot();
        }

        return postProposalVmSnapshots;
    }

    // function testProposals() public returns (uint256[] memory postProposalVmSnapshots) {
    //     if (debug) {
    //         console.log("TestProposals: running", proposals.length, "proposals.");
    //     }
    //     postProposalVmSnapshots = new uint256[](proposals.length);
    //     for (uint256 i = 0; i < proposals.length; i++) {
    //         string memory name = proposals[i].name();

    //         // Deploy step
    //         if (doDeploy) {
    //             if (debug) {
    //                 console.log("Proposal", name, "deploy()");
    //                 addresses.resetRecordingAddresses();
    //             }

    //             vm.startBroadcast(deployer);
    //             proposals[i].deploy(addresses, deployer);
    //             vm.stopBroadcast();

    //             if (debug) {
    //                 (string[] memory recordedNames, address[] memory recordedAddresses) = addresses
    //                     .getRecordedAddresses();
    //                 for (uint256 j = 0; j < recordedNames.length; j++) {
    //                     console.log("  Deployed", recordedAddresses[j], recordedNames[j]);
    //                 }
    //             }
    //         }

    //         // After-deploy step
    //         if (doAfterDeploy) {
    //             if (debug) console.log("Proposal", name, "afterDeploy()");

    //             vm.startBroadcast(deployer);
    //             proposals[i].afterDeploy(addresses, deployer);
    //             vm.stopBroadcast();
    //         }

    //         // Build step
    //         if (doBuild) {
    //             if (debug) console.log("Proposal", name, "build()");

    //             vm.startBroadcast(deployer);
    //             proposals[i].build(addresses);
    //             vm.stopBroadcast();
    //         }

    //         // Run step
    //         if (doRun) {
    //             if (debug) console.log("Proposal", name, "run()");

    //             vm.startBroadcast(deployer);
    //             proposals[i].run(addresses, deployer);
    //             vm.stopBroadcast();
    //         }

    //         // Teardown step
    //         if (doTeardown) {
    //             if (debug) console.log("Proposal", name, "teardown()");

    //             vm.startBroadcast(deployer);
    //             proposals[i].teardown(addresses, deployer);
    //             vm.stopBroadcast();
    //         }

    //         // Validate step
    //         if (doValidate) {
    //             if (debug) console.log("Proposal", name, "validate()");
    //             vm.startBroadcast(deployer);
    //             proposals[i].validate(addresses, deployer);
    //             vm.stopBroadcast();
    //         }

    //         if (debug) console.log("Proposal", name, "done.");

    //         postProposalVmSnapshots[i] = vm.snapshot();
    //     }

    //     return postProposalVmSnapshots;
    // }
}
