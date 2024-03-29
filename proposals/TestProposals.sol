//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {Test} from "@forge-std/Test.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";

import {zip000} from "@proposals/zips/zip000.sol";
import {zip001} from "@proposals/zips/zip001.sol";
import {zip002} from "@proposals/zips/zip002.sol";
import {zip003} from "@proposals/zips/zip003.sol";
import {zip004} from "@proposals/zips/zip004.sol";
import {zip005} from "@proposals/zips/zip005.sol";
import {zip006} from "@proposals/zips/zip006.sol";
import {zipTest} from "@proposals/zips/zipTest.sol";

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
        addresses = new Addresses();

        // Load proposals
        proposals.push(Proposal(address(new zip000()))); /// Genesis token proposal
        proposals.push(Proposal(address(new zip001()))); /// Wearables, Core, ADMIN_MULTISIG proposal
        proposals.push(Proposal(address(new zip002()))); /// Timelock proposal
        proposals.push(Proposal(address(new zip003()))); /// CGv1 proposal
        proposals.push(Proposal(address(new zip004()))); /// TokenIds, MaxSupply and Capsule settings proposal
        proposals.push(Proposal(address(new zip005()))); /// MaxSupply settings proposal
        proposals.push(Proposal(address(new zip006()))); /// MaxSupply settings proposal
        proposals.push(Proposal(address(new zipTest()))); /// RnD/testing only proposal

        nProposals = proposals.length;

        vm.warp(block.timestamp + 1); /// required for timelock to work
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

            // Run the deploy for testing only workflow
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
}
