//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {Script} from "@forge-std/Script.sol";

import {Addresses, EnvVar} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";

import {zip000} from "@proposals/zips/zip000.sol";
import {zip001} from "@proposals/zips/zip001.sol";
import {zip002} from "@proposals/zips/zip002.sol";
import {zip003} from "@proposals/zips/zip003.sol";

contract BaseDeployCompleteSystem is Script {
    uint256 public privateKey;
    Proposal[] public proposals;

    function setUp() public virtual {
        privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        // Load proposals
        proposals.push(Proposal(address(new zip000())));
        proposals.push(Proposal(address(new zip001())));
        proposals.push(Proposal(address(new zip002())));
        proposals.push(Proposal(address(new zip003())));
    }

    function deployOnTestNet(Addresses addresses) public {
        console.log("DeployCompleteSystem: running", proposals.length, "proposals.");

        for (uint256 i = 0; i < proposals.length; i++) {
            proposals[i].deployOnTestNet(addresses, privateKey);
        }
    }
}
