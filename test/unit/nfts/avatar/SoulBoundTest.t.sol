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

    function testBatchBalanceQuery() public {
        address recipient = address(1);
        soulBound.mint(recipient, 1);
        soulBound.mint(recipient, 2);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        address[] memory recipients = new address[](2);
        recipients[0] = recipient;
        recipients[1] = recipient;

        uint256[] memory balances = soulBound.balanceOfBatch(recipients, tokenIds);
        assertEq(balances[0], 1, "Incorrect balance for token 1");
        assertEq(balances[1], 1, "Incorrect balance for token 2");
    }

    function testFailMintUnauthorized() public {
        address unauthorizedUser = address(2);
        uint256 tokenId = 1;

        vm.prank(unauthorizedUser);
        vm.expectRevert("Unauthorized");
        soulBound.mint(unauthorizedUser, tokenId);
    }

    function testOwnerOfNonExistentToken() public {
        uint256 nonExistentTokenId = 999;

        // Depending on your contract's logic, expect revert or assert expected result
        vm.expectRevert("Token does not exist");
        soulBound.ownerOf(nonExistentTokenId);
    }

    function testFailMintWithInvalidTokenId() public {
        address recipient = address(1);
        uint256 invalidTokenId = 0; // Assuming 0 is an invalid or reserved token ID

        vm.expectRevert("Invalid token ID");
        soulBound.mint(recipient, invalidTokenId); // This should fail
    }

    function testBalanceQueryForNonOwner() public {
        address owner = address(1);
        address nonOwner = address(2);
        uint256 tokenId = 1;
        soulBound.mint(owner, tokenId);

        // Verify balance for non-owner is zero
        assertEq(soulBound.balanceOf(nonOwner, tokenId), 0, "Balance for non-owner should be zero");
    }

    function testOwnerMappingUpdate() public {
        address recipient = address(1);
        uint256 tokenId = 1;
        soulBound.mint(recipient, tokenId);

        // Verify that the owner mapping is correctly updated
        assertEq(soulBound.ownerOf(tokenId), recipient, "Owner mapping not updated correctly");
    }

    function testOwnerCheck() public {
        address recipient = address(1);
        uint256 tokenId = 1;

        // Mint the token to the recipient
        soulBound.mint(recipient, tokenId);

        // Use the internal _owners mapping to check the owner of the token
        address owner = soulBound.ownerOf(tokenId);

        // Assert that the owner recorded in the _owners mapping is the recipient
        assertEq(owner, recipient, "The owner is not correctly set after minting");
    }
}