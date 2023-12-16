//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";
import {TimelockProposal} from "@proposals/proposalTypes/TimelockProposal.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {Token, MAX_SUPPLY} from "@protocol/token/Token.sol";
import {ERC20HoldingDeposit} from "@protocol/finance/ERC20HoldingDeposit.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

contract zip004 is Proposal, TimelockProposal {
    string public name = "ZIP004";
    string public description = "Set TokenIds, MaxSupply and Capsule settings proposal";

    function _beforeDeploy(Addresses, address deployer) internal override {}

    function _deploy(Addresses addresses, address) internal override {}

    function _afterDeploy(Addresses addresses, address) internal override {}

    function _afterDeployOnChain(Addresses, address deployer) internal virtual override {}

    function _aferDeployForTestingOnly(Addresses, address deployer) internal virtual override {}

    function _teardown(Addresses addresses, address deployer) internal override {}

    function _build(Addresses addresses, address) internal override {
        // TODO Should we config the Season 1 contract here? IF so what's the go live config.

        /// Placeables config

        // TokenId 1
        _pushTimelockAction(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
            abi.encodeWithSignature("setSupplyCap(uint256,uint256)", 1, 100_000),
            "Set placeable tokenId 1 to max supply 100_000"
        );

        // TokenId 4
        _pushTimelockAction(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
            abi.encodeWithSignature("setSupplyCap(uint256,uint256)", 4, 100_000),
            "Set placeable tokenId 4 to max supply 100_000"
        );

        // TokenId 12
        _pushTimelockAction(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
            abi.encodeWithSignature("setSupplyCap(uint256,uint256)", 12, 100_000),
            "Set placeable tokenId 12 to max supply 100_000"
        );

        // TokenId 14
        _pushTimelockAction(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
            abi.encodeWithSignature("setSupplyCap(uint256,uint256)", 14, 2500),
            "Set placeable tokenId 14 to max supply 100_000"
        );

        // TokenId 17
        _pushTimelockAction(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
            abi.encodeWithSignature("setSupplyCap(uint256,uint256)", 17, 100_000),
            "Set placeable tokenId 17 to max supply 100_000"
        );

        // TokenId 21
        _pushTimelockAction(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
            abi.encodeWithSignature("setSupplyCap(uint256,uint256)", 21, 6000),
            "Set placeable tokenId 21 to max supply 6000"
        );

        // TokenId 27
        _pushTimelockAction(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
            abi.encodeWithSignature("setSupplyCap(uint256,uint256)", 27, 100_000),
            "Set placeable tokenId 27 to max supply 100_000"
        );

        // TokenId 28
        _pushTimelockAction(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
            abi.encodeWithSignature("setSupplyCap(uint256,uint256)", 28, 50),
            "Set placeable tokenId 28 to max supply 50"
        );

        // TokenId 31
        _pushTimelockAction(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
            abi.encodeWithSignature("setSupplyCap(uint256,uint256)", 31, 4000),
            "Set placeable tokenId 31 to max supply 4000"
        );

        // TokenId 43
        _pushTimelockAction(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
            abi.encodeWithSignature("setSupplyCap(uint256, uint256)", 43, 4000),
            "Set placeable tokenId 43 to max supply 4000"
        );

        // // TokenId 45
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setSupplyCap(uint256, uint256)", 45, 6000),
        //     "Set placeable tokenId 45 to max supply 6000"
        // );

        // // TokenId 60
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setSupplyCap(uint256, uint256)", 60, 6000),
        //     "Set placeable tokenId 60 to max supply 6000"
        // );

        // // TokenId 64
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setSupplyCap(uint256, uint256)", 64, 100_000),
        //     "Set placeable tokenId 64 to max supply 100_000"
        // );

        // // TokenId 65
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setSupplyCap(uint256, uint256)", 65, 100_000),
        //     "Set placeable tokenId 65 to max supply 100_000"
        // );

        // // TokenId 67
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setSupplyCap(uint256, uint256)", 67, 2500),
        //     "Set placeable tokenId 67 to max supply 2500"
        // );

        // // TokenId 69
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setSupplyCap(uint256, uint256)", 69, 6000),
        //     "Set placeable tokenId 69 to max supply 6000"
        // );

        // // TokenId 70
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setSupplyCap(uint256, uint256)", 70, 50),
        //     "Set placeable tokenId 70 to max supply 50"
        // );

        // // TokenId 72
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setSupplyCap(uint256, uint256)", 72, 4000),
        //     "Set placeable tokenId 72 to max supply 4000"
        // );

        // // TokenId 74
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setSupplyCap(uint256, uint256)", 74, 4000),
        //     "Set placeable tokenId 74 to max supply 4000"
        // );

        // // TokenId 76
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setSupplyCap(uint256, uint256)", 76, 1000),
        //     "Set placeable tokenId 76 to max supply 1000"
        // );

        // // TokenId 82
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setSupplyCap(uint256, uint256)", 82, 100_000),
        //     "Set placeable tokenId 82 to max supply 100_000"
        // );

        // // TokenId 90
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setSupplyCap(uint256, uint256)", 90, 100_000),
        //     "Set placeable tokenId 90 to max supply 100_000"
        // );

        // // TokenId 94
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setSupplyCap(uint256, uint256)", 94, 100_000),
        //     "Set placeable tokenId 94 to max supply 100_000"
        // );

        // // TokenId 96
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setSupplyCap(uint256, uint256)", 96, 100_000),
        //     "Set placeable tokenId 96 to max supply 100_000"
        // );

        // // TokenId 106
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setMintAmountLeft(uint256,uint256)", 106, 100_000),
        //     "Set placeable tokenId 106 to max supply 100_000"
        // );

        // // TokenId 107
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setMaxTokenSupply(uint256,uint256)", 107, 6000),
        //     "Set placeable tokenId 107 to max supply 6000"
        // );

        // // TokenId 111
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setMaxTokenSupply(uint256,uint256)", 111, 100_000),
        //     "Set placeable tokenId 111 to max supply 100_000"
        // );

        // // TokenId 124
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setMaxTokenSupply(uint256,uint256)", 124, 500),
        //     "Set placeable tokenId 124 to max supply 500"
        // );

        // // TokenId 149
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setMaxTokenSupply(uint256,uint256)", 149, 100_000),
        //     "Set placeable tokenId 149 to max supply 100_000"
        // );

        // // TokenId 152
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setMaxTokenSupply(uint256,uint256)", 152, 100_000),
        //     "Set placeable tokenId 152 to max supply 100_000"
        // );

        // // TokenId 153
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setMaxTokenSupply(uint256,uint256)", 153, 4000),
        //     "Set placeable tokenId 153 to max supply 4000"
        // );

        // // TokenId 154
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setMaxTokenSupply(uint256,uint256)", 154, 100_00),
        //     "Set placeable tokenId 154 to max supply 100_00"
        // );

        // // TokenId 156
        // _pushTimelockAction(
        //     addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
        //     abi.encodeWithSignature("setMaxTokenSupply(uint256,uint256)", 156, 100_000),
        //     "Set placeable tokenId 156 to max supply 100_000"
        // );
    }

    function _run(Addresses addresses, address) internal override {
        this.setDebug(true);

        _simulateTimelockActions(
            addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"),
            addresses.getAddress("ADMIN_MULTISIG"),
            addresses.getAddress("ADMIN_MULTISIG")
        );
    }

    function _validate(Addresses addresses, address) internal override {
        /// Placeable

        // tokenId 1
        assertEq(
            ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).getMintAmountLeft(
                1
            ),
            100_000,
            "getMintAmountLeft of placeable tokenId 1 should be 100_000"
        );
        assertEq(
            ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).maxTokenSupply(1),
            100_000,
            "maxTokenSupply of placeable tokenId 1 should be 100_000"
        );

        // tokenId 4
        assertEq(
            ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).getMintAmountLeft(
                4
            ),
            100_000,
            "getMintAmountLeft of placeable tokenId 4 should be 100_000"
        );
        assertEq(
            ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).maxTokenSupply(4),
            100_000,
            "maxTokenSupply of placeable tokenId 4 should be 100_000"
        );

        // tokenId 12
        assertEq(
            ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).getMintAmountLeft(
                12
            ),
            100_000,
            "getMintAmountLeft of placeable tokenId 12 should be 100_000"
        );
        assertEq(
            ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).maxTokenSupply(12),
            100_000,
            "maxTokenSupply of placeable tokenId 12 should be 100_000"
        );

        // tokenId 14
        assertEq(
            ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).getMintAmountLeft(
                14
            ),
            2500,
            "getMintAmountLeft of placeable tokenId 14 should be 2500"
        );
        assertEq(
            ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).maxTokenSupply(14),
            2500,
            "maxTokenSupply of placeable tokenId 14 should be 2500"
        );

        // tokenId 17
        assertEq(
            ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).getMintAmountLeft(
                17
            ),
            100_000,
            "getMintAmountLeft of placeable tokenId 17 should be 100_000"
        );
        assertEq(
            ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).maxTokenSupply(17),
            100_000,
            "maxTokenSupply of placeable tokenId 17 should be 100_000"
        );

        // tokenId 21
        assertEq(
            ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).getMintAmountLeft(
                21
            ),
            6000,
            "getMintAmountLeft of placeable tokenId 21 should be 6000"
        );
        assertEq(
            ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).maxTokenSupply(21),
            6000,
            "maxTokenSupply of placeable tokenId 21 should be 6000"
        );

        // tokenId 27
        assertEq(
            ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).getMintAmountLeft(
                27
            ),
            100_000,
            "getMintAmountLeft of placeable tokenId 27 should be 100_000"
        );
        assertEq(
            ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).maxTokenSupply(27),
            100_000,
            "maxTokenSupply of placeable tokenId 27 should be 100_000"
        );

        // tokenId 28
        assertEq(
            ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).getMintAmountLeft(
                28
            ),
            50,
            "getMintAmountLeft of placeable tokenId 28 should be 50"
        );
        assertEq(
            ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).maxTokenSupply(28),
            50,
            "maxTokenSupply of placeable tokenId 28 should be 50"
        );
    }

    function _validateOnChain(Addresses, address deployer) internal virtual override {}

    function _validateForTestingOnly(Addresses, address deployer) internal virtual override {}
}
