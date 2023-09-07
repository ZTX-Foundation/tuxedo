pragma solidity 0.8.18;

import "@test/BaseTest.sol";
import {SingleFunctionReentrancy} from "@test/mock/SingleFunctionReentrancy.sol";
import {CrossFunctionReentrancy} from "@test/mock/CrossFunctionReentrancy.sol";

contract UnitTestERC1155Reentrancy is BaseTest {

    SingleFunctionReentrancy public receiver;
    CrossFunctionReentrancy public cReceiver;

    function setUp() public override {
        super.setUp();
        vm.prank(addresses.adminAddress);
        sale.setTokenConfig(tokenId, address(token), uint96(block.timestamp + 1), tokenPrice, fee, true, bytes32(0));
        vm.warp(block.timestamp + 1);

        receiver = new SingleFunctionReentrancy(sale, address(token));
        cReceiver = new CrossFunctionReentrancy(sale, address(token), address(nft));
    }

    function testSetup() public {
        assertEq(address(receiver.sale()), address(sale));
        assertTrue(!receiver.isBuying());
        assertEq(token.allowance(address(receiver), address(sale)), type(uint256).max);
    }

    function testSingleFunctionReentrancyFails() public {
        (uint256 total, , ) = sale.getPurchasePrice(tokenId, supplyCap);

        token.mint(address(receiver), total);

        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        receiver.purchaseTokens(tokenId, supplyCap);
    }
    
    function testCrossFunctionReentrancySucceeds() public {
        (uint256 total, , ) = sale.getPurchasePrice(tokenId, supplyCap);
    
        token.mint(address(cReceiver), total);
    
        cReceiver.purchaseTokens(tokenId, supplyCap);

        assertEq(nft.balanceOf(address(1), tokenId), supplyCap);
        assertEq(nft.totalSupply(tokenId), supplyCap);
    }
    
    function testCrossFunctionReentrancySucceedsMintBatch() public {
        vm.prank(address(sale));
        lock.lock(1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = supplyCap;

        vm.prank(addresses.minterAddress);
        nft.mintBatch(address(cReceiver), tokenIds, amounts);
    
        assertEq(nft.balanceOf(address(1), tokenId), supplyCap);
        assertEq(nft.totalSupply(tokenId), supplyCap);
    }
    
    function testCrossFunctionReentrancySucceedsMintBatchMultiIds() public {
        uint256 tokenIdTwo = tokenId + 1;
        setSupplyCap(vm, nft, tokenIdTwo, supplyCap);

        vm.prank(address(sale));
        lock.lock(1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = tokenId;
        tokenIds[1] = tokenIdTwo;
    
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = supplyCap;
        amounts[1] = supplyCap;

        vm.prank(addresses.minterAddress);
        nft.mintBatch(address(cReceiver), tokenIds, amounts);
    
        assertEq(nft.balanceOf(address(1), tokenId), supplyCap);
        assertEq(nft.totalSupply(tokenId), supplyCap);

        assertEq(nft.balanceOf(address(1), tokenIdTwo), supplyCap);
        assertEq(nft.totalSupply(tokenIdTwo), supplyCap);
    }

    function testBatchMintReentrancyFails() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        vm.prank(addresses.minterAddress);
        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        nft.mintBatch(address(receiver), tokenIds, amounts);
    }
}
