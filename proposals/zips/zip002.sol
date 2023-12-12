//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

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
import {SeasonsTokenIdRegistry} from "@protocol/nfts/seasons/SeasonsTokenIdRegistry.sol";
import {ERC1155SeasonOne} from "@protocol/nfts/seasons/ERC1155SeasonOne.sol";

contract zip002 is Proposal, TimelockProposal {
    string public name = "ZIP002";
    string public description = "CGV1 ZTX proposal";

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
            10_000e18, // TODO need offical values from the boss man
            10_000_000e18, // same as above
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

        /// SeasonsTokenIdRegistry contract
        SeasonsTokenIdRegistry seasonsTokenIdRegistry = new SeasonsTokenIdRegistry(address(_core));
        addresses.addAddress("SEASONS_TOKEN_ID_REGISTRY", address(seasonsTokenIdRegistry));

        /// Season contracts (Season 1)
        ERC1155SeasonOne erc1155SeasonOne = new ERC1155SeasonOne(
            address(_core),
            address(erc1155Consumables),
            address(addresses.getAddress("TOKEN")),
            address(seasonsTokenIdRegistry)
        );
        addresses.addAddress("ERC1155_SEASON_ONE", address(erc1155SeasonOne));

        /// Admin timelock controller
        address[] memory adminTimelockProposersExecutors = new address[](1);

        adminTimelockProposersExecutors[0] = address(addresses.getAddress("ADMIN_MULTISIG"));
        TimelockController adminTimelock = new TimelockController(
            0, // TODO No delay for the adminTimeLock?
            adminTimelockProposersExecutors,
            adminTimelockProposersExecutors,
            address(0) // TODO what about the ADMIN_MULTISIG?
        );
        addresses.addAddress("ADMIN_TIMELOCK_CONTROLLER", address(adminTimelock));
    }

    function _afterDeploy(Addresses addresses, address) internal override {
        // Set LOCKER role for all NFT minting contracts
        _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES"));
        _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"));
        _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER"));

        /// MINTER role for all NFT minting contracts
        _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES"));
        _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"));
        _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER"));

        /// REGISTRY_OPERATOR role on the seasonOne contract
        _core.grantRole(Roles.REGISTRY_OPERATOR_PROTOCOL_ROLE, addresses.getAddress("ERC1155_SEASON_ONE"));

        // TODO should we config the seasonOne contract here?
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
                _core.hasRole(
                    Roles.LOCKER_PROTOCOL_ROLE,
                    addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES")
                ),
                true
            );
            assertEq(
                _core.hasRole(
                    Roles.LOCKER_PROTOCOL_ROLE,
                    addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")
                ),
                true
            );
            assertEq(
                _core.hasRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER")),
                true
            );

            /// Verfiy MINTER role
            assertEq(
                _core.hasRole(
                    Roles.MINTER_PROTOCOL_ROLE,
                    addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES")
                ),
                true
            );
            assertEq(
                _core.hasRole(
                    Roles.MINTER_PROTOCOL_ROLE,
                    addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")
                ),
                true
            );
            assertEq(
                _core.hasRole(Roles.MINTER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER")),
                true
            );
        }

        /// Verfiy REGISTRY_OPERATOR role
        {
            assertEq(
                _core.hasRole(Roles.REGISTRY_OPERATOR_PROTOCOL_ROLE, addresses.getAddress("ERC1155_SEASON_ONE")),
                true
            );
        }

        // Sum of Role counts to date
        {
            assertEq(_core.getRoleMemberCount(Roles.LOCKER_PROTOCOL_ROLE), 5);
            assertEq(_core.getRoleMemberCount(Roles.MINTER_PROTOCOL_ROLE), 5);
        }
    }

    function _validateOnChain(Addresses, address deployer) internal override {}

    function _validateForTestingOnly(Addresses, address deployer) internal override {}

    function _teardown(Addresses addresses, address deployer) internal override {}

    function _build(Addresses addresses, address) internal override {
        _pushTimelockAction(
            addresses.getAddress("CORE"),
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                Roles.LOCKER_PROTOCOL_ROLE,
                addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES")
            ),
            "Grant protocol locker role to ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES"
        );
    }

    function _run(Addresses addresses, address) internal override {
        this.setDebug(true);

        _simulateTimelockActions(
            addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"),
            addresses.getAddress("ADMIN_MULTISIG"),
            addresses.getAddress("ADMIN_MULTISIG")
        );
    }
}
