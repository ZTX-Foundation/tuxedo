pragma solidity ^0.8.0;

import {BaseTest} from "@test/BaseTest.sol";

import {PlayTest} from "@protocol/nfts/PlayTest.sol";

contract UnitTestPlayTest is BaseTest {
    /// @dev PlayTest
    PlayTest playTest;

    function setUp() public override {
        super.setUp();

        playTest = new PlayTest("PlayTest", "PLAY");
    }

    function testSafeMint() public {
        playTest.safeMint(address(1), "https://example.com");

        assertEq(playTest.balanceOf(address(1)), 1);
        assertEq(playTest.ownerOf(0), address(1));
        assertEq(playTest.tokenURI(0), "https://example.com");
    }

    function testAirdropNfts() public {
        address[] memory addresses = new address[](2);
        addresses[0] = address(1);
        addresses[1] = address(2);

        playTest.airdropNfts(addresses, "https://example.com");

        assertEq(playTest.balanceOf(address(1)), 1);
        assertEq(playTest.ownerOf(0), address(1));
        assertEq(playTest.tokenURI(0), "https://example.com");

        assertEq(playTest.balanceOf(address(2)), 1);
        assertEq(playTest.ownerOf(1), address(2));
        assertEq(playTest.tokenURI(1), "https://example.com");
    }

    function testSafeTransferFrom() public {
        playTest.safeMint(address(1), "https://example.com");

        vm.startPrank(address(1));
        playTest.approve(address(2), 0);
        vm.expectRevert("Computer says no; token not transferable");
        playTest.safeTransferFrom(address(1), address(2), 0);
        vm.stopPrank();

        assertEq(playTest.balanceOf(address(1)), 1);
        assertEq(playTest.ownerOf(0), address(1));
        assertEq(playTest.tokenURI(0), "https://example.com");
    }
}
