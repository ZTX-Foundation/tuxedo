//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Splitter} from "@protocol/finance/ERC20Splitter.sol";

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

contract zip003 is Proposal, TimelockProposal {
    string public name = "ZIP003";
    string public description = "ZTX CGv1 contracts proposal";

    function _beforeDeploy(Addresses addresses, address deployer) internal override {
        /// Get Core Address
        _core = Core(addresses.getCore());

        /// Confirm Timelock has been giving the ADMIN role correctly before we start the deployment
        assertEq(
            _core.getRoleMember(Roles.ADMIN, 2),
            addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"),
            "Verifying ADMIN role is pointing to the correct address"
        );

        assertEq(_core.hasRole(Roles.ADMIN, addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER")), true);
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

        /// ERC20Splitter allocation settings
        ERC20Splitter.Allocation[] memory allocations = new ERC20Splitter.Allocation[](2);
        allocations[0].deposit = addresses.getAddress("REVENUE_WALLET_MULTISIG01");
        allocations[0].ratio = 5_000;
        allocations[1].deposit = addresses.getAddress("REVENUE_WALLET_MULTISIG02");
        allocations[1].ratio = 5_000;

        /// ERC20Splitter consumable splitter contract
        ERC20Splitter consumableSplitter = new ERC20Splitter(
            address(_core),
            addresses.getAddress("TOKEN"),
            allocations
        );
        addresses.addAddress("CONSUMABLE_SPLITTER", address(consumableSplitter));

        /// AutoGraphMinter contract
        address[] memory nftContractAddresses = new address[](3);
        nftContractAddresses[0] = address(erc1155Consumables);
        nftContractAddresses[1] = address(erc1155Placeables);
        nftContractAddresses[2] = addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES");

        ERC1155AutoGraphMinter erc1155AutoGraphMinter = new ERC1155AutoGraphMinter(
            address(_core),
            nftContractAddresses,
            3, // 10_800 per hour = 3 per second
            250_000, // 250_000 tokens per day
            addresses.getAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT"),
            1 // 1 hour expiry token timeout
        );
        addresses.addAddress("ERC1155_AUTO_GRAPH_MINTER", address(erc1155AutoGraphMinter));

        /// Game consumer
        GameConsumer gameConsumer = new GameConsumer(
            address(_core),
            addresses.getAddress("TOKEN"),
            addresses.getAddress("CONSUMABLE_SPLITTER"),
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
    }

    function _afterDeploy(Addresses addresses, address) internal override {}

    function _aferDeployForTestingOnly(Addresses, address deployer) internal virtual override {}

    function _afterDeployOnChain(Addresses, address deployer) internal override {}

    function _validate(Addresses addresses, address) internal override {
        /// Verfiy all contracts are pointing to the correct core address
        {
            assertEq(
                address(
                    ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES")).core()
                ),
                address(_core),
                "Verfiy ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES is pointing to the correct core address"
            );
            assertEq(
                address(
                    ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).core()
                ),
                address(_core),
                "Verfiy ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES is pointing to the correct core address"
            );
            assertEq(
                address(ERC1155AutoGraphMinter(addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER")).core()),
                address(_core),
                "Verfiy ERC1155_AUTO_GRAPH_MINTER is pointing to the correct core address"
            );
            assertEq(
                address(CoreRef(addresses.getAddress("GAME_CONSUMABLE")).core()),
                address(_core),
                "Verfiy GAME_CONSUMABLE is pointing to the correct core address"
            );
        }

        /// Verfiy all roles have been assigned correcly
        {
            /// Verfiy LOCKER role
            assertEq(
                _core.hasRole(
                    Roles.LOCKER_PROTOCOL_ROLE,
                    addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES")
                ),
                true,
                "Verifying ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES has LOCKER role"
            );
            assertEq(
                _core.hasRole(
                    Roles.LOCKER_PROTOCOL_ROLE,
                    addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")
                ),
                true,
                "Verifying ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES has LOCKER role"
            );
            assertEq(
                _core.hasRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER")),
                true,
                "Verifying ERC1155_AUTO_GRAPH_MINTER has LOCKER role"
            );

            /// Verfiy MINTER role
            assertEq(
                _core.hasRole(
                    Roles.MINTER_PROTOCOL_ROLE,
                    addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES")
                ),
                true,
                "Verifying ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES has MINTER role"
            );
            assertEq(
                _core.hasRole(
                    Roles.MINTER_PROTOCOL_ROLE,
                    addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")
                ),
                true,
                "Verifying ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES has MINTER role"
            );
            assertEq(
                _core.hasRole(Roles.MINTER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER")),
                true,
                "Verifying ERC1155_AUTO_GRAPH_MINTER has MINTER role"
            );
        }

        /// Verfiy REGISTRY_OPERATOR role
        {
            assertEq(
                _core.hasRole(Roles.REGISTRY_OPERATOR_PROTOCOL_ROLE, addresses.getAddress("ERC1155_SEASON_ONE")),
                true,
                "Verifying ERC1155_SEASON_ONE has REGISTRY_OPERATOR role"
            );
        }

        /// Sum of Role counts to date
        {
            assertEq(_core.getRoleMemberCount(Roles.LOCKER_PROTOCOL_ROLE), 5, "Locker role count is not 5");
            assertEq(_core.getRoleMemberCount(Roles.MINTER_PROTOCOL_ROLE), 5, "Minter role count is not 5");
        }

        /// Verfiy MULTISIGS have the correct roles
        {
            assertEq(
                _core.hasRole(Roles.GUARDIAN, addresses.getAddress("GUARDIAN_MULTISIG")),
                true,
                "Verfiy GUARDIAN Role is set on GUARDIAN_MULTISIG"
            );
            assertEq(
                _core.hasRole(Roles.ADMIN, addresses.getAddress("ADMIN_MULTISIG")),
                true,
                "Verfiy ADMIN Role is set on ADMIN_MULTISIG"
            );
        }

        /// Verfiy ERC20Splitter has the correct settings
        {
            ERC20Splitter splitter = ERC20Splitter(addresses.getAddress("CONSUMABLE_SPLITTER"));
            assertEq(address(splitter.token()), addresses.getAddress("TOKEN"), "Verfiy splitter token address");

            (address address0, uint ratio0) = splitter.allocations(0);
            (address address1, uint ratio1) = splitter.allocations(1);

            assertEq(address0, addresses.getAddress("REVENUE_WALLET_MULTISIG01"));
            assertEq(ratio0, 5_000);
            assertEq(address1, addresses.getAddress("REVENUE_WALLET_MULTISIG02"));
            assertEq(ratio1, 5_000);
        }

        /// Verfiy ERC1155AutoGraphMinter has the correct settings
        {
            ERC1155AutoGraphMinter minter = ERC1155AutoGraphMinter(addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER"));
            assertEq(address(minter.core()), address(_core), "Verfiy minter core address");
            assertEq(
                address(minter.paymentRecipient()),
                addresses.getAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT"),
                "Verfiy minter payment recipient address"
            );
            assertEq(minter.replenishRatePerSecond(), 3, "Verfiy minter replenish rate per second");
            assertEq(minter.bufferCap(), 250_000, "Verfiy minter max tokens per day");
            assertEq(minter.buffer(), minter.bufferCap(), "Verfiy minter buffer == bufferCap");
            assertEq(minter.expiryTokenHoursValid(), 1, "Verfiy minter expiry timeout");

            assertEq(
                minter.isWhitelistedAddress(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")),
                true,
                "Verify ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES is whitelisted"
            );
            assertEq(
                minter.isWhitelistedAddress(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES")),
                true,
                "Verify ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES is whitelisted"
            );
            assertEq(
                minter.isWhitelistedAddress(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")),
                true,
                "Verify ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES is whitelisted"
            );

            /// Verify Game consumable
            ERC20Splitter.Allocation[] memory consumableAllocations = ERC20Splitter(
                addresses.getAddress("CONSUMABLE_SPLITTER")
            ).getAllocations();

            assertEq(consumableAllocations.length, 2, "Consumable allocations length is not equal to 2");
            assertEq(
                consumableAllocations[0].deposit,
                addresses.getAddress("REVENUE_WALLET_MULTISIG01"),
                "Consumable allocation deposit is not equal to BURNER_HOLDING_DEPOSIT"
            );
            assertEq(consumableAllocations[0].ratio, 5_000, "Consumable allocation ratio is not equal to 5_000");
            assertEq(
                consumableAllocations[1].deposit,
                addresses.getAddress("REVENUE_WALLET_MULTISIG02"),
                "Consumable allocation deposit is not equal to TREASURY_WALLET_MULTISIG"
            );
            assertEq(consumableAllocations[1].ratio, 5_000, "Consumable allocation ratio is not equal to 5_000");

            assertEq(
                address(ERC20Splitter(addresses.getAddress("CONSUMABLE_SPLITTER")).core()),
                address(_core),
                "CONSUMABLE_SPLITTER is pointing to wrong core"
            );
        }
    }

    function _validateOnChain(Addresses, address deployer) internal override {}

    function _validateForTestingOnly(Addresses, address deployer) internal override {}

    function _teardown(Addresses addresses, address deployer) internal override {}

    function _build(Addresses addresses, address) internal override {
        /// Grant the GUARDIAN role to the GUARDIAN_MULTISIG
        _pushTimelockAction(
            addresses.getAddress("CORE"),
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                Roles.GUARDIAN,
                addresses.getAddress("GUARDIAN_MULTISIG")
            ),
            "Grant GUARDIAN role to GUARDIAN_MULTISIG"
        );

        /// grant protocol Locker role
        _pushTimelockAction(
            addresses.getAddress("CORE"),
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                Roles.LOCKER_PROTOCOL_ROLE,
                addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES")
            ),
            "Grant protocol locker role to ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES"
        );

        _pushTimelockAction(
            addresses.getAddress("CORE"),
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                Roles.LOCKER_PROTOCOL_ROLE,
                addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")
            ),
            "Grant protocol locker role to ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"
        );

        _pushTimelockAction(
            addresses.getAddress("CORE"),
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                Roles.LOCKER_PROTOCOL_ROLE,
                addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER")
            ),
            "Grant protocol locker role to ERC1155_AUTO_GRAPH_MINTER"
        );

        /// grant protocol minter role
        _pushTimelockAction(
            addresses.getAddress("CORE"),
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                Roles.MINTER_PROTOCOL_ROLE,
                addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES")
            ),
            "Grant protocol minter role to ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES"
        );

        _pushTimelockAction(
            addresses.getAddress("CORE"),
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                Roles.MINTER_PROTOCOL_ROLE,
                addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")
            ),
            "Grant protocol minter role to ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"
        );

        _pushTimelockAction(
            addresses.getAddress("CORE"),
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                Roles.MINTER_PROTOCOL_ROLE,
                addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER")
            ),
            "Grant protocol minter role to ERC1155_AUTO_GRAPH_MINTER"
        );

        /// grant registry operator role
        _pushTimelockAction(
            addresses.getAddress("CORE"),
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                Roles.REGISTRY_OPERATOR_PROTOCOL_ROLE,
                addresses.getAddress("ERC1155_SEASON_ONE")
            ),
            "Grant registry operator role to ERC1155_SEASON_ONE"
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
