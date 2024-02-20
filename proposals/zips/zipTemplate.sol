//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";
import {TimelockProposal} from "@proposals/proposalTypes/TimelockProposal.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {Token, MAX_SUPPLY} from "@protocol/token/Token.sol";
import {ERC20HoldingDeposit} from "@protocol/finance/ERC20HoldingDeposit.sol";

contract zipTemplate is Proposal, TimelockProposal {
    constructor() {
        name = "ZIPTEMPLATE";
        description = "Template proposal";
    }
    function _beforeDeploy(Addresses, address deployer) internal override {}

    function _deploy(Addresses addresses, address) internal override {}

    function _afterDeploy(Addresses addresses, address) internal override {}

    function _afterDeployOnChain(Addresses, address deployer) internal virtual override {}

    function _validate(Addresses addresses, address) internal override {}

    function _validateOnChain(Addresses, address deployer) internal virtual override {}

    function _validateForTestingOnly(Addresses, address deployer) internal virtual override {}

    function _teardown(Addresses addresses, address deployer) internal override {}

    function _build(Addresses addresses, address deployer) internal override {}

    function _run(Addresses addresses, address deployer) internal override {}
}
