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

contract zip002 is Proposal, TimelockProposal {
    string public name = "ZIP002";
    string public description = "The Next draft ZTX proposal";

    function _beforeDeploy(Addresses addresses, address deployer) internal override {
        /// Get Core Address
        _core = Core(addresses.getCore());

        // Admin required for the deployment of this proposal
        assertEq(_core.hasRole(Roles.ADMIN, deployer), true);
    }

    function _deploy(Addresses addresses, address) internal override {
        /// NTF contracts
        /// Setup metadata base uri
        string memory _metadataBaseUri = string(
            abi.encodePacked("https://meta.", vm.envString("ENVIRONMENT"), ".", vm.envString("DOMAIN"), "/")
        );

        /// Consumables NFT contract
        ERC1155MaxSupplyMintable erc1155Consumables = new ERC1155MaxSupplyMintable(
            address(_core),
            string(abi.encodePacked(_metadataBaseUri, "consumables/metadata/")),
            "ZTX Consumables",
            "ZTXC"
        );
        addresses.addAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES", address(erc1155Consumables));

        /// Placeables NFT contract
        ERC1155MaxSupplyMintable erc1155Placeables = new ERC1155MaxSupplyMintable(
            address(_core),
            string(abi.encodePacked(_metadataBaseUri, "placeables/metadata/")),
            "ZTX Placeables",
            "ZTXP"
        );
        addresses.addAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES", address(erc1155Placeables));

        /// AutoGraphMinter contract
        address[] memory nftContractAddresses = new address[](3);
        nftContractAddresses[0] = address(erc1155Consumables);
        nftContractAddresses[1] = address(erc1155Placeables);
        nftContractAddresses[2] = addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES");

        ERC1155AutoGraphMinter erc1155AutoGraphMinter = new ERC1155AutoGraphMinter(
            address(_core),
            nftContractAddresses,
            10_000e18, // TODO get offical values from the HQ
            10_000_000e18,
            addresses.getAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT"),
            1 // 1 hour for valid expiryToken
        );
        addresses.addAddress("ERC1155_AUTO_GRAPH_MINTER", address(erc1155AutoGraphMinter));

        /// Game consumer
        GameConsumer gameConsumer = new GameConsumer(
            address(_core),
            addresses.getAddress("TOKEN"),
            addresses.getAddress("GAME_CONSUMER_PAYMENT_RECIPIENT"),
            addresses.getAddress("WETH")
        );
        addresses.addAddress("GAME_CONSUMABLE", address(gameConsumer));
    }

    function _afterDeploy(Addresses addresses, address) internal override {
        // Set LOCKER role for all NFT minting contracts
        _core.grantRole(Roles.LOCKER, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES"));
        _core.grantRole(Roles.LOCKER, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"));
        _core.grantRole(Roles.LOCKER, addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER"));

        /// MINTER role for all NFT minting contracts
        _core.grantRole(Roles.MINTER, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES"));
        _core.grantRole(Roles.MINTER, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"));
        _core.grantRole(Roles.MINTER, addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER"));
    }

    function _afterDeployOnChain(Addresses, address deployer) internal override {}

    function _validate(Addresses addresses, address) internal override {
        /// Verfiy all contracts are pointing to the correct core address
        {
            assertEq(
                address(
                    ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES")).core()
                ),
                address(_core)
            );
            assertEq(
                address(
                    ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).core()
                ),
                address(_core)
            );
            assertEq(
                address(ERC1155AutoGraphMinter(addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER")).core()),
                address(_core)
            );
            assertEq(address(CoreRef(addresses.getAddress("GAME_CONSUMABLE")).core()), address(_core));
        }

        /// Verfiy all roles have been assigned correcly
        {
            /// Verfiy LOCKER role
            assertEq(
                _core.hasRole(Roles.LOCKER, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES")),
                true
            );
            assertEq(_core.hasRole(Roles.LOCKER, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")), true);
            assertEq(_core.hasRole(Roles.LOCKER, addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER")), true);

            /// Verfiy MINTER role
            assertEq(
                _core.hasRole(Roles.MINTER, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES")),
                true
            );
            assertEq(_core.hasRole(Roles.MINTER, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")), true);
            assertEq(_core.hasRole(Roles.MINTER, addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER")), true);
        }

        // Sum of Role counts to date
        {
            assertEq(_core.getRoleMemberCount(Roles.LOCKER), 5);
            assertEq(_core.getRoleMemberCount(Roles.MINTER), 5);
        }
    }

    function _validateOnChain(Addresses, address deployer) internal override {}

    function _validateForTestingOnly(Addresses, address deployer) internal override {}

    function _teardown(Addresses addresses, address deployer) internal override {}

    function _build(Addresses addresses, address deployer) internal override {}

    function _run(Addresses addresses, address deployer) internal override {}
}
