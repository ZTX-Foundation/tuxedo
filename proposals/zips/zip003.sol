//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Splitter} from "@protocol/finance/ERC20Splitter.sol";

import {TimelockProposal} from "@forge-proposal-simulator/src/proposals/TimelockProposal.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {ERC1155AutoGraphMinter} from "@protocol/nfts/ERC1155AutoGraphMinter.sol";
import {GameConsumer} from "@protocol/game/GameConsumer.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {SeasonsTokenIdRegistry} from "@protocol/nfts/seasons/SeasonsTokenIdRegistry.sol";
import {ERC1155SeasonOne} from "@protocol/nfts/seasons/ERC1155SeasonOne.sol";

contract zip003 is TimelockProposal {
    Core private _core;

    // Returns the name of the proposal.
    function name() public pure override returns (string memory) {
        return "ZIP003";
    }

    // Provides a brief description of the proposal.
    function description() public pure override returns (string memory) {
        return "ZTX CGv1 contracts proposal";
    }

    function deploy() public override {
        /// Confirm Timelock has been giving the ADMIN role correctly before we start the deployment
        assertEq(_core.hasRole(Roles.ADMIN, addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER")), true);

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
        addresses.addAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES", address(erc1155Consumables), true);

        /// Placeables NFT contract
        ERC1155MaxSupplyMintable erc1155Placeables = new ERC1155MaxSupplyMintable(
            address(_core),
            string(abi.encodePacked(_metadataBaseUri, "placeables/metadata/")),
            "ZTX Placeables",
            "ZTXP"
        );
        addresses.addAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES", address(erc1155Placeables), true);

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
        addresses.addAddress("CONSUMABLE_SPLITTER", address(consumableSplitter), true);

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
        addresses.addAddress("ERC1155_AUTO_GRAPH_MINTER", address(erc1155AutoGraphMinter), true);

        /// Game consumer
        GameConsumer gameConsumer = new GameConsumer(
            address(_core),
            addresses.getAddress("TOKEN"),
            addresses.getAddress("CONSUMABLE_SPLITTER"),
            addresses.getAddress("WETH")
        );
        addresses.addAddress("GAME_CONSUMABLE", address(gameConsumer), true);

        /// SeasonsTokenIdRegistry contract
        SeasonsTokenIdRegistry seasonsTokenIdRegistry = new SeasonsTokenIdRegistry(address(_core));
        addresses.addAddress("SEASONS_TOKEN_ID_REGISTRY", address(seasonsTokenIdRegistry), true);

        /// Season contracts (Season 1)
        ERC1155SeasonOne erc1155SeasonOne = new ERC1155SeasonOne(
            address(_core),
            address(erc1155Consumables),
            address(addresses.getAddress("TOKEN")),
            address(seasonsTokenIdRegistry)
        );
        addresses.addAddress("ERC1155_SEASON_ONE", address(erc1155SeasonOne), true);
    }

    function build()
        public
        override
        buildModifier(addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER")) 
    {
        /// Grant the GUARDIAN role to the GUARDIAN_MULTISIG
        _core.grantRole(Roles.GUARDIAN, addresses.getAddress("GUARDIAN_MULTISIG"));
        
        /// grant protocol Locker role
        _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES"));
        _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"));
        _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER"));

        /// grant protocol minter role
        _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER"));

        /// grant registry operator role
        _core.grantRole(Roles.REGISTRY_OPERATOR_PROTOCOL_ROLE, addresses.getAddress("ERC1155_SEASON_ONE"));

        /// grant minter notary role
        _core.grantRole(Roles.MINTER_NOTARY_PROTOCOL_ROLE, addresses.getAddress("AUTOGRAPH_SERVICE_KMS_WALLET"));

        /// grant game consumer notary protocol role
        _core.grantRole(Roles.GAME_CONSUMER_NOTARY_PROTOCOL_ROLE, addresses.getAddress("AUTOGRAPH_SERVICE_KMS_WALLET"));
    }

    function run() public override {
        setTimelock(addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"));
        
        /// Get Core Address
        _core = Core(addresses.getAddress("CORE"));

        super.run();
    }

    function simulate() public override {
        address multisig = addresses.getAddress("ADMIN_MULTISIG");

        /// Multisig is proposer and executor
        _simulateActions(multisig, multisig);
    }

    function validate() public override {
        /// Verify all contracts are pointing to the correct core address
        {
            assertEq(
                address(
                    ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES")).core()
                ),
                address(_core),
                "Verify ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES is pointing to the correct core address"
            );
            assertEq(
                address(
                    ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).core()
                ),
                address(_core),
                "Verify ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES is pointing to the correct core address"
            );
            assertEq(
                address(ERC1155AutoGraphMinter(addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER")).core()),
                address(_core),
                "Verify ERC1155_AUTO_GRAPH_MINTER is pointing to the correct core address"
            );
            assertEq(
                address(CoreRef(addresses.getAddress("GAME_CONSUMABLE")).core()),
                address(_core),
                "Verify GAME_CONSUMABLE is pointing to the correct core address"
            );
        }

        /// Verify all roles have been assigned correcly
        {
            /// Verify LOCKER role
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

            /// Verify MINTER role
            assertEq(
                _core.hasRole(Roles.MINTER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER")),
                true,
                "Verifying ERC1155_AUTO_GRAPH_MINTER has MINTER role"
            );
        }

        /// Verify REGISTRY_OPERATOR role
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
            assertEq(_core.getRoleMemberCount(Roles.MINTER_PROTOCOL_ROLE), 3, "Minter role count is not 5");
        }

        /// Verify MULTISIGS have the correct roles
        {
            assertEq(
                _core.hasRole(Roles.GUARDIAN, addresses.getAddress("GUARDIAN_MULTISIG")),
                true,
                "Verify GUARDIAN Role is set on GUARDIAN_MULTISIG"
            );
            assertEq(
                _core.hasRole(Roles.ADMIN, addresses.getAddress("ADMIN_MULTISIG")),
                true,
                "Verify ADMIN Role is set on ADMIN_MULTISIG"
            );
        }

        /// Verify ERC20Splitter has the correct settings
        {
            ERC20Splitter splitter = ERC20Splitter(addresses.getAddress("CONSUMABLE_SPLITTER"));
            assertEq(address(splitter.token()), addresses.getAddress("TOKEN"), "Verify splitter token address");

            (address address0, uint ratio0) = splitter.allocations(0);
            (address address1, uint ratio1) = splitter.allocations(1);

            assertEq(address0, addresses.getAddress("REVENUE_WALLET_MULTISIG01"));
            assertEq(ratio0, 5_000);
            assertEq(address1, addresses.getAddress("REVENUE_WALLET_MULTISIG02"));
            assertEq(ratio1, 5_000);
        }

        /// Verify ERC1155AutoGraphMinter has the correct settings
        {
            ERC1155AutoGraphMinter minter = ERC1155AutoGraphMinter(addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER"));
            assertEq(address(minter.core()), address(_core), "Verify minter core address");
            assertEq(
                address(minter.paymentRecipient()),
                addresses.getAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT"),
                "Verify minter payment recipient address"
            );
            assertEq(minter.replenishRatePerSecond(), 3, "Verify minter replenish rate per second");
            assertEq(minter.bufferCap(), 250_000, "Verify minter max tokens per day");
            assertEq(minter.buffer(), minter.bufferCap(), "Verify minter buffer == bufferCap");
            assertEq(minter.expiryTokenHoursValid(), 1, "Verify minter expiry timeout");

            assertEq(
                minter.isWhitelistedContract(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")),
                true,
                "Verify ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES is whitelisted"
            );
            assertEq(
                minter.isWhitelistedContract(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES")),
                true,
                "Verify ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES is whitelisted"
            );
            assertEq(
                minter.isWhitelistedContract(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")),
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

        /// Verify notary roles
        {
            assertEq(
                _core.hasRole(Roles.MINTER_NOTARY_PROTOCOL_ROLE, addresses.getAddress("AUTOGRAPH_SERVICE_KMS_WALLET")),
                true,
                "Verifying AUTOGRAPH_SERVICE_KMS_WALLET has MINTER_NOTARY role"
            );

            assertEq(
                _core.hasRole(
                    Roles.GAME_CONSUMER_NOTARY_PROTOCOL_ROLE,
                    addresses.getAddress("AUTOGRAPH_SERVICE_KMS_WALLET")
                ),
                true,
                "Verifying AUTOGRAPH_SERVICE_KMS_WALLET has GAME_CONSUMER_NOTARY role"
            );
        }
    }
}
