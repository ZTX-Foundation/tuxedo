pragma solidity 0.8.18;

import "@forge-std/Test.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {BaseTest} from "@test/BaseTest.sol";
import {ERC1155AdminMinter} from "@protocol/nfts/ERC1155AdminMinter.sol";
import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";
import {getSystem, configureSale, setSupplyCap} from "@test/fixtures/Fixtures.sol";

contract UnitTestERC1155AdminMinter is BaseTest {
    ERC1155AdminMinter minter;
    uint256 public constant amountToMint = 1_000;

    function setUp() public virtual override {
        super.setUp();

        minter = new ERC1155AdminMinter(address(core));

        vm.startPrank(addresses.adminAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, address(minter));
        core.grantRole(Roles.MINTER_PROTOCOL_ROLE, address(minter));
        vm.stopPrank();
    }

    function testSetup() public {
        assertEq(address(minter.core()), address(core));
    }

    /// ACL TESTS

    function testMintTokenFailsNonAdmin(address user) public {
        vm.assume(user != addresses.adminAddress);
        vm.prank(user);

        vm.expectRevert("CoreRef: no role on core");
        minter.mintToken(address(nft), proceedsRecipient, tokenId, amountToMint);
    }

    function testBulkMintTokenFailsNonAdmin(address user) public {
        vm.assume(user != addresses.adminAddress);

        ERC1155AdminMinter.BulkMint[] memory params = new ERC1155AdminMinter.BulkMint[](1);

        vm.prank(user);
        vm.expectRevert("CoreRef: no role on core");
        minter.bulkMintTokens(params);
    }

    function testMintSucceeds() public {
        uint256 startingSupply = nft.totalSupply(tokenId);
        uint256 startingBalance = nft.balanceOf(proceedsRecipient, tokenId);

        vm.prank(addresses.adminAddress);
        minter.mintToken(address(nft), proceedsRecipient, tokenId, amountToMint);

        assertEq(nft.balanceOf(proceedsRecipient, tokenId), amountToMint + startingBalance);
        assertEq(nft.totalSupply(tokenId), startingSupply + amountToMint);
    }

    function testBulkMintSucceeds() public {
        uint256 startingBalance = nft.balanceOf(proceedsRecipient, tokenId);
        uint256 startingSupply = nft.totalSupply(tokenId);

        ERC1155AdminMinter.BulkMint[] memory params = new ERC1155AdminMinter.BulkMint[](3);
        params[0].nftContract = address(nft);
        params[0].recipient = proceedsRecipient;
        params[0].tokenId = tokenId;
        params[0].amount = amountToMint;

        params[1].nftContract = address(nft);
        params[1].recipient = proceedsRecipient;
        params[1].tokenId = tokenId;
        params[1].amount = amountToMint;

        params[2].nftContract = address(nft);
        params[2].recipient = proceedsRecipient;
        params[2].tokenId = tokenId;
        params[2].amount = amountToMint;

        vm.prank(addresses.adminAddress);
        minter.bulkMintTokens(params);

        assertEq(nft.balanceOf(proceedsRecipient, tokenId), startingBalance + (amountToMint * 3));
        assertEq(nft.totalSupply(tokenId), startingSupply + amountToMint * 3);
    }

    function testCanMintThenBulkMint() public {
        testMintSucceeds();
        testBulkMintSucceeds();
    }
}
