pragma solidity 0.8.18;

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {BaseTest} from "@test/integration/BaseTest.sol";

contract IntegrationTestWearableTokenDropPostDeployment is BaseTest {
    address multisig;
    address recipient = address(0x108);
    ERC1155MaxSupplyMintable erc1155Wearables;

    function setUp() public override {
        super.setUp();

        multisig = addresses.getAddress("ADMIN_MULTISIG");
        erc1155Wearables = ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES"));
    }

    function testMultisigSetTokenSupplyCapAndMint() public {
        /// set supply cap
        vm.prank(multisig);
        erc1155Wearables.setSupplyCap(108, 10_000);

        assertEq(erc1155Wearables.maxTokenSupply(108), 10_000);

        /// mint
        vm.prank(multisig);
        erc1155Wearables.airDropMint(recipient, 108, 10_000);

        assertEq(erc1155Wearables.balanceOf(recipient, 108), 10_000);
    }
}
