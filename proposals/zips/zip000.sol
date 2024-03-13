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

contract zip000 is Proposal, TimelockProposal {
    constructor() {
        name = "ZIP000";
        description = "The ZTX Genesis Proposal";
    }

    function _beforeDeploy(Addresses addresses, address) internal override {
        assertNotEq(addresses.getAddress("TREASURY_WALLET_MULTISIG"), address(0), "treasury wallet not set");
    }

    function _deploy(Addresses addresses, address) internal override {
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
        IERC20(addresses.getAddress("TOKEN")).transfer(addresses.getAddress("TREASURY_WALLET_MULTISIG"), MAX_SUPPLY);
    }

    function _aferDeployForTestingOnly(Addresses, address) internal virtual override {}

    function _afterDeployOnMainNet(Addresses, address) internal virtual override {}

    function _afterDeployOnTestNet(Addresses, address) internal virtual override {}

    function _validate(Addresses addresses, address) internal override {
        /// Check Treasury balance
        assertEq(
            IERC20(addresses.getAddress("TOKEN")).balanceOf(addresses.getAddress("TREASURY_WALLET_MULTISIG")),
            10_000_000_000e18 // hardcoded to verfiy all code is working
        );
    }

    function _validateForTestingOnly(Addresses, address) internal virtual override {}

    function _validateOnMainNet(Addresses, address) internal virtual override {}

    function _validateOnTestNet(Addresses, address) internal virtual override {} // check admin role was revoked;

    function _teardown(Addresses, address) internal override {}

    function _build(Addresses, address) internal override {}

    function _runOnMainNet(Addresses, address) internal override {}
    function _runOnTestNet(Addresses, address) internal override {}
}
