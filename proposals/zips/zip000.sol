//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {MultisigProposal} from "@forge-proposal-simulator/src/proposals/MultisigProposal.sol";

import {Token, MAX_SUPPLY} from "@protocol/token/Token.sol";
import {ERC20HoldingDeposit} from "@protocol/finance/ERC20HoldingDeposit.sol";

contract zip000 is MultisigProposal {

    // Returns the name of the proposal.
    function name() public pure override returns (string memory) {
        return "ZIP000";
    }

    // Provides a brief description of the proposal.
    function description() public pure override returns (string memory) {
        return "The ZTX Genesis Proposal";
    }

    function deploy() public override {
        /// Token deployment
        {
            Token token = new Token(
                string(abi.encodePacked(vm.envString("TOKEN_NAME"))),
                string(abi.encodePacked(vm.envString("TOKEN_SYMBOL")))
            );
            addresses.addAddress("TOKEN", address(token), true);
        }

        /// Token transfer
        IERC20(addresses.getAddress("TOKEN")).transfer(addresses.getAddress("TREASURY_WALLET_MULTISIG"), MAX_SUPPLY);
    }

    function validate() public override {
        /// Check Treasury balance
        assertEq(
            IERC20(addresses.getAddress("TOKEN")).balanceOf(addresses.getAddress("TREASURY_WALLET_MULTISIG")),
            10_000_000_000e18 // hardcoded to Verify all code is working
        );
    }

    function run() public override {
        // No actions to print
        DO_PRINT = false;

        super.run();
    }
}
