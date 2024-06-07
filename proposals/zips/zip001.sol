//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {MultisigProposal} from "@forge-proposal-simulator/src/proposals/MultisigProposal.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {ERC1155AdminMinter} from "@protocol/nfts/ERC1155AdminMinter.sol";
import {GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

import {Constants} from 'proposals/utils/Constants.sol';

contract zip001 is MultisigProposal {
    Core private _core;

    // Returns the name of the proposal.
    function name() public pure override returns (string memory) {
        return "ZIP001";
    }

    // Provides a brief description of the proposal.
    function description() public pure override returns (string memory) {
        return "The ZTX wearable, Core & GlobalReentrancyLock contract proposal";
    }

    function deploy() public override {
        /// Deploy Core
        _core = new Core();
        addresses.addAddress("CORE", address(_core), true);

        /// GlobalReentrancyLock
        GlobalReentrancyLock globalReentrancyLock = new GlobalReentrancyLock(addresses.getAddress("CORE"));
        addresses.addAddress("GLOBAL_REENTRANCY_LOCK", address(globalReentrancyLock), true);

        /// NTF contracts
        /// Setup metadata base uri
        string memory _metadataBaseUri = string(
            abi.encodePacked("https://meta.", vm.envString("ENVIRONMENT"), ".", vm.envString("DOMAIN"), "/")
        );

        /// Wearables NFT contract
        ERC1155MaxSupplyMintable erc1155Wearables = new ERC1155MaxSupplyMintable(
            address(_core),
            string(abi.encodePacked(_metadataBaseUri, "wearables/metadata/")),
            "ZTX Wearables",
            "ZTXW"
        );
        addresses.addAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES", address(erc1155Wearables), true);

        ERC1155AdminMinter minter = new ERC1155AdminMinter(address(_core));
        addresses.addAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTER", address(minter), true);

        // Setup ADMIN_MULTISIG
        _core.grantRole(Roles.ADMIN, addresses.getAddress("ADMIN_MULTISIG"));

        /// Set global lock
        _core.setGlobalLock(addresses.getAddress("GLOBAL_REENTRANCY_LOCK"));

        /// Set LOCKER role for all NFT minting contracts
        _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES"));
        _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTER"));

        /// Set MINTER role for all NFT minting contracts
        _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES"));
        _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTER"));

        /// Revoke ADMIN role from deployer on mainnet
        if (block.chainid == Constants.ARBITRUM_MAINNET) _core.revokeRole(Roles.ADMIN, addresses.getAddress("DEPLOYER_EOA"));
    }

    function validate() public override {
        /// Check Roles
        assertEq(_core.hasRole(Roles.ADMIN, addresses.getAddress("ADMIN_MULTISIG")), true, "incorrect admin role");

        /// Verify all contracts are pointing to the correct core address
        assertEq(
            address(GlobalReentrancyLock(addresses.getAddress("GLOBAL_REENTRANCY_LOCK")).core()),
            address(_core),
            "incorrect core address global reentrancy lock"
        );
        assertEq(
            address(ERC1155AdminMinter(addresses.getAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTER")).core()),
            address(_core),
            "incorrect core address admin minter"
        );

        assertEq(
            address(ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")).core()),
            address(_core),
            "incorrect core address erc1155 max supply mintable wearables"
        );

        /// Verifiy CoreRef
        assertEq(
            address(CoreRef(addresses.getAddress("GLOBAL_REENTRANCY_LOCK")).core()),
            address(_core),
            "incorrect core address global reentrancy lock"
        );

        assertEq(
            address(CoreRef(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")).core()),
            address(_core),
            "incorrect core address erc1155 max supply mintable wearables"
        );

        /// Verify globlal lock has been set correctly
        assertEq(address(_core.lock()), addresses.getAddress("GLOBAL_REENTRANCY_LOCK"), "incorrect global lock");

        /// Verify metadata URI
        assertEq(
            ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")).uri(0),
            string(
                abi.encodePacked(
                    "https://meta.",
                    vm.envString("ENVIRONMENT"),
                    ".",
                    vm.envString("DOMAIN"),
                    "/wearables/metadata/0"
                )
            ),
            "incorrect metadata URI"
        );

        /// Verify all roles have been assigned correcly
        /// Verify LOCKER role
        assertTrue(
            _core.hasRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")),
            "incorrect locker wearables"
        );
        assertTrue(
            _core.hasRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTER")),
            "incorrect locker admin minter"
        );

        /// Verify MINTER role
        assertTrue(
            _core.hasRole(Roles.MINTER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")),
            "incorrect minter wearables"
        );
        assertTrue(
            _core.hasRole(Roles.MINTER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTER")),
            "incorrect minter admin minter"
        );

        // Sum of Role counts to date
        assertEq(_core.getRoleMemberCount(Roles.LOCKER_PROTOCOL_ROLE), 2, "incorrect locker count");
        assertEq(_core.getRoleMemberCount(Roles.MINTER_PROTOCOL_ROLE), 2, "incorrect minter count");

        // Verify ADMIN count
        if (block.chainid == Constants.ARBITRUM_MAINNET) {
            assertEq(_core.getRoleMemberCount(Roles.ADMIN), 1, "incorrect admin count");
        }
        else {
            assertEq(_core.getRoleMemberCount(Roles.ADMIN), 2, "incorrect admin count");
        }

        // Verify ADMIN role has been revoked from deployer on mainnet
        if (block.chainid == Constants.ARBITRUM_MAINNET)
            assertFalse(
                _core.hasRole(Roles.ADMIN, addresses.getAddress("DEPLOYER_EOA")),
                "deployer should not have admin role"
            );
    }

    function run() public override {
        // No actions to print
        DO_PRINT = false;

        super.run();
    }
}
