pragma solidity 0.8.18;

import {BaseTest} from "@test/BaseTest.sol";
import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";

import {JobRegistry} from "@protocol/nfts/JobRegistry.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

contract UnitTestJobRegistry is BaseTest {
    /// @dev JobRegistry
    JobRegistry jobRegistry;

    function setUp() public override {
        super.setUp();

        jobRegistry = new JobRegistry(address(core));
    }

    function testSetUp() public {
        assertEq(address(jobRegistry.core()), address(core));
        assertEq(address(nft.core()), address(core));
        assertEq("https://exampleUri.com/0", nft.uri(0));
        assertEq(nft.name(), "NFT");
        assertEq(nft.symbol(), "NFT");
        assertEq(nft.getMintAmountLeft(tokenId), supplyCap);
        assertEq(nft.totalSupply(tokenId), 0);
    }

    function testRegisterJobWithoutRoleFails() public {
        vm.expectRevert("CoreRef: no role on core");
        jobRegistry.registerJob(address(nft), 1, 1);
    }

    function testRegisterJobAsAdmin() public {
        vm.startPrank(addresses.adminAddress);
        jobRegistry.registerJob(address(nft), tokenId, 1);
        assertTrue(jobRegistry.isPending(address(nft), tokenId, 1));
        vm.stopPrank();
    }

    function testRegisterJobAsOperator() public {
        vm.startPrank(addresses.registryOperatorAddress);
        jobRegistry.registerJob(address(nft), tokenId, 1);
        assertTrue(jobRegistry.isPending(address(nft), tokenId, 1));
        vm.stopPrank();
    }

    function testRegisterJobDuplicate() public {
        vm.startPrank(addresses.adminAddress);
        jobRegistry.registerJob(address(nft), tokenId, 1);
        assertTrue(jobRegistry.isPending(address(nft), tokenId, 1));

        vm.expectRevert("JobRegistry: job is already pending");
        jobRegistry.registerJob(address(nft), tokenId, 1);
        vm.stopPrank();
    }

    function testRegisterJobSupplyExhausted() public {
        vm.startPrank(addresses.adminAddress);
        nft.setSupplyCap(tokenId, 1);

        jobRegistry.registerJob(address(nft), tokenId, 1);
        assertTrue(jobRegistry.isPending(address(nft), tokenId, 1));

        vm.expectRevert("JobRegistry: supply exhausted");
        jobRegistry.registerJob(address(nft), tokenId, 2);
        vm.stopPrank();
    }

    function testRegisterJobAlreadyCompleted() public {
        vm.startPrank(addresses.adminAddress);
        jobRegistry.registerJob(address(nft), tokenId, 1);
        assertTrue(jobRegistry.isPending(address(nft), tokenId, 1));

        jobRegistry.completeJob(address(nft), tokenId, 1);
        assertFalse(jobRegistry.isPending(address(nft), tokenId, 1));
        assertTrue(jobRegistry.isCompleted(address(nft), tokenId, 1));

        vm.expectRevert("JobRegistry: job is already completed");
        jobRegistry.registerJob(address(nft), tokenId, 1);
        vm.stopPrank();
    }

    function testRegisterJobRemainingSupply() public {
        vm.startPrank(addresses.adminAddress);
        jobRegistry.registerJob(address(nft), tokenId, 1);
        assertTrue(jobRegistry.isPending(address(nft), tokenId, 1));

        assertEq(nft.totalSupply(tokenId), 0);
        assertEq(jobRegistry.remainingSupplyOf(address(nft), tokenId), nft.maxTokenSupply(tokenId) - 1);
        vm.stopPrank();
    }
    
    function testCompleteJob() public {
        vm.startPrank(addresses.adminAddress);
        jobRegistry.registerJob(address(nft), tokenId, 1);
        assertTrue(jobRegistry.isPending(address(nft), tokenId, 1));

        jobRegistry.completeJob(address(nft), tokenId, 1);
        assertFalse(jobRegistry.isPending(address(nft), tokenId, 1));
        assertTrue(jobRegistry.isCompleted(address(nft), tokenId, 1));

        vm.stopPrank();
    }

    function testCompleteJobAlreadyCompleted() public {
        vm.startPrank(addresses.adminAddress);
        jobRegistry.registerJob(address(nft), tokenId, 1);
        assertTrue(jobRegistry.isPending(address(nft), tokenId, 1));

        jobRegistry.completeJob(address(nft), tokenId, 1);
        assertFalse(jobRegistry.isPending(address(nft), tokenId, 1));
        assertTrue(jobRegistry.isCompleted(address(nft), tokenId, 1));

        vm.expectRevert("JobRegistry: job is already completed");
        jobRegistry.completeJob(address(nft), tokenId, 1);
        vm.stopPrank();
    }

    function testCompleteJobSupplyExhausted() public {
        vm.startPrank(addresses.adminAddress);
        nft.setSupplyCap(tokenId, 1);

        jobRegistry.registerJob(address(nft), tokenId, 1);
        assertTrue(jobRegistry.isPending(address(nft), tokenId, 1));

        jobRegistry.completeJob(address(nft), tokenId, 1);
        assertFalse(jobRegistry.isPending(address(nft), tokenId, 1));
        assertTrue(jobRegistry.isCompleted(address(nft), tokenId, 1));

        vm.expectRevert("JobRegistry: supply exhausted");
        jobRegistry.registerJob(address(nft), tokenId, 2);
        vm.stopPrank();
    }

    function testCompleteJobRemainingSupply() public {
        vm.startPrank(addresses.adminAddress);
        jobRegistry.registerJob(address(nft), tokenId, 1);
        assertTrue(jobRegistry.isPending(address(nft), tokenId, 1));

        jobRegistry.completeJob(address(nft), tokenId, 1);
        assertFalse(jobRegistry.isPending(address(nft), tokenId, 1));
        assertTrue(jobRegistry.isCompleted(address(nft), tokenId, 1));

        assertEq(nft.totalSupply(tokenId), 0);
        assertEq(jobRegistry.remainingSupplyOf(address(nft), tokenId), nft.maxTokenSupply(tokenId) - 1);
        vm.stopPrank();
    }
}
