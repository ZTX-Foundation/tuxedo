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
    string public name = "ZIP000";
    string public description = "The ZTX Genesis Proposal";

    function deploy(Addresses addresses, address) public override {
        /// Token deployment
        {
            Token token = new Token(
                string(abi.encodePacked(vm.envString("TOKEN_NAME"))),
                string(abi.encodePacked(vm.envString("TOKEN_SYMBOL")))
            );
            addresses.addAddress("TOKEN", address(token));
        }
    }

    function afterDeploy(Addresses addresses, address) public override {
        /// Token transfer
        IERC20(addresses.getAddress("TOKEN")).transfer(addresses.getAddress("TREASURY_WALLET_MULTISIG"), MAX_SUPPLY);
    }

    function validate(Addresses addresses, address) public override {
        /// Check Treasury balance
        assertEq(
            IERC20(addresses.getAddress("TOKEN")).balanceOf(addresses.getAddress("TREASURY_WALLET_MULTISIG")),
            10_000_000_000e18 // hardcoded to verfiy all code is working
        );
    }

    function teardown(Addresses addresses, address deployer) public override {}

    function build(Addresses addresses, address deployer) public override {}

    function run(Addresses addresses, address deployer) public override {}
}
