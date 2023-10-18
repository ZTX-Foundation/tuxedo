//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {Test} from "@forge-std/Test.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";

import {zip000} from "@proposals/zips/zip000.sol";
import {zip001} from "@proposals/zips/zip001.sol";
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
        proposals.push(Proposal(address(new zip000())));
        proposals.push(Proposal(address(new zip001())));
        proposals.push(Proposal(address(new zipTest())));

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
