//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Addresses} from "@test/proposals/Addresses.sol";
import {Proposal} from "@test/proposals/proposalTypes/Proposal.sol";
import {TimelockProposal} from "@test/proposals/proposalTypes/TimelockProposal.sol";

contract zip000 is Proposal, TimelockProposal {
    string public name = "ZIP000";
    string public description = "The ZTX Genesis Proposal";

    function deploy(Addresses addresses, address deployer) public {}

    function afterDeploy(Addresses addresses, address deployer) public {}

    function teardown(Addresses addresses, address deployer) public pure {}

    function validate(Addresses addresses, address deployer) public {}

    function build(Addresses addresses) public {}

    function run(Addresses addresses, address deployer) public {}
}
