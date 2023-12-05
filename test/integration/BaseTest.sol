// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@forge-std/Test.sol";

import {zip001} from "@proposals/zips/zip001.sol";
import {zip002} from "@proposals/zips/zip002.sol";
import {Addresses} from "@proposals/Addresses.sol";
import {IProposal} from "@proposals/proposalTypes/IProposal.sol";
import {TestProposals} from "@proposals/TestProposals.sol";

contract BaseTest is Test, ERC1155Holder {
    Addresses addresses;
    uint256 preProposalsSnapshot;
    uint256 postProposalsSnapshot;

    uint256 arbitrumFork;

    function setUp() public virtual {
        arbitrumFork = vm.createFork(vm.envString("ARBITRUM_TESTNET_GOERLI_RPC_URL"));
        vm.selectFork(arbitrumFork);

        runProposals();
    }

    function runProposals() internal virtual {
        preProposalsSnapshot = vm.snapshot();

        address[] memory _proposals = new address[](2);
        _proposals[0] = address(new zip001());
        _proposals[1] = address(new zip002());

        // Run all pending proposals first
        TestProposals proposals = new TestProposals(_proposals);
        proposals.setUp();
        IProposal(address(proposals)).setDebug(false);
        proposals.testProposals();
        addresses = proposals.addresses();

        postProposalsSnapshot = vm.snapshot();
    }
}
