//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";
import {Addresses} from "@proposals/Addresses.sol";
import {ERC1155AdminMinter} from "@protocol/nfts/ERC1155AdminMinter.sol";
import {GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

contract zip001 is Proposal {
    string public name = "ZIP001";
    string public description = "The ZTX wearable, Core & GlobalReentrancyLock contract proposal";

    function deploy(Addresses addresses, address) public override {
        /// Deploy Core
        _core = new Core();
        addresses.addAddress("CORE", address(_core));

        /// GlobalReentrancyLock
        GlobalReentrancyLock globalReentrancyLock = new GlobalReentrancyLock(addresses.getCore());
        addresses.addAddress("GLOBAL_REENTRANCY_LOCK", address(globalReentrancyLock));

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
        addresses.addAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES", address(erc1155Wearables));

        ERC1155AdminMinter minter = new ERC1155AdminMinter(address(_core));
        addresses.addAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTER", address(minter));
    }

    function afterDeploy(Addresses addresses, address deployer) public override {
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

        _core.revokeRole(Roles.ADMIN, deployer);
    }

    function validate(Addresses addresses, address deployer) public override {
        /// Check Roles
        assertEq(_core.hasRole(Roles.ADMIN, addresses.getAddress("ADMIN_MULTISIG")), true, "incorrect admin role");

        /// Verfiy all contracts are pointing to the correct core address
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

        /// Verfiy globlal lock has been set correctly
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

        /// Verfiy all roles have been assigned correcly
        /// Verfiy LOCKER role
        assertTrue(
            _core.hasRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")),
            "incorrect locker wearables"
        );
        assertTrue(
            _core.hasRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTER")),
            "incorrect locker admin minter"
        );

        /// Verfiy MINTER role
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

        /// Verify ADMIN role has been revoked from deployer
        assertEq(_core.hasRole(Roles.ADMIN, deployer), false, "deployer should not have admin role");
    
        /// Verify only ADMIN_MULTISIG has ADMIN role
        assertEq(_core.getRoleMemberCount(Roles.ADMIN), 1, "incorrect admin count");
    }

    function teardown(Addresses addresses, address) public override {}

    function build(Addresses addresses, address) public override {}

    function run(Addresses addresses, address) public override {}

    function printProposalActionSteps() public override {} /// no op, do nothing
}
