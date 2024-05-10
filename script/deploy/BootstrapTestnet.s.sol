// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {Script} from "@forge-std/Script.sol";
import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";

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
import {zip016} from "@proposals/zips/zip016.sol";
import {zip017} from "@proposals/zips/zip017.sol";

/*
How to use:
forge script script/deploy/BootstrapTestnet.s.sol:BootstrapTestnet \
    -vvvv \
    --rpc-url $ETH_RPC_URL \
    --broadcast \
    --private-key <KEY>
Remove --broadcast and --private-key if you want to try locally first, without paying any gas.
*/

contract BootstrapTestnet is Script {
    uint256 public privateKey;

    Addresses addresses;
    Proposal[] public proposals;

    function setUp() public {
        string memory environment = vm.envOr("ENVIRONMENT", string("localnet"));
        string memory addressPath = string(abi.encodePacked("proposals/Addresses/", environment, ".json"));
        addresses = new Addresses(addressPath);
        addresses.resetRecordingAddresses();

        // Load proposals
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
        proposals.push(Proposal(address(new zip016()))); /// MaxSupply settings proposal
        proposals.push(Proposal(address(new zip017()))); /// MaxSupply settings proposal
    }

    function run() public {
        for (uint256 i = 0; i < proposals.length; i++) {
            string memory name = proposals[i].name();
            console.log("Proposal", name, "deploy()");
            addresses.resetRecordingAddresses();

            // Run the deploy for testing only workflow
            proposals[i].run();

            /// output deployed contract addresses and names
            (string[] memory recordedNames, , address[] memory recordedAddresses) = Addresses(proposals[i].addresses())
                .getRecordedAddresses();
            for (uint256 j = 0; j < recordedNames.length; j++) {
                console.log("  Deployed", recordedAddresses[j], recordedNames[j]);
            }
        }
    }
}
