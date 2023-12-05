//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {Test} from "@forge-std/Test.sol";

import {IProposal} from "@proposals/proposalTypes/IProposal.sol";
import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";

import {zip000} from "@proposals/zips/zip000.sol";
import {zip001} from "@proposals/zips/zip001.sol";
import {zip002} from "@proposals/zips/zip002.sol";
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
    bool public DEBUG;
    bool public DO_DEPLOY;
    bool public DO_AFTER_DEPLOY;
    bool public DO_BUILD;
    bool public DO_RUN;
    bool public DO_TEARDOWN;
    bool public DO_VALIDATE;

    constructor(address[] memory _proposals) {
        for (uint256 i = 0; i < _proposals.length; i++) {
            proposals.push(Proposal(_proposals[i]));
        }

        nProposals = _proposals.length;
    }

    function setUp() public {
        DEBUG = vm.envOr("DEBUG", true);
        DO_DEPLOY = vm.envOr("DO_DEPLOY", true);
        DO_AFTER_DEPLOY = vm.envOr("DO_AFTER_DEPLOY", true);
        DO_BUILD = vm.envOr("DO_BUILD", true);
        DO_RUN = vm.envOr("DO_RUN", true);
        DO_TEARDOWN = vm.envOr("DO_TEARDOWN", true);
        DO_VALIDATE = vm.envOr("DO_VALIDATE", true);

        addresses = new Addresses();

        // proposals.push(Proposal(address(new mipb01())));
        nProposals = proposals.length;
    }

    // function printCalldata(uint256 index, address temporalGovernor, address wormholeCore) public {
    //     IProposal(address(proposals[index])).printProposalActionSteps();
    // }

    function printProposalActionSteps() public {
        for (uint256 i = 0; i < proposals.length; i++) {
            proposals[i].printProposalActionSteps();
        }
    }

    function testProposals(
        bool debug,
        bool deploy,
        bool afterDeploy,
        bool build,
        bool run,
        bool teardown,
        bool validate
    ) public returns (uint256[] memory postProposalVmSnapshots) {
        if (debug) {
            console.log("TestProposals: running", proposals.length, "proposals.");
        }

        postProposalVmSnapshots = new uint256[](proposals.length);
        for (uint256 i = 0; i < proposals.length; i++) {
            string memory name = IProposal(address(proposals[i])).name();

            // Deploy step
            if (deploy) {
                if (debug) {
                    console.log("Proposal", name, "deploy()");
                    addresses.resetRecordingAddresses();
                }
                proposals[i].deploy(addresses, address(proposals[i])); /// mip itself is the deployer
                if (debug) {
                    (string[] memory recordedNames, address[] memory recordedAddresses) = addresses
                        .getRecordedAddresses();
                    for (uint256 j = 0; j < recordedNames.length; j++) {
                        console.log('{\n        "addr": "%s, ', recordedAddresses[j]);
                        console.log('        "chainId": %d,', block.chainid);
                        console.log(
                            '        "name": "%s"\n}%s',
                            recordedNames[j],
                            j < recordedNames.length - 1 ? "," : ""
                        );
                    }
                }
            }

            // After-deploy step
            if (afterDeploy) {
                if (debug) console.log("Proposal", name, "afterDeploy()");
                proposals[i].afterDeploy(addresses, address(proposals[i]));
            }

            // Build step
            if (build) {
                if (debug) console.log("Proposal", name, "build()");
                proposals[i].build(addresses, address(proposals[i]));
            }

            // Run step
            if (run) {
                if (debug) console.log("Proposal", name, "run()");
                proposals[i].run(addresses, address(proposals[i]));
            }

            // Teardown step
            if (teardown) {
                if (debug) console.log("Proposal", name, "teardown()");
                proposals[i].teardown(addresses, address(proposals[i]));
            }

            // Validate step
            if (validate) {
                if (debug) console.log("Proposal", name, "validate()");
                proposals[i].validate(addresses, address(proposals[i]));
            }

            if (debug) console.log("Proposal", name, "done.");

            postProposalVmSnapshots[i] = vm.snapshot();
        }

        return postProposalVmSnapshots;
    }

    function testProposals() public returns (uint256[] memory postProposalVmSnapshots) {
        return testProposals(DEBUG, DO_DEPLOY, DO_AFTER_DEPLOY, DO_BUILD, DO_RUN, DO_TEARDOWN, DO_VALIDATE);
    }
}
