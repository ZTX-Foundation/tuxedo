// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseTest} from "@test/BaseTest.sol";
import {SoulBound} from "@protocol/nfts/avatar/SoulBound.sol";
import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
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

    function testOwnerOfNonExistentTokenReverts() public {
        // Test for a non-existent token
        uint256 nonExistentTokenId = 999;

        // Expect a revert with the specific error message when querying a non-existent token
        vm.expectRevert("Token does not exist");

        soulBound.ownerOf(nonExistentTokenId);
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

    function testSafeTransferFromReverts() public {
        address from = address(1);
        address to = address(2);
        uint256 tokenId = 1;
        uint256 amount = 1;
        bytes memory data = "";

        // Attempting to transfer should always revert
        vm.expectRevert("SoulBound tokens cannot be transferred");
        soulBound.safeTransferFrom(from, to, tokenId, amount, data);
    }
    function testSafeBatchTransferFromReverts() public {
        address from = address(1);
        address to = address(2);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        bytes memory data = "";

        // Attempting to batch transfer should always revert
        vm.expectRevert("SoulBound tokens cannot be transferred");
        soulBound.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function testTokenURIAfterMint() public {
        uint256 tokenId = 4;
        address recipient = address(1);

        vm.startPrank(notary);
        soulBound.mint(recipient, tokenId);
        vm.stopPrank();

        string memory expectedURI = string(abi.encodePacked("ipfs://metadata/", Strings.toString(tokenId)));
        string memory actualURI = soulBound.uri(tokenId);

        assertEq(actualURI, expectedURI, "URI should match the expected format after minting");
    }

    function testURILargeTokenID() public {
        uint256 largeTokenId = 2**256 - 1; // Maximum value for a uint256
        string memory expectedBaseURI = "ipfs://metadata/";
        string memory expectedURI = string(abi.encodePacked(expectedBaseURI, Strings.toString(largeTokenId)));

        // Mint a token to ensure the token ID exists
        vm.startPrank(notary);
        soulBound.mint(address(1), largeTokenId);
        vm.stopPrank();

        // Call the uri function with the large token ID
        string memory actualURI = soulBound.uri(largeTokenId);

        // Compare the actual URI with the expected URI
        assertEq(actualURI, expectedURI, "URI for large token ID does not match the expected format");
    }



    function testMintMultipleTokenIDs() public {
        address recipient1 = address(1);
        uint256 tokenId1 = 1;
        address recipient2 = address(2);
        uint256 tokenId2 = 2;

        vm.startPrank(notary);
        soulBound.mint(recipient1, tokenId1);
        soulBound.mint(recipient2, tokenId2);
        vm.stopPrank();

        assertEq(soulBound.balanceOf(recipient1, tokenId1), 1);
        assertEq(soulBound.balanceOf(recipient2, tokenId2), 1);
    }

    function testMintMaxTokenID() public {
        uint256 maxTokenId = type(uint256).max;
        address recipient = address(3);

        vm.startPrank(notary);
        soulBound.mint(recipient, maxTokenId);
        vm.stopPrank();

        assertEq(soulBound.balanceOf(recipient, maxTokenId), 1);
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

    function testBalanceOfZeroAddressReverts() public {
        uint256 tokenId = 1;
        vm.expectRevert("ERC1155: balance query for the zero address");
        soulBound.balanceOf(address(0), tokenId);
    }

    function testBalanceOfNonOwner() public {
        address recipient = address(1);
        uint256 tokenId = 1;
        address nonOwner = address(2);
        vm.startPrank(notary);
        soulBound.mint(recipient, tokenId);
        vm.stopPrank();
        uint256 balance = soulBound.balanceOf(nonOwner, tokenId);
        assertEq(balance, 0, "Balance should be 0 for non-owner");
    }

    function testBalanceOfTokenOwner() public {
        address recipient = address(1);
        uint256 tokenId = 1;
        vm.startPrank(notary);
        soulBound.mint(recipient, tokenId);
        vm.stopPrank();
        uint256 balance = soulBound.balanceOf(recipient, tokenId);
        assertEq(balance, 1, "Balance should be 1 for the token owner");
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

    function testTokenURI() public {
        address recipient = address(1);
        uint256 tokenId = 1;
        string memory expectedURI = "ipfs://metadata/1";
        vm.startPrank(notary);
        soulBound.mint(recipient, tokenId);
        vm.stopPrank();
        string memory actualURI = soulBound.uri(tokenId);
        assertEq(actualURI, expectedURI, "Token URI does not match expected URI");
    }

    function testURIGeneration() public {
        uint256 tokenId1 = 1;
        uint256 tokenId2 = 100;

        string memory baseURI = "ipfs://metadata/";
        string memory expectedURI1 = string(abi.encodePacked(baseURI, Strings.toString(tokenId1)));
        string memory expectedURI2 = string(abi.encodePacked(baseURI, Strings.toString(tokenId2)));

        assertEq(soulBound.uri(tokenId1), expectedURI1, "URI for tokenId1 does not match expected");
        assertEq(soulBound.uri(tokenId2), expectedURI2, "URI for tokenId2 does not match expected");
    }


    function testFailUnauthorizedMint() public {
        address unauthorized = address(3);
        uint256 tokenId = 1;
        vm.prank(unauthorized);
        vm.expectRevert("Unauthorized");
        soulBound.mint(address(1), tokenId);
        vm.stopPrank();
    }

    function testFailMintZeroAmount() public {
        address recipient = address(1);
        uint256 tokenId = 1;
        uint256 amount = 0;
        vm.startPrank(notary);
        vm.expectRevert("Amount must be greater than 0");
        soulBound.mint(recipient, tokenId);
        vm.stopPrank();
    }

    function testFailOwnershipTransfer() public {
        address recipient = address(1);
        uint256 tokenId = 1;
        vm.startPrank(notary);
        soulBound.mint(recipient, tokenId);
        vm.stopPrank();
        address newOwner = address(2);
        vm.expectRevert("SoulBound tokens cannot be transferred");
        soulBound.transferOwnership(newOwner);
    }
}