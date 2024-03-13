// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@forge-std/Test.sol";

import {BaseTest} from "@test/BaseTest.sol";
import {SoulBound} from "@protocol/nfts/avatar/SoulBound.sol";


contract SoulBoundTest is BaseTest {
    SoulBound soulBound;
    address mockCore = address(this); // Simplified CoreRef address for testing

    function setUp() public override {
        super.setUp();
        soulBound = new SoulBound("ipfs://metadata/", mockCore);
    }


    function testMintingAndOwnership() public {
        address to = address(1);
        uint256 tokenId = 1;

        soulBound.mint(to, tokenId);

        // Verify ownership
        assertEq(soulBound.balanceOf(to, tokenId), 1, "Owner should have a balance of 1");
    }

    function testFailMintToZeroAddress() public {
        uint256 tokenId = 1;
        soulBound.mint(address(0), tokenId);
    }

    function testFailMintDuplicateToken() public {
        address to = address(1);
        uint256 tokenId = 1;

        soulBound.mint(to, tokenId);
        soulBound.mint(to, tokenId); // This should fail
    }

    function testFailTransferToken() public {
        address to = address(1);
        uint256 tokenId = 1;

        soulBound.mint(to, tokenId);

        // This should revert with the "SoulBound tokens cannot be transferred" message
        vm.expectRevert(bytes("SoulBound tokens cannot be transferred"));
        soulBound.safeTransferFrom(to, address(2), tokenId, 1, "");
    }

    function testFailBatchTransferToken() public {
        address to = address(1);
        uint256 tokenId = 1;

        soulBound.mint(to, tokenId);

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        // This should revert with the "SoulBound tokens cannot be transferred" message
        vm.expectRevert(bytes("SoulBound tokens cannot be transferred"));
        soulBound.safeBatchTransferFrom(to, address(2), ids, amounts, "");
    }

}