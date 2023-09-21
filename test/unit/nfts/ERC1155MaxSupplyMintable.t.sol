pragma solidity 0.8.18;

import "@test/BaseTest.sol";

contract UnitTestERC1155MaxSupplyMintable is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function testSetup() public {
        assertEq(address(nft.core()), address(core));
        assertEq("https://exampleUri.com/0", nft.uri(0));
        assertEq(nft.name(), "NFT");
        assertEq(nft.symbol(), "NFT");
        assertEq(nft.getMintAmountLeft(tokenId), supplyCap);
        assertEq(nft.totalSupply(tokenId), 0);
    }

    /// ACL Tests

    function testMintWithoutRoleFails() public {
        vm.expectRevert("CoreRef: no role on core");
        nft.mint(address(this), tokenId, 100);
    }

    function testMintBatchWithoutRoleFails() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        vm.expectRevert("CoreRef: no role on core");
        nft.mintBatch(address(this), tokenIds, amounts);
    }
    
    function testSetURIWithoutRoleFails() public {
        vm.expectRevert("CoreRef: no role on core");
        nft.setURI("https://exampleUri1.com/");
    }
    
    function testSetURIWithRoleSucceeds() public {
        vm.prank(addresses.adminAddress);
        nft.setURI("https://exampleUri1.com/");
        assertEq("https://exampleUri1.com/0", nft.uri(0));
    }

    function testSetTokenSupplyCapWithoutRoleFails() public {
        vm.expectRevert("CoreRef: no role on core");
        nft.setSupplyCap(tokenId, supplyCap);
    }

    function testSetTokenSupplyCapWithRoleSucceeds() public {
        vm.prank(addresses.adminAddress);
        nft.setSupplyCap(tokenId + 1, supplyCap);

        assertEq(nft.getMintAmountLeft(tokenId + 1), supplyCap);
        assertEq(nft.maxTokenSupply(tokenId + 1), supplyCap);
    }

    function testSetTokenSupplyCapUnderSupplyFails() public {
        testMintSucceedsMinter(10_000);

        vm.expectRevert("BaseERC1155NFT: maxSupply cannot be less than current supply");
        vm.prank(addresses.adminAddress);
        nft.setSupplyCap(tokenId, supplyCap - 1);
    }

    function testPauseWithoutRoleFails() public {
        vm.expectRevert("UNAUTHORIZED");
        nft.pause();
    }

    /// pause tests
    function testMintFailsWhenPaused() public {
        vm.prank(addresses.adminAddress);
        nft.pause();

        vm.prank(addresses.minterAddress);
        vm.expectRevert("Pausable: paused");
        nft.mint(address(this), tokenId, 100);
    }

    function testMintBatchFailsWhenPaused() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        vm.prank(addresses.adminAddress);
        nft.pause();

        vm.prank(addresses.minterAddress);
        vm.expectRevert("Pausable: paused");
        nft.mintBatch(address(this), tokenIds, amounts);
    }

    function testMintSucceedsMinter(uint16 amount) public {
        vm.assume(amount <= supplyCap);

        /// lock up to level 1 as sale contract
        vm.prank(address(sale));
        lock.lock(1);

        vm.prank(addresses.minterAddress);
        nft.mint(address(this), tokenId, amount);

        assertEq(nft.balanceOf(address(this), tokenId), amount);
        assertEq(nft.totalSupply(tokenId), amount);
        assertEq(nft.getMintAmountLeft(tokenId), supplyCap - amount);
    }

    function testMintBatchSucceedsMinter() public {
        testSetTokenSupplyCapWithRoleSucceeds();
        uint256 amount = 100;

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = tokenId;
        tokenIds[1] = tokenId + 1;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        amounts[1] = amount;

        /// lock up to level 1
        vm.prank(address(sale));
        lock.lock(1);

        vm.prank(addresses.minterAddress);
        nft.mintBatch(address(this), tokenIds, amounts);

        assertEq(nft.balanceOf(address(this), tokenId), amount);
        assertEq(nft.balanceOf(address(this), tokenId + 1), amount);
        assertEq(nft.totalSupply(tokenId), amount);
        assertEq(nft.totalSupply(tokenId + 1), amount);
        assertEq(nft.getMintAmountLeft(tokenId), supplyCap - amount);
        assertEq(nft.getMintAmountLeft(tokenId + 1), supplyCap - amount);
    }

    function testMintBatchAboveSupplyCapFails() public {
        uint256 amount = 4_000;

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = tokenId;
        tokenIds[1] = tokenId;
        tokenIds[2] = tokenId;
        
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = amount;
        amounts[1] = amount;
        amounts[2] = amount;

        /// lock up to level 1
        vm.prank(address(sale));
        lock.lock(1);

        vm.expectRevert("BaseERC1155NFT: supply exceeded");
        vm.prank(addresses.minterAddress);
        nft.mintBatch(address(this), tokenIds, amounts);
    }

    function testMintAboveSupplyCapFails() public {
        uint256 amount = 10_001;

        /// lock up to level 1
        vm.prank(address(sale));
        lock.lock(1);

        vm.expectRevert("BaseERC1155NFT: supply exceeded");
        vm.prank(addresses.minterAddress);
        nft.mint(address(this), tokenId, amount);        
    }

    function testBurnDecreasesSupply() public {
        testMintBatchSucceedsMinter();

        nft.burn(address(this), tokenId, nft.balanceOf(address(this), tokenId));
        nft.burn(address(this), tokenId + 1, nft.balanceOf(address(this), tokenId + 1));

        assertEq(nft.balanceOf(address(this), tokenId), 0);
        assertEq(nft.balanceOf(address(this), tokenId + 1), 0);
        assertEq(nft.totalSupply(tokenId), 0);
        assertEq(nft.totalSupply(tokenId + 1), 0);
        assertEq(nft.getMintAmountLeft(tokenId), supplyCap);
        assertEq(nft.getMintAmountLeft(tokenId + 1), supplyCap);
    }

    function testBurnBatchDecreasesSupply() public {
        testMintBatchSucceedsMinter();
        uint256 amount = 100;

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = tokenId;
        tokenIds[1] = tokenId + 1;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        amounts[1] = amount;

        nft.burnBatch(address(this), tokenIds, amounts);

        assertEq(nft.balanceOf(address(this), tokenId), 0);
        assertEq(nft.balanceOf(address(this), tokenId + 1), 0);
        assertEq(nft.totalSupply(tokenId), 0);
        assertEq(nft.totalSupply(tokenId + 1), 0);
        assertEq(nft.getMintAmountLeft(tokenId), supplyCap);
        assertEq(nft.getMintAmountLeft(tokenId + 1), supplyCap);
    }

    function testSendTokensToContractFails() public {
        testMintSucceedsMinter(10_000);

        vm.expectRevert("ERC1155: transfer to non-ERC1155Receiver implementer");
        nft.safeTransferFrom(address(this), address(nft), tokenId, 1, "");
    }

    function testNotLockedMintFails() public {
        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        vm.prank(addresses.minterAddress);
        nft.mint(address(this), tokenId, supplyCap);
    }

    function testNotLockedBatchMintFails() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = supplyCap;

        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        vm.prank(addresses.minterAddress);
        nft.mintBatch(address(this), tokenIds, amounts);
    }
}
