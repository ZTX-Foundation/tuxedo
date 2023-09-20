pragma solidity 0.8.18;

import "forge-std/console.sol";

import {BaseTest} from "@test/BaseTest.sol";

import {SeasonsTokenIdRegistry} from "@protocol/nfts/seasons/SeasonsTokenIdRegistry.sol";

contract UnitTestSeasonsTokenIdRegistry is BaseTest {
    SeasonsTokenIdRegistry private _registry;

    function setUp() public override {
        super.setUp();

        _registry = new SeasonsTokenIdRegistry(address(core));
    }

    // TODO added permission testing
    function testRegister() public {
        assertEq(_registry.tokenIdSeasonContract(0), address(0x0)); // not registered

        _registry.register(0, address(0x123));
        assertEq(_registry.tokenIdSeasonContract(0), address(0x123));

        vm.expectRevert("SeasonsTokenIdRegistry: tokenId already registered to a Season Contract");
        _registry.register(0, address(0x123));
    }
}
