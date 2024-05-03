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

        /// ERC20Splitter allocation settings
        ERC20Splitter.Allocation[] memory allocations = new ERC20Splitter.Allocation[](2);
        allocations[0].deposit = addresses.getAddress("REVENUE_WALLET_MULTISIG01");
        allocations[0].ratio = 5_000;
        allocations[1].deposit = addresses.getAddress("REVENUE_WALLET_MULTISIG02");
        allocations[1].ratio = 5_000;

        /// ERC20Splitter consumable splitter contract
        ERC20Splitter erc1155SaleSplitter = new ERC20Splitter(
            address(_core),
            addresses.getAddress("TOKEN"),
            allocations
        );
        addresses.addAddress("ERC1155_SALE_SPLITTER", address(erc1155SaleSplitter), true);

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

    function _run() internal override {
        super._run();

        _simulateActions(
            addresses.getAddress("ADMIN_MULTISIG"),
            addresses.getAddress("ADMIN_MULTISIG")
        );
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

        /// ERC1155Sale
        ERC20Splitter.Allocation[] memory erc1155SaleAllocations = ERC20Splitter(
            addresses.getAddress("ERC1155_SALE_SPLITTER")
        ).getAllocations();

        assertEq(erc1155SaleAllocations.length, 2, "ERC1155Sale allocations length is not equal to 2");
        assertEq(
            erc1155SaleAllocations[0].deposit,
            addresses.getAddress("REVENUE_WALLET_MULTISIG01"),
            "ERC1155Sale allocation deposit is not equal to REVENUE_WALLET_MULTISIG01"
        );
        assertEq(erc1155SaleAllocations[0].ratio, 5_000);
        assertEq(
            erc1155SaleAllocations[1].deposit,
            addresses.getAddress("REVENUE_WALLET_MULTISIG02"),
            "ERC1155Sale allocation deposit is not equal to REVENUE_WALLET_MULTISIG02"
        );
        assertEq(erc1155SaleAllocations[1].ratio, 5_000, "ERC1155Sale allocation ratio is not equal to 5_000");

        assertEq(
            address(ERC20Splitter(addresses.getAddress("ERC1155_SALE_SPLITTER")).core()),
            address(_core),
            "ERC1155_SALE_SPLITTER is pointing to wrong core"
        );
    }
}
