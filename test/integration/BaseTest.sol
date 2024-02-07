// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {Addresses} from "@proposals/Addresses.sol";
import {TestProposals} from "@proposals/TestProposals.sol";
import "@forge-std/Test.sol";

contract BaseTest is Test, ERC1155Holder {
    Addresses addresses;
    uint256 preProposalsSnapshot;
    uint256 postProposalsSnapshot;

    function setUp() public virtual {
        runProposals();
    }

    function runProposals() internal virtual {
        preProposalsSnapshot = vm.snapshot();

        // Run all pending proposals first
        TestProposals proposals = new TestProposals();
        proposals.setUp();
        proposals.setDebug(false);
        proposals.testProposals();
        addresses = proposals.addresses();

        postProposalsSnapshot = vm.snapshot();
    }
}
