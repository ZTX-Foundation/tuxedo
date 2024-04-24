pragma solidity 0.8.18;

import {BaseTest} from "@test/BaseTest.sol";
import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";

import {MaxSupplyEnforcer} from "@protocol/nfts/MaxSupplyEnforcer.sol";
import {MaxSupplyEnforcerDeploy} from "@protocol/nfts/MaxSupplyEnforcerDeploy.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

contract UnitTestMaxSupplyEnforcer is BaseTest {
    /// @dev MaxSupplyEnforcer
    MaxSupplyEnforcer maxSupplyEnforcer;

    function setUp() public override {
        super.setUp();
        MaxSupplyEnforcerDeploy maxSupplyEnforcerDeployer = new MaxSupplyEnforcerDeploy();
        (address proxy, address maxSupplyEnforcerImpl) = maxSupplyEnforcerDeployer.deployMaxSupplyEnforcer(addresses.safeAddress);

        maxSupplyEnforcerDeployer.initializeMaxSupplyEnforcer(proxy, address(core));

        maxSupplyEnforcer = MaxSupplyEnforcer(proxy);
    }

    function testSetUp() public {
        assertEq(address(maxSupplyEnforcer.core()), address(core));
        assertEq(address(nft.core()), address(core));
        assertEq("https://exampleUri.com/0", nft.uri(0));
        assertEq(nft.name(), "NFT");
        assertEq(nft.symbol(), "NFT");
        assertEq(nft.getMintAmountLeft(tokenId), supplyCap);
        assertEq(nft.totalSupply(tokenId), 0);
    }

    function testRegisterJobWithoutRoleFails() public {
        vm.expectRevert("CoreRef: no role on core");
        maxSupplyEnforcer.registerJob(address(nft), 1, 1);
    }

    function testRegisterJobAsAdmin() public {
        vm.startPrank(addresses.adminAddress);
        maxSupplyEnforcer.registerJob(address(nft), tokenId, 1);
        assertTrue(maxSupplyEnforcer.isPending(address(nft), tokenId, 1));
        vm.stopPrank();
    }

    function testRegisterJobAsOperator() public {
        vm.startPrank(addresses.registryOperatorAddress);
        maxSupplyEnforcer.registerJob(address(nft), tokenId, 1);
        assertTrue(maxSupplyEnforcer.isPending(address(nft), tokenId, 1));
        vm.stopPrank();
    }

    function testRegisterJobDuplicate() public {
        vm.startPrank(addresses.adminAddress);
        maxSupplyEnforcer.registerJob(address(nft), tokenId, 1);
        assertTrue(maxSupplyEnforcer.isPending(address(nft), tokenId, 1));

        vm.expectRevert("MaxSupplyEnforcer: job is already pending");
        maxSupplyEnforcer.registerJob(address(nft), tokenId, 1);
        vm.stopPrank();
    }

    function testRegisterJobSupplyExhausted() public {
        vm.startPrank(addresses.adminAddress);
        nft.setSupplyCap(tokenId, 1);

        maxSupplyEnforcer.registerJob(address(nft), tokenId, 1);
        assertTrue(maxSupplyEnforcer.isPending(address(nft), tokenId, 1));

        vm.expectRevert("MaxSupplyEnforcer: supply exhausted");
        maxSupplyEnforcer.registerJob(address(nft), tokenId, 2);
        vm.stopPrank();
    }

    function testRegisterJobAlreadyCompleted() public {
        vm.startPrank(addresses.adminAddress);
        maxSupplyEnforcer.registerJob(address(nft), tokenId, 1);
        assertTrue(maxSupplyEnforcer.isPending(address(nft), tokenId, 1));

        maxSupplyEnforcer.completeJob(address(nft), tokenId, 1);
        assertFalse(maxSupplyEnforcer.isPending(address(nft), tokenId, 1));
        assertTrue(maxSupplyEnforcer.isCompleted(address(nft), tokenId, 1));

        vm.expectRevert("MaxSupplyEnforcer: job is already completed");
        maxSupplyEnforcer.registerJob(address(nft), tokenId, 1);
        vm.stopPrank();
    }

    function testRegisterJobRemainingSupply() public {
        vm.startPrank(addresses.adminAddress);
        maxSupplyEnforcer.registerJob(address(nft), tokenId, 1);
        assertTrue(maxSupplyEnforcer.isPending(address(nft), tokenId, 1));

        assertEq(nft.totalSupply(tokenId), 0);
        assertEq(maxSupplyEnforcer.remainingSupplyOf(address(nft), tokenId), nft.maxTokenSupply(tokenId) - 1);
        vm.stopPrank();
    }
    
    function testCompleteJob() public {
        vm.startPrank(addresses.adminAddress);
        maxSupplyEnforcer.registerJob(address(nft), tokenId, 1);
        assertTrue(maxSupplyEnforcer.isPending(address(nft), tokenId, 1));

        maxSupplyEnforcer.completeJob(address(nft), tokenId, 1);
        assertFalse(maxSupplyEnforcer.isPending(address(nft), tokenId, 1));
        assertTrue(maxSupplyEnforcer.isCompleted(address(nft), tokenId, 1));

        vm.stopPrank();
    }

    function testCompleteJobAlreadyCompleted() public {
        vm.startPrank(addresses.adminAddress);
        maxSupplyEnforcer.registerJob(address(nft), tokenId, 1);
        assertTrue(maxSupplyEnforcer.isPending(address(nft), tokenId, 1));

        maxSupplyEnforcer.completeJob(address(nft), tokenId, 1);
        assertFalse(maxSupplyEnforcer.isPending(address(nft), tokenId, 1));
        assertTrue(maxSupplyEnforcer.isCompleted(address(nft), tokenId, 1));

        vm.expectRevert("MaxSupplyEnforcer: job is already completed");
        maxSupplyEnforcer.completeJob(address(nft), tokenId, 1);
        vm.stopPrank();
    }

    function testCompleteJobSupplyExhausted() public {
        vm.startPrank(addresses.adminAddress);
        nft.setSupplyCap(tokenId, 1);

        maxSupplyEnforcer.registerJob(address(nft), tokenId, 1);
        assertTrue(maxSupplyEnforcer.isPending(address(nft), tokenId, 1));

        maxSupplyEnforcer.completeJob(address(nft), tokenId, 1);
        assertFalse(maxSupplyEnforcer.isPending(address(nft), tokenId, 1));
        assertTrue(maxSupplyEnforcer.isCompleted(address(nft), tokenId, 1));

        vm.expectRevert("MaxSupplyEnforcer: supply exhausted");
        maxSupplyEnforcer.registerJob(address(nft), tokenId, 2);
        vm.stopPrank();
    }

    function testCompleteJobRemainingSupply() public {
        vm.startPrank(addresses.adminAddress);
        maxSupplyEnforcer.registerJob(address(nft), tokenId, 1);
        assertTrue(maxSupplyEnforcer.isPending(address(nft), tokenId, 1));

        maxSupplyEnforcer.completeJob(address(nft), tokenId, 1);
        assertFalse(maxSupplyEnforcer.isPending(address(nft), tokenId, 1));
        assertTrue(maxSupplyEnforcer.isCompleted(address(nft), tokenId, 1));

        assertEq(nft.totalSupply(tokenId), 0);
        assertEq(maxSupplyEnforcer.remainingSupplyOf(address(nft), tokenId), nft.maxTokenSupply(tokenId) - 1);
        vm.stopPrank();
    }
}
