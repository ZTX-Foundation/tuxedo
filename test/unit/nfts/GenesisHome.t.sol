pragma solidity 0.8.18;

import {BaseTest} from "@test/BaseTest.sol";

import {GenesisHome} from "@protocol/nfts/GenesisHome.sol";

contract UnitTestGenesisHome is BaseTest {
    /// @dev GenesisHome
    GenesisHome genesisHome;

    function setUp() public override {
        super.setUp();

        genesisHome = new GenesisHome("ZTX Genesis Home", "ZTXGH");
    }

    function testSafeMint() public {
        genesisHome.safeMint(vm.addr(1), "https://example.com");

        assertEq(genesisHome.balanceOf(vm.addr(1)), 1);
        assertEq(genesisHome.ownerOf(0), vm.addr(1));
        assertEq(genesisHome.tokenURI(0), "https://example.com");
    }

    function testSafeTransferFrom() public {
        genesisHome.safeMint(vm.addr(1), "https://example.com");

        vm.startPrank(vm.addr(1));
        genesisHome.approve(vm.addr(2), 0);
        genesisHome.safeTransferFrom(vm.addr(1), vm.addr(2), 0);
        vm.stopPrank();

        assertEq(genesisHome.balanceOf(vm.addr(1)), 0);
        assertEq(genesisHome.balanceOf(vm.addr(2)), 1);
        assertEq(genesisHome.ownerOf(0), vm.addr(2));
        assertEq(genesisHome.tokenURI(0), "https://example.com");
    }
}
