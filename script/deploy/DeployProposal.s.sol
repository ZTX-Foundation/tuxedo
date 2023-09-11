// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {Script} from "@forge-std/Script.sol";
import {Addresses} from "@test/proposals/Addresses.sol";
import {Proposal} from "@test/proposals/proposalTypes/Proposal.sol";

import {zip000} from "@test/proposals/zips/zip000.sol";
import {zip001} from "@test/proposals/zips/zip001.sol";

/*
How to use:
forge script test/proposals/DeployProposal.s.sol:DeployProposal \
    -vvvv \
    --rpc-url $ETH_RPC_URL \
    --broadcast
Remove --broadcast if you want to try locally first, without paying any gas.
*/

contract DeployProposal is Script {
    uint256 public constant MAINNET = 42161; // Arb mainnet
    uint256 public constant TESTNET = 421614; // Arb testnet
    uint256 public chainId;

    Proposal[] public proposals;
    uint256 public privateKey;
    bool public doDeploy;
    bool public doAfterDeploy;
    bool public doValidate;
    bool public doTeardown;
    bool public debug;

    function setUp() public {
        chainId = block.chainid;

        // Default behavior: debug
        debug = vm.envOr("DEBUG", true);
        privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        // Default behavior: do deploy
        doDeploy = vm.envOr("DO_DEPLOY", true);
        // Default behavior: do after-deploy
        doAfterDeploy = vm.envOr("DO_AFTERDEPLOY", true);
        // Default behavior: do validate
        doValidate = vm.envOr("DO_VALIDATE", true);
        // Default behavior: don't do teardown
        doTeardown = vm.envOr("DO_TEARDOWN", false);

        proposals.push(Proposal(address(new zip000())));
        proposals.push(Proposal(address(new zip001())));
    }

    function run() public {
        Addresses addresses = new Addresses();
        addresses.resetRecordingAddresses();
        address deployerAddress = vm.addr(privateKey);
        vm.startBroadcast(privateKey);

        if (debug) {
            console.log("DeployProposals: running", proposals.length, "proposals.");
        }

        for (uint256 i = 0; i < proposals.length; i++) {
            string memory name = proposals[i].name();

            // Deploy step
            if (doDeploy) {
                if (debug) {
                    console.log("Proposal", name, "deploy()");
                }
                // test we are deploying to mainNet
                if (chainId == MAINNET) {
                    // test if we have already deployed contract.
                    if (!proposals[i].mainnetDeployed()) {
                        proposals[i].deploy(addresses, address(this));
                    }
                    // test we are deploying to testNet
                } else if (chainId == TESTNET) {
                    // test if we have already deployed contract.
                    if (!proposals[i].testnetDeployed()) {
                        proposals[i].deploy(addresses, address(this));
                    }
                    // Deploy to all unknown chains ie localnet without deployment checks per proposal
                } else {
                    if (debug) {
                        console.log("Deploying: ", name, "to chainId", chainId);
                    }
                    proposals[i].deploy(addresses, address(this));
                }
                if (debug) {
                    (string[] memory recordedNames, address[] memory recordedAddresses) = addresses
                        .getRecordedAddresses();
                    for (uint256 j = 0; j < recordedNames.length; j++) {
                        console.log("  Deployed", recordedAddresses[j], recordedNames[j]);
                    }
                }
            }

            // After-deploy step
            if (doAfterDeploy) {
                if (debug) console.log("Proposal", name, "afterDeploy()");

                // test we are on mainNet
                if (chainId == MAINNET) {
                    // test if we have already deployed contract.
                    if (!proposals[i].mainnetDeployed()) {
                        proposals[i].afterDeploy(addresses, address(proposals[i]));
                    }
                    // test we are on testNet
                } else if (chainId == TESTNET) {
                    // test if we have already deployed contract.
                    if (!proposals[i].testnetDeployed()) {
                        proposals[i].afterDeploy(addresses, address(proposals[i]));
                    }
                    // Run for all unknown chains ie localnet without deployment checks per proposal
                } else {
                    if (debug) {
                        console.log("Deploying: ", name, "to chainId", chainId);
                    }
                    proposals[i].afterDeploy(addresses, address(proposals[i]));
                }
            }

            // Validate step
            if (doValidate) {
                if (debug) console.log("Proposal", name, "validate()");

                // test we are on mainNet
                if (chainId == MAINNET) {
                    // test if we have already deployed contract.
                    if (!proposals[i].mainnetDeployed()) {
                        proposals[i].validate(addresses, address(proposals[i]));
                    }
                    // test we are on testNet
                } else if (chainId == TESTNET) {
                    // test if we have already deployed contract.
                    if (!proposals[i].testnetDeployed()) {
                        proposals[i].validate(addresses, address(proposals[i]));
                    }
                    // Run for all unknown chains ie localnet without deployment checks per proposal
                } else {
                    if (debug) {
                        console.log("Deploying: ", name, "to chainId", chainId);
                    }
                    proposals[i].validate(addresses, address(proposals[i]));
                }
            }

            // Teardown step
            if (doTeardown) {
                if (debug) console.log("Proposal", name, "teardown()");

                // test we are on mainNet
                if (chainId == MAINNET) {
                    // test if we have already deployed contract.
                    if (!proposals[i].mainnetDeployed()) {
                        proposals[i].teardown(addresses, address(proposals[i]));
                    }
                    // test we are on testNet
                } else if (chainId == TESTNET) {
                    // test if we have already deployed contract.
                    if (!proposals[i].testnetDeployed()) {
                        proposals[i].teardown(addresses, address(proposals[i]));
                    }
                    // Run for all unknown chains ie localnet without deployment checks per proposal
                } else {
                    if (debug) {
                        console.log("Deploying: ", name, "to chainId", chainId);
                    }
                    proposals[i].teardown(addresses, address(proposals[i]));
                }
            }

            if (debug) console.log("Proposal", name, "done.");
        }

        vm.stopBroadcast();
    }
}
