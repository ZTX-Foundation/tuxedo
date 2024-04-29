//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {Test} from "@forge-std/Test.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";
import {Constants} from '@proposals/utils/Constants.sol';

import {zip000} from "@proposals/zips/zip000.sol";
import {zip001} from "@proposals/zips/zip001.sol";
import {zip002} from "@proposals/zips/zip002.sol";
import {zip003} from "@proposals/zips/zip003.sol";
import {zip004} from "@proposals/zips/zip004.sol";
import {zip005} from "@proposals/zips/zip005.sol";
import {zip006} from "@proposals/zips/zip006.sol";
import {zip007} from "@proposals/zips/zip007.sol";
import {zip008} from "@proposals/zips/zip008.sol";
import {zip009} from "@proposals/zips/zip009.sol";
import {zip010} from "@proposals/zips/zip010.sol";
import {zip011} from "@proposals/zips/zip011.sol";
import {zip012} from "@proposals/zips/zip012.sol";
import {zip013} from "@proposals/zips/zip013.sol";
import {zip014} from "@proposals/zips/zip014.sol";
import {zipTest} from "@proposals/zips/zipTest.sol";

/*
How to use:
forge test --fork-url $RPC_URL --match-contract TestProposals -vvv

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

    function setUp() public {

        // Load proposals
        if (block.chainid == Constants.ANVIL) {
            proposals.push(Proposal(address(new zip000()))); /// Genesis token proposal
            proposals.push(Proposal(address(new zip001()))); /// Wearables, Core, ADMIN_MULTISIG proposal
            proposals.push(Proposal(address(new zip002()))); /// Timelock proposal
            proposals.push(Proposal(address(new zip003()))); /// CGv1 proposal
            proposals.push(Proposal(address(new zip004()))); /// TokenIds, MaxSupply and Capsule settings proposal
            proposals.push(Proposal(address(new zip005()))); /// MaxSupply settings proposal
            proposals.push(Proposal(address(new zip006()))); /// MaxSupply settings proposal
            proposals.push(Proposal(address(new zip007()))); /// MaxSupply settings proposal
            proposals.push(Proposal(address(new zip008()))); /// MaxSupply settings proposal
            proposals.push(Proposal(address(new zip009()))); /// MaxSupply settings proposal
            proposals.push(Proposal(address(new zip010()))); /// MaxSupply settings proposal
            proposals.push(Proposal(address(new zip011()))); /// MaxSupply settings proposal
            proposals.push(Proposal(address(new zip012()))); /// MaxSupply settings proposal
            proposals.push(Proposal(address(new zip013()))); /// MaxSupply settings proposal
            proposals.push(Proposal(address(new zip014()))); /// MaxSupply settings proposal
        }

        proposals.push(Proposal(address(new zipTest()))); /// RnD/testing only proposal

        addresses = proposals[0].addresses();

        for (uint256 i = 1; i < proposals.length; i++) {
            proposals[i].setAddresses(addresses);
        }

        vm.warp(block.timestamp + 1); /// required for timelock to work
    }

    function testProposals() public returns (uint256[] memory postProposalVmSnapshots) {
        console.log("TestProposals: running", proposals.length, "proposals.");

        /// evm snapshot array
        postProposalVmSnapshots = new uint256[](proposals.length);

        for (uint256 i = 0; i < proposals.length; i++) {
            string memory name = proposals[i].name();
            console.log("Proposal", name, "run()");

            proposals[i].run();

            /// output deployed contract addresses and names
            proposals[i].addresses().printRecordedAddresses();
            proposals[i].addresses().printChangedAddresses();

            /// take new snapshot
            postProposalVmSnapshots[i] = vm.snapshot();
        }

        return postProposalVmSnapshots;
    }
}
