//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {Script} from "@forge-std/Script.sol";

import {Addresses, EnvVar} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";

import {zip000} from "@proposals/zips/zip000.sol";
import {zip001} from "@proposals/zips/zip001.sol";

contract DeployCompleteSystem is Script {
    uint256 public privateKey;
    Proposal[] public proposals;
    EnvVar public env;

    function setUp() public {
        privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        // Load proposals
        proposals.push(Proposal(address(new zip000())));
        proposals.push(Proposal(address(new zip001())));
    }

    function run(EnvVar _env) public {
        env = _env;
        Addresses addresses = new Addresses(env);
        addresses.resetRecordingAddresses();

        console.log("DeployCompleteSystem: running", proposals.length, "proposals.");

        for (uint256 i = 0; i < proposals.length; i++) {
            string memory name = proposals[i].name();
            console.log("Proposal", name, "deploy()");
            addresses.resetRecordingAddresses();

            // Run the deploy
            proposals[i].deployOnChain(addresses, privateKey);

            /// output deployed contract addresses and names
            (string[] memory recordedNames, address[] memory recordedAddresses) = addresses.getRecordedAddresses();
            for (uint256 j = 0; j < recordedNames.length; j++) {
                console.log("  Deployed", recordedAddresses[j], recordedNames[j]);
            }
        }
    }
}
