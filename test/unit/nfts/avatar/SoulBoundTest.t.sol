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

    function testMintSuccess() public {
        address recipient = address(1);
        uint256 tokenId = 1;
        soulBound.mint(recipient, tokenId);
        assertEq(soulBound.balanceOf(recipient, tokenId), 1);
    }

    function testFailMintToZeroAddress() public {
        uint256 tokenId = 1;
        soulBound.mint(address(0), tokenId);
    }

    function testFailMintDuplicateToken() public {
        address recipient = address(1);
        uint256 tokenId = 1;
        soulBound.mint(recipient, tokenId);
        soulBound.mint(recipient, tokenId); // This should fail
    }

    function testFailTransferToken() public {
        address recipient = address(1);
        uint256 tokenId = 1;
        soulBound.mint(recipient, tokenId);
        soulBound.safeTransferFrom(recipient, address(2), tokenId, 1, "");
    }

    function testFailBatchTransferToken() public {
        address recipient = address(1);
        uint256 tokenId = 1;
        soulBound.mint(recipient, tokenId);
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        soulBound.safeBatchTransferFrom(recipient, address(2), ids, amounts, "");
    }
}