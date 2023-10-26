//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";
import {TimelockProposal} from "@proposals/proposalTypes/TimelockProposal.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {Token} from "@protocol/token/Token.sol";
import {ERC20HoldingDeposit} from "@protocol/finance/ERC20HoldingDeposit.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {ERC1155AutoGraphMinter} from "@protocol/nfts/ERC1155AutoGraphMinter.sol";
import {GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";
import {GameConsumer} from "@protocol/game/GameConsumer.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";

contract zip001 is Proposal, TimelockProposal {
    string public name = "ZIP001";
    string public description = "The ZTX wearable, Core & GlobalReentrancyLock contract proposal";

    function _beforeDeploy(Addresses addresses, address deployer) internal override {}

    function _deploy(Addresses addresses, address) internal override {
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
    }

    function _afterDeploy(Addresses addresses, address) internal override {
        // Setup ADMIN_MULTISIG
        _core.grantRole(Roles.ADMIN, addresses.getAddress("ADMIN_MULTISIG"));

        /// Set global lock
        _core.setGlobalLock(addresses.getAddress("GLOBAL_REENTRANCY_LOCK"));

        // Set LOCKER role for all NFT minting contracts
        _core.grantRole(Roles.LOCKER, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES"));

        /// MINTER role for all NFT minting contracts
        _core.grantRole(Roles.MINTER, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES"));
    }

    function _afterDeployOnChain(Addresses, address deployer) internal override {
        // Revoke ADMIN role from deployer
        _core.revokeRole(Roles.ADMIN, deployer);
    }

    function _validate(Addresses addresses, address) internal override {
        /// Check Roles
        assertEq(_core.hasRole(Roles.ADMIN, addresses.getAddress("ADMIN_MULTISIG")), true);

        /// Verfiy all contracts are pointing to the correct core address
        assertEq(address(GlobalReentrancyLock(addresses.getAddress("GLOBAL_REENTRANCY_LOCK")).core()), address(_core));

        assertEq(
            address(ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")).core()),
            address(_core)
        );

        /// Verifiy CoreRef
        assertEq(address(CoreRef(addresses.getAddress("GLOBAL_REENTRANCY_LOCK")).core()), address(_core));

        assertEq(
            address(CoreRef(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")).core()),
            address(_core)
        );

        /// Verfiy globlal lock has been set correctly
        assertEq(address(_core.lock()), addresses.getAddress("GLOBAL_REENTRANCY_LOCK"));

        /// Verfiy all roles have been assigned correcly
        /// Verfiy LOCKER role
        assertEq(_core.hasRole(Roles.LOCKER, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")), true);

        /// Verfiy MINTER role
        assertEq(_core.hasRole(Roles.MINTER, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")), true);

        // Sum of Role counts to date
        assertEq(_core.getRoleMemberCount(Roles.LOCKER), 1);
        assertEq(_core.getRoleMemberCount(Roles.MINTER), 1);
    }

    function _validateOnChain(Addresses, address deployer) internal override {
        /// Verify ADMIN role has been revoked from deployer
        assertEq(_core.hasRole(Roles.ADMIN, deployer), false);

        /// Verify only ADMIN_MULTISIG has ADMIN role
        assertEq(_core.getRoleMemberCount(Roles.ADMIN), 1);
    }

    function _validateForTestingOnly(Addresses, address deployer) internal override {}

    function _teardown(Addresses addresses, address deployer) internal override {}

    function _build(Addresses addresses, address deployer) internal override {}

    function _run(Addresses addresses, address deployer) internal override {}
}
