pragma solidity 0.8.18;

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {ERC1155AdminMinter} from "@protocol/nfts/ERC1155AdminMinter.sol";
import {BaseTest} from "@test/integration/BaseTest.sol";

contract IntegrationTestERC1155AdminMinter is BaseTest {
    address multisig;
    address recipient = address(0x108);
    ERC1155MaxSupplyMintable erc1155Wearables;
    ERC1155AdminMinter erc1155AdminMinter;

    function setUp() public override {
        super.setUp();

        multisig = addresses.getAddress("ADMIN_MULTISIG");
        erc1155Wearables = ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES"));
        erc1155AdminMinter = ERC1155AdminMinter(addresses.getAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTER"));
    }

    function testSetSupplyCap() public {
        /// set supply cap
        vm.prank(multisig);
        erc1155Wearables.setSupplyCap(108, 10_000);
        assertEq(erc1155Wearables.maxTokenSupply(108), 10_000);
    }

    function testMintSuccess() public {
        /// set supply cap
        vm.prank(multisig);
        erc1155Wearables.setSupplyCap(108, 10_000);
        assertEq(erc1155Wearables.maxTokenSupply(108), 10_000);

        /// mint
        vm.prank(multisig);
        erc1155AdminMinter.mintToken(address(erc1155Wearables), recipient, 108, 10_000);
        assertEq(erc1155Wearables.balanceOf(recipient, 108), 10_000);
    }

    function testbulkMintTokensSuccess() public {
        /// set supply cap
        vm.startPrank(multisig);
        erc1155Wearables.setSupplyCap(106, 10_000);
        erc1155Wearables.setSupplyCap(108, 10_000);
        assertEq(erc1155Wearables.maxTokenSupply(106), 10_000);
        assertEq(erc1155Wearables.maxTokenSupply(108), 10_000);
        vm.stopPrank();

        ERC1155AdminMinter.BulkMint[] memory toMint = new ERC1155AdminMinter.BulkMint[](2);
        toMint[0] = ERC1155AdminMinter.BulkMint(address(erc1155Wearables), 106, 10_000, recipient);
        toMint[1] = ERC1155AdminMinter.BulkMint(address(erc1155Wearables), 108, 10_000, recipient);

        /// bulkMintTokens
        vm.prank(multisig);
        erc1155AdminMinter.bulkMintTokens(toMint);

        // assert
        assertEq(erc1155Wearables.balanceOf(recipient, 106), 10_000);
        assertEq(erc1155Wearables.balanceOf(recipient, 108), 10_000);
    }

    function testMintFailedNoSupply() public {
        /// mint
        vm.prank(multisig);
        vm.expectRevert("BaseERC1155NFT: supply exceeded");
        erc1155AdminMinter.mintToken(address(erc1155Wearables), recipient, 108, 10_000);
    }

    function testBulkMintTokensFailNoSupply() public {
        ERC1155AdminMinter.BulkMint[] memory toMint = new ERC1155AdminMinter.BulkMint[](2);
        toMint[0] = ERC1155AdminMinter.BulkMint(address(erc1155Wearables), 106, 10_000, recipient);
        toMint[1] = ERC1155AdminMinter.BulkMint(address(erc1155Wearables), 108, 10_000, recipient);

        /// bulkMintTokens
        vm.prank(multisig);
        vm.expectRevert("BaseERC1155NFT: supply exceeded");
        erc1155AdminMinter.bulkMintTokens(toMint);
    }

    function testMintFailOverSupplyLimit() public {
        /// mint
        vm.prank(multisig);
        vm.expectRevert("BaseERC1155NFT: supply exceeded");
        erc1155AdminMinter.mintToken(address(erc1155Wearables), recipient, 108, 100_000);
    }

    function testBulkMintTokenFailOverSupplyLimit() public {
        /// set supply cap
        vm.startPrank(multisig);
        erc1155Wearables.setSupplyCap(106, 10_000);
        erc1155Wearables.setSupplyCap(108, 10_000);
        assertEq(erc1155Wearables.maxTokenSupply(106), 10_000);
        assertEq(erc1155Wearables.maxTokenSupply(108), 10_000);
        vm.stopPrank();

        ERC1155AdminMinter.BulkMint[] memory toMint = new ERC1155AdminMinter.BulkMint[](2);
        toMint[0] = ERC1155AdminMinter.BulkMint(address(erc1155Wearables), 106, 20_000, recipient);
        toMint[1] = ERC1155AdminMinter.BulkMint(address(erc1155Wearables), 108, 20_000, recipient);

        /// bulkMintTokens
        vm.prank(multisig);
        vm.expectRevert("BaseERC1155NFT: supply exceeded");
        erc1155AdminMinter.bulkMintTokens(toMint);
    }

    function testMintFailNonAdminCaller() public {
        /// mint
        vm.expectRevert("CoreRef: no role on core");
        erc1155AdminMinter.mintToken(address(erc1155Wearables), recipient, 108, 10_000);
    }

    function testBulkMintTokenFailNonAdminCaller() public {
        /// set supply cap
        vm.startPrank(multisig);
        erc1155Wearables.setSupplyCap(106, 10_000);
        erc1155Wearables.setSupplyCap(108, 10_000);
        assertEq(erc1155Wearables.maxTokenSupply(106), 10_000);
        assertEq(erc1155Wearables.maxTokenSupply(108), 10_000);
        vm.stopPrank();

        ERC1155AdminMinter.BulkMint[] memory toMint = new ERC1155AdminMinter.BulkMint[](2);
        toMint[0] = ERC1155AdminMinter.BulkMint(address(erc1155Wearables), 106, 20_000, recipient);
        toMint[1] = ERC1155AdminMinter.BulkMint(address(erc1155Wearables), 108, 20_000, recipient);

        /// bulkMintTokens
        vm.expectRevert("CoreRef: no role on core");
        erc1155AdminMinter.bulkMintTokens(toMint);
    }

    function testMintFailWhenPaused() public {
        /// set supply cap
        vm.prank(multisig);
        erc1155Wearables.setSupplyCap(108, 10_000);
        assertEq(erc1155Wearables.maxTokenSupply(108), 10_000);

        /// pause
        vm.prank(multisig);
        erc1155Wearables.pause();

        /// mint
        vm.prank(multisig);
        vm.expectRevert("Pausable: paused");
        erc1155AdminMinter.mintToken(address(erc1155Wearables), recipient, 108, 10_000);
    }

    function testBulkMintTokenFailWhenPaused() public {
        /// set supply cap
        vm.startPrank(multisig);
        erc1155Wearables.setSupplyCap(106, 10_000);
        erc1155Wearables.setSupplyCap(108, 10_000);
        assertEq(erc1155Wearables.maxTokenSupply(106), 10_000);
        assertEq(erc1155Wearables.maxTokenSupply(108), 10_000);
        vm.stopPrank();

        ERC1155AdminMinter.BulkMint[] memory toMint = new ERC1155AdminMinter.BulkMint[](2);
        toMint[0] = ERC1155AdminMinter.BulkMint(address(erc1155Wearables), 106, 20_000, recipient);
        toMint[1] = ERC1155AdminMinter.BulkMint(address(erc1155Wearables), 108, 20_000, recipient);

        /// pause
        vm.prank(multisig);
        erc1155Wearables.pause();

        /// bulkMintTokens
        vm.prank(multisig);
        vm.expectRevert("Pausable: paused");
        erc1155AdminMinter.bulkMintTokens(toMint);
    }
}
