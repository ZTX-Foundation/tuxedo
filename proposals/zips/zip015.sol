//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";
import {TimelockProposal} from "@proposals/proposalTypes/TimelockProposal.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {Token} from "@protocol/token/Token.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {ERC1155Sale} from "@protocol/sale/ERC1155Sale.sol";
import {ERC20Splitter} from "@protocol/finance/ERC20Splitter.sol";

contract zip015 is TimelockProposal {
    Core private _core;

    constructor() Proposal("ADMIN_TIMELOCK_CONTROLLER") {}

    // Returns the name of the proposal.
    function name() public pure override returns (string memory) {
        return "ZIP015";
    }

    // Provides a brief description of the proposal.
    function description() public pure override returns (string memory) {
        return "The ZTX marketplace sale conracts";
    }

    function _beforeDeploy() internal override {
        _core = Core(addresses.getAddress("CORE"));
    }

    function _deploy() internal override {
        /// ERC1155Sale
        ERC1155Sale consumablesERC1155Sale = new ERC1155Sale(
            address(_core),
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES"),
            addresses.getAddress("WETH")
        );
        addresses.addAddress("ERC1155_SALE_CONSUMABLES", address(consumablesERC1155Sale), true);

        ERC1155Sale placeablesERC1155Sale = new ERC1155Sale(
            address(_core),
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
            addresses.getAddress("WETH")
        );
        addresses.addAddress("ERC1155_SALE_PLACEABLES", address(placeablesERC1155Sale), true);

        ERC1155Sale wearablesERC1155Sale = new ERC1155Sale(
            address(_core),
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES"),
            addresses.getAddress("WETH")
        );
        addresses.addAddress("ERC1155_SALE_WEARABLES", address(wearablesERC1155Sale), true);

        /// @dev configure the proceeds
        ERC1155Sale(addresses.getAddress("ERC1155_SALE_CONSUMABLES")).setTokenRecipients(
            addresses.getAddress("TOKEN"),
            addresses.getAddress("REVENUE_WALLET_MULTISIG01"),
            addresses.getAddress("REVENUE_WALLET_MULTISIG02")
        );

        ERC1155Sale(addresses.getAddress("ERC1155_SALE_PLACEABLES")).setTokenRecipients(
            addresses.getAddress("TOKEN"),
            addresses.getAddress("REVENUE_WALLET_MULTISIG01"),
            addresses.getAddress("REVENUE_WALLET_MULTISIG02")
        );

        ERC1155Sale(addresses.getAddress("ERC1155_SALE_WEARABLES")).setTokenRecipients(
            addresses.getAddress("TOKEN"),
            addresses.getAddress("REVENUE_WALLET_MULTISIG01"),
            addresses.getAddress("REVENUE_WALLET_MULTISIG02")
        );
    }

    function _afterDeploy() internal override {
        /// LOCKER role
        _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_SALE_CONSUMABLES"));
        _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_SALE_PLACEABLES"));
        _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_SALE_WEARABLES"));

        /// MINTER role
        _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_SALE_CONSUMABLES"));
        _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_SALE_PLACEABLES"));
        _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_SALE_WEARABLES"));
    }

    function _validate() internal override {
        assertEq(
            address(ERC1155Sale(addresses.getAddress("ERC1155_SALE_CONSUMABLES")).core()),
            address(_core),
            "ERC1155Sale core address is not equal to core address"
        );
        assertEq(
            address(ERC1155Sale(addresses.getAddress("ERC1155_SALE_WEARABLES")).core()),
            address(_core),
            "ERC1155Sale core address is not equal to core address"
        );
        assertEq(
            address(ERC1155Sale(addresses.getAddress("ERC1155_SALE_PLACEABLES")).core()),
            address(_core),
            "ERC1155Sale core address is not equal to core address"
        );
    }
}
