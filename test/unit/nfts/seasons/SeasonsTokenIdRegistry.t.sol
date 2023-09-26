pragma solidity 0.8.18;

import {BaseTest} from "@test/BaseTest.sol";
import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {SeasonsTokenIdRegistry} from "@protocol/nfts/seasons/SeasonsTokenIdRegistry.sol";

contract UnitTestSeasonsTokenIdRegistry is BaseTest {
    SeasonsTokenIdRegistry private _registry;

    function setUp() public override {
        super.setUp();

        _registry = new SeasonsTokenIdRegistry(address(core));
    }

    function testRegister() public {
        assertEq(_registry.tokenIdSeasonContract(0), address(0x0)); // not registered

        vm.expectRevert("CoreRef: no role on core");
        _registry.register(0, address(0x123));

        vm.prank(addresses.registryOperatorAddress);
        _registry.register(0, address(0x123));
        assertEq(_registry.tokenIdSeasonContract(0), address(0x123));

        vm.expectRevert("SeasonsTokenIdRegistry: tokenId already registered to a Season Contract");
        vm.prank(addresses.registryOperatorAddress);
        _registry.register(0, address(0x123));
    }
}
