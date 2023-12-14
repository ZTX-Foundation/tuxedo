//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";
import {TimelockProposal} from "@proposals/proposalTypes/TimelockProposal.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {Token, MAX_SUPPLY} from "@protocol/token/Token.sol";
import {ERC20HoldingDeposit} from "@protocol/finance/ERC20HoldingDeposit.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract zip002 is Proposal, TimelockProposal {
    string public name = "ZIP002";
    string public description = "The TimeLock deployment";

    function _beforeDeploy(Addresses addresses, address deployer) internal override {
        /// Get Core Address
        _core = Core(addresses.getCore());
    }

    function _deploy(Addresses addresses, address) internal override {
        /// Admin timelock controller
        address[] memory adminTimelockProposersExecutors = new address[](1);

        adminTimelockProposersExecutors[0] = address(addresses.getAddress("ADMIN_MULTISIG"));
        TimelockController adminTimelock = new TimelockController(
            0, // zero delay
            adminTimelockProposersExecutors,
            adminTimelockProposersExecutors,
            address(0) // No admin requried
        );
        addresses.addAddress("ADMIN_TIMELOCK_CONTROLLER", address(adminTimelock));
    }

    function _afterDeploy(Addresses addresses, address) internal override {}

    function _aferDeployForTestingOnly(Addresses addresses, address deployer) internal virtual override {
        /// For the sake of testing, give the ADMIN role to the ADMIN_TIMELOCK_CONTROLLER.
        /// This is not possible onchain as the deployer is not an Admin
        _core.grantRole(Roles.ADMIN, addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"));
    }

    function _afterDeployOnChain(Addresses, address deployer) internal virtual override {
        /// The ADMIN_MULTISIG now needs to give the ADMIN role to the ADMIN_TIMELOCK_CONTROLLER
        console.log("Please give Roles.Admin to the ADMIN_TIMELOCK_CONTROLLER from the ADMIN_MULTISIG");
    }

    function _validate(Addresses addresses, address) internal override {}

    function _validateOnChain(Addresses, address deployer) internal virtual override {}

    function _validateForTestingOnly(Addresses, address deployer) internal virtual override {}

    function _teardown(Addresses addresses, address deployer) internal override {}

    function _build(Addresses addresses, address deployer) internal override {}

    function _run(Addresses addresses, address deployer) internal override {}
}
