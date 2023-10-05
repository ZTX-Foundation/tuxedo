//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";
import {TimelockProposal} from "@proposals/proposalTypes/TimelockProposal.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {Token} from "@protocol/token/Token.sol";
import {ERC20HoldingDeposit} from "@protocol/finance/ERC20HoldingDeposit.sol";

contract zip000 is Proposal, TimelockProposal {
    string public name = "ZIP000";
    string public description = "The ZTX Genesis Proposal";

    function _beforeDeploy(Addresses, address deployer) internal override {
        // first deployment. Nothing to check
    }

    function _deploy(Addresses addresses, address) internal override {
        /// Core protocol
        _core = new Core();
        addresses.addAddress("CORE", address(_core));

        /// Token deployment
        {
            Token token = new Token(
                string(abi.encodePacked(vm.envString("TOKEN_NAME"))),
                string(abi.encodePacked(vm.envString("TOKEN_SYMBOL")))
            );
            addresses.addAddress("TOKEN", address(token));
        }
    }

    function _afterDeploy(Addresses addresses, address) internal override {
        /// Token transfer
        IERC20(addresses.getAddress("TOKEN")).transfer(
            addresses.getAddress("TREASURY_WALLET_MULTISIG"),
            10_000_000_000e18
        );

        // Setup ADMIN_MULTISIG
        _core.grantRole(Roles.ADMIN, addresses.getAddress("ADMIN_MULTISIG"));
    }

    function _validate(Addresses addresses, address) internal override {
        /// Check Treasury balance
        assertEq(
            IERC20(addresses.getAddress("TOKEN")).balanceOf(addresses.getAddress("TREASURY_WALLET_MULTISIG")),
            10_000_000_000e18
        );

        // Check Roles
        assertEq(_core.hasRole(Roles.ADMIN, addresses.getAddress("ADMIN_MULTISIG")), true);
    }

    function _teardown(Addresses addresses, address deployer) internal override {}

    function _build(Addresses addresses, address deployer) internal override {}

    function _run(Addresses addresses, address deployer) internal override {}
}
