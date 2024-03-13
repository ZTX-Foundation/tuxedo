// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseTest} from "@test/BaseTest.sol";
import {SoulBound} from "@protocol/nfts/avatar/SoulBound.sol";
import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";
import {Roles} from "@protocol/core/Roles.sol";

contract SoulBoundTest is BaseTest {
    SoulBound soulBound;
    uint256 public privateKey;
    address public notary;

    function testMintSuccess() public {
        address recipient = address(1);
        uint256 tokenId = 1;
        vm.startPrank(notary);
        soulBound.mint(recipient, tokenId);
        vm.stopPrank();
        assertEq(soulBound.balanceOf(recipient, tokenId), 1);
    }

    function setUp() public override {
        super.setUp();
        soulBound = new SoulBound("ipfs://metadata/", address(core));
        string memory mnemonic = "test test test test test test test test test test test junk";
        privateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/1/", 0);

        notary = vm.addr(privateKey);

        vm.startPrank(addresses.adminAddress);
        core.grantRole(Roles.MINTER_PROTOCOL_ROLE, notary);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, address(soulBound));
        vm.stopPrank();

    }

    function testFailMintDuplicateToken() public {
        address recipient = address(1);
        uint256 tokenId = 1;
        vm.startPrank(notary);
        soulBound.mint(recipient, tokenId);
        vm.stopPrank();
        vm.startPrank(notary);
        soulBound.mint(recipient, tokenId); // This should fail
        vm.stopPrank();
    }

    function testFailTransferToken() public {
        address recipient = address(1);
        uint256 tokenId = 1;
        vm.startPrank(notary);
        soulBound.mint(recipient, tokenId);
        vm.stopPrank();
        soulBound.safeTransferFrom(recipient, address(2), tokenId, 1, "");
    }

    function testFailBatchTransferToken() public {
        address recipient = address(1);
        uint256 tokenId = 1;
        vm.startPrank(notary);
        soulBound.mint(recipient, tokenId);
        vm.stopPrank();
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        soulBound.safeBatchTransferFrom(recipient, address(2), ids, amounts, "");
    }

    function testBatchBalanceQuery() public {
        address recipient = address(1);
        vm.startPrank(notary);
        soulBound.mint(recipient, 1);
        vm.stopPrank();
        vm.startPrank(notary);
        soulBound.mint(recipient, 2);
        vm.stopPrank();

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
        vm.startPrank(notary);
        soulBound.mint(owner, tokenId);
        vm.stopPrank();
        // Verify balance for non-owner is zero
        assertEq(soulBound.balanceOf(nonOwner, tokenId), 0, "Balance for non-owner should be zero");
    }

    function testOwnerMappingUpdate() public {
        address recipient = address(1);
        uint256 tokenId = 1;
        vm.startPrank(notary);
        soulBound.mint(recipient, tokenId);
        vm.stopPrank();
        // Verify that the owner mapping is correctly updated
        assertEq(soulBound.ownerOf(tokenId), recipient, "Owner mapping not updated correctly");
    }

    function testOwnerCheck() public {
        address recipient = address(1);
        uint256 tokenId = 1;
        vm.startPrank(notary);
        // Mint the token to the recipient
        soulBound.mint(recipient, tokenId);
        vm.stopPrank();
        // Use the internal _owners mapping to check the owner of the token
        address owner = soulBound.ownerOf(tokenId);

        // Assert that the owner recorded in the _owners mapping is the recipient
        assertEq(owner, recipient, "The owner is not correctly set after minting");
    }
}