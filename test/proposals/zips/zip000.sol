//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {Addresses} from "@test/proposals/Addresses.sol";
import {Proposal} from "@test/proposals/proposalTypes/Proposal.sol";
import {TimelockProposal} from "@test/proposals/proposalTypes/TimelockProposal.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {Token} from "@protocol/token/Token.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {ERC1155Sale} from "@protocol/sale/ERC1155Sale.sol";
import {GameConsumer} from "@protocol/game/GameConsumer.sol";
import {GovernorDAO} from "@protocol/governance/GovernorDAO.sol";
import {ERC20Splitter} from "@protocol/finance/ERC20Splitter.sol";
import {FinanceGuardian} from "@protocol/finance/FinanceGuardian.sol";
import {GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";
import {ERC1155AutoGraphMinter} from "@protocol/nfts/ERC1155AutoGraphMinter.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {ERC20HoldingDeposit} from "@protocol/finance/ERC20HoldingDeposit.sol";
import {ERC1155SeasonOne} from "@protocol/nfts/seasons/ERC1155SeasonOne.sol";
import {ERC1155SeasonTwo} from "@protocol/nfts/seasons/ERC1155SeasonTwo.sol";
import {SeasonsTokenIdRegistry} from "@protocol/nfts/seasons/SeasonsTokenIdRegistry.sol";
import {TokenIdRewardAmount} from "@protocol/nfts/seasons/SeasonsBase.sol";

contract zip000 is Proposal, TimelockProposal {
    string public name = "ZIP000";
    string public description = "The ZTX Genesis Proposal";
    bool public mainnetDeployed = false;
    bool public testnetDeployed = false;

    address[] public whitelistAddresses;

    function deploy(Addresses addresses, address deployer) public {
        /// Core
        Core core = new Core();
        addresses.addAddress("CORE", address(core));

        /// GlobalReentrancyLock
        GlobalReentrancyLock globalReentrancyLock = new GlobalReentrancyLock(addresses.getAddress("CORE"));
        addresses.addAddress("GLOBAL_REENTRANCY_LOCK", address(globalReentrancyLock));

        {
            /// ERC1155MaxSupplyMintable
            string memory _metadataBaseUri = string(
                abi.encodePacked("https://meta.", vm.envString("ENVIRONMENT"), ".", vm.envString("DOMAIN"), "/")
            );
            ERC1155MaxSupplyMintable erc1155Consumables = new ERC1155MaxSupplyMintable(
                address(core),
                string(abi.encodePacked(_metadataBaseUri, "consumables/metadata/")),
                "ZTX Consumables",
                "ZTXC"
            );

            addresses.addAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES", address(erc1155Consumables));

            ERC1155MaxSupplyMintable erc1155Placeables = new ERC1155MaxSupplyMintable(
                address(core),
                string(abi.encodePacked(_metadataBaseUri, "placeables/metadata/")),
                "ZTX Placeables",
                "ZTXP"
            );

            addresses.addAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES", address(erc1155Placeables));

            ERC1155MaxSupplyMintable erc1155Wearables = new ERC1155MaxSupplyMintable(
                address(core),
                string(abi.encodePacked(_metadataBaseUri, "wearables/metadata/")),
                "ZTX Wearables",
                "ZTXW"
            );

            addresses.addAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES", address(erc1155Wearables));

            address[] memory nftContractAddresses = new address[](3);
            nftContractAddresses[0] = address(erc1155Consumables);
            nftContractAddresses[1] = address(erc1155Placeables);
            nftContractAddresses[2] = address(erc1155Wearables);

            /// ERC1155RateLimitedMinter
            ERC1155AutoGraphMinter erc1155AutoGraphMinter = new ERC1155AutoGraphMinter(
                address(core),
                nftContractAddresses,
                10_000e18, // TODO get offical values from the HQ
                10_000_000e18,
                addresses.getAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT"),
                1 // 1 hour for valid expiryToken
            );

            addresses.addAddress("ERC1155_AUTO_GRAPH_MINTER", address(erc1155AutoGraphMinter));

            /// ERC20HoldingDeposit
            // IERC20 wethToken = IERC20(addresses.getAddress("WETH"));

            ERC20HoldingDeposit wethErc20HoldingDeposit = new ERC20HoldingDeposit(
                address(core),
                addresses.getAddress("WETH")
            );

            addresses.addAddress("WETH_ERC20_HOLDING_DEPOSIT", address(wethErc20HoldingDeposit));
        }

        {
            /// ERC1155Sale
            ERC1155Sale consumablesERC1155Sale = new ERC1155Sale(
                address(core),
                addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES"),
                addresses.getAddress("WETH")
            );
            addresses.addAddress("ERC1155_SALE_CONSUMABLES", address(consumablesERC1155Sale));

            ERC1155Sale placeablesERC1155Sale = new ERC1155Sale(
                address(core),
                addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
                addresses.getAddress("WETH")
            );
            addresses.addAddress("ERC1155_SALE_PLACEABLES", address(placeablesERC1155Sale));

            ERC1155Sale wearablesERC1155Sale = new ERC1155Sale(
                address(core),
                addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES"),
                addresses.getAddress("WETH")
            );
            addresses.addAddress("ERC1155_SALE_WEARABLES", address(wearablesERC1155Sale));

            /// FinanceGuardian
            whitelistAddresses.push(addresses.getAddress("WETH_ERC20_HOLDING_DEPOSIT"));
            whitelistAddresses.push(address(consumablesERC1155Sale));
            whitelistAddresses.push(address(placeablesERC1155Sale));
            whitelistAddresses.push(address(wearablesERC1155Sale));

            FinanceGuardian financeGuardian = new FinanceGuardian(
                address(core),
                addresses.getAddress("FINANCE_GUARDIAN_SAFE_ADDRESS"),
                whitelistAddresses
            );

            addresses.addAddress("FINANCE_GUARDIAN", address(financeGuardian));
        }

        {
            /// Token
            Token token = new Token(
                string(abi.encodePacked(vm.envString("TOKEN_NAME"))),
                string(abi.encodePacked(vm.envString("TOKEN_SYMBOL")))
            );
            addresses.addAddress("TOKEN", address(token));

            /// Timelock Controller (Governor Bravo DAO)
            /// @notice we do this as the deployer is different when running in fork mode,
            /// versus deploying to a live chain
            address governorDAOTimelockAdmin;
            if (addresses.getAddress("DEPLOYER") == deployer) {
                governorDAOTimelockAdmin = deployer;
            } else {
                governorDAOTimelockAdmin = address(this);
            }

            /// @notice set a temporary admin and then transfer
            TimelockController governorDAOTimelock = new TimelockController(
                2 days,
                new address[](0),
                new address[](0),
                governorDAOTimelockAdmin
            );

            /// Governor DAO contract
            GovernorDAO governorDAO = new GovernorDAO(
                string(abi.encodePacked(Token(addresses.getAddress("TOKEN")).name(), "Protocol Governor")),
                addresses.getAddress("CORE"),
                address(governorDAOTimelock),
                addresses.getAddress("TOKEN"),
                0,
                200_000,
                100_000_000e18,
                200_000_000e18
            );
            addresses.addAddress("GOVERNOR_DAO", address(governorDAO));
            addresses.addAddress("GOVERNOR_DAO_TIMELOCK_CONTROLLER", address(governorDAOTimelock));
            governorDAOTimelock.grantRole(
                governorDAOTimelock.TIMELOCK_ADMIN_ROLE(),
                addresses.getAddress("GOVERNOR_DAO")
            );

            /// Admin timelock controller
            address[] memory adminTimelockProposersExecutors = new address[](1);

            adminTimelockProposersExecutors[0] = address(addresses.getAddress("ADMIN_MULTISIG"));
            TimelockController adminTimelock = new TimelockController(
                2 days,
                adminTimelockProposersExecutors,
                adminTimelockProposersExecutors,
                address(0)
            );

            addresses.addAddress("ADMIN_TIMELOCK_CONTROLLER", address(adminTimelock));
            governorDAOTimelock.grantRole(governorDAOTimelock.PROPOSER_ROLE(), addresses.getAddress("GOVERNOR_DAO"));
            governorDAOTimelock.grantRole(governorDAOTimelock.EXECUTOR_ROLE(), addresses.getAddress("GOVERNOR_DAO"));
            governorDAOTimelock.grantRole(governorDAOTimelock.CANCELLER_ROLE(), addresses.getAddress("GOVERNOR_DAO"));

            governorDAOTimelock.grantRole(
                governorDAOTimelock.CANCELLER_ROLE(),
                addresses.getAddress("GUARDIAN_MULTISIG")
            );

            governorDAOTimelock.revokeRole(governorDAOTimelock.TIMELOCK_ADMIN_ROLE(), governorDAOTimelockAdmin);
        }

        {
            ERC20HoldingDeposit burnHoldingDeposit = new ERC20HoldingDeposit(
                address(core),
                addresses.getAddress("TOKEN")
            );
            addresses.addAddress("BURNER_WALLET", address(burnHoldingDeposit));

            ERC20HoldingDeposit treasuryHoldingDeposit = new ERC20HoldingDeposit(
                address(core),
                addresses.getAddress("TOKEN")
            );
            addresses.addAddress("TREASURY_WALLET", address(treasuryHoldingDeposit));

            ERC20HoldingDeposit wethTreasuryHoldingDeposit = new ERC20HoldingDeposit(
                address(core),
                addresses.getAddress("WETH")
            );
            addresses.addAddress("WETH_TREASURY_WALLET", address(wethTreasuryHoldingDeposit));

            ERC20Splitter.Allocation[] memory allocations = new ERC20Splitter.Allocation[](2);
            allocations[0].deposit = addresses.getAddress("BURNER_WALLET");
            allocations[0].ratio = 5_000;
            allocations[1].deposit = addresses.getAddress("TREASURY_WALLET");
            allocations[1].ratio = 5_000;

            /// ERC20Splitter
            ERC20Splitter splitter = new ERC20Splitter(address(core), addresses.getAddress("TOKEN"), allocations);
            ERC20Splitter consumableSplitter = new ERC20Splitter(
                address(core),
                addresses.getAddress("TOKEN"),
                allocations
            );
            addresses.addAddress("CONSUMABLE_SPLITTER", address(consumableSplitter));

            /// ERC1155Sale Splitter
            ERC20Splitter.Allocation[] memory wethAllocations = new ERC20Splitter.Allocation[](2);
            wethAllocations[0].deposit = addresses.getAddress("WETH_TREASURY_WALLET");
            wethAllocations[0].ratio = 5_000;
            wethAllocations[1].deposit = addresses.getAddress("WETH_TREASURY_WALLET");
            wethAllocations[1].ratio = 5_000;

            ERC20Splitter erc1155SaleSplitter = new ERC20Splitter(
                address(core),
                addresses.getAddress("WETH"),
                wethAllocations
            );
            addresses.addAddress("ERC1155_SALE_SPLITTER", address(erc1155SaleSplitter));

            /// Game consumer
            GameConsumer consumer = new GameConsumer(
                address(core),
                addresses.getAddress("TOKEN"),
                addresses.getAddress("GAME_CONSUMER_PAYMENT_RECIPIENT"),
                addresses.getAddress("WETH")
            );

            addresses.addAddress("GAME_CONSUMABLE", address(consumer));
        }

        {
            Core core = Core(addresses.getAddress("CORE"));

            // SeasonsTokenIdRegistry setup
            SeasonsTokenIdRegistry seasonsTokenIdRegistry = new SeasonsTokenIdRegistry(address(core));
            addresses.addAddress("SEASONS_TOKENID_REGISTRY", address(seasonsTokenIdRegistry));

            /// ERC1155MaxSupplyMintable
            string memory _metadataBaseUri = string(
                abi.encodePacked("https://meta.", vm.envString("ENVIRONMENT"), vm.envString("DOMAIN"), "/")
            );

            // CapsulesNFT ERC1155 setup
            ERC1155MaxSupplyMintable erc1155CapsulesNFT = new ERC1155MaxSupplyMintable(
                address(core),
                string(abi.encodePacked(_metadataBaseUri, "/consumables/metadata/seasons/1/capsules/")), //TODO confirm path
                "Capsules",
                "CAPS"
            );
            addresses.addAddress("ERC1155_CAPSULES_NFT", address(erc1155CapsulesNFT));

            // Config tokenId to Reaward Amount
            TokenIdRewardAmount[] memory tokenIdRewardAmounts = new TokenIdRewardAmount[](3);
            tokenIdRewardAmounts[0] = TokenIdRewardAmount({tokenId: 1, rewardAmount: 400});
            tokenIdRewardAmounts[1] = TokenIdRewardAmount({tokenId: 2, rewardAmount: 1000});
            tokenIdRewardAmounts[2] = TokenIdRewardAmount({tokenId: 3, rewardAmount: 1600});

            // SeasonOne Logic contract setup
            ERC1155SeasonOne erc1155SeasonOne = new ERC1155SeasonOne(
                address(core),
                address(erc1155CapsulesNFT),
                addresses.getAddress("TOKEN"),
                address(seasonsTokenIdRegistry)
            );
            addresses.addAddress("ERC1155_SEASON_ONE", address(erc1155SeasonOne));

            // TODO erc1155.setSupplyCap(1, 4000); numbers need to be given by HQ
            // TODO erc1155.setSupplyCap(2, 4000); numbers need to be given by HQ
            // TODO erc1155.setSupplyCap(3, 4000); numbers need to be given by HQ

            // TODO cant called this until supply has been set.
            // erc1155SeasonOne.configSeasonDistribution(tokenIdRewardAmounts);
        }
    }

    function afterDeploy(Addresses addresses, address deployer) public {
        Core core = Core(addresses.getAddress("CORE"));

        /// Set global lock
        core.setGlobalLock(addresses.getAddress("GLOBAL_REENTRANCY_LOCK"));

        /// Transfer ERC20
        IERC20(addresses.getAddress("TOKEN")).transfer(addresses.getAddress("TREASURY_WALLET"), 10_000_000_000e18);

        /// ADMIN role
        core.grantRole(Roles.ADMIN, addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"));
        core.grantRole(Roles.ADMIN, addresses.getAddress("ADMIN_MULTISIG"));

        /// LOCKER role
        core.grantRole(Roles.LOCKER, addresses.getAddress("ERC1155_SALE_CONSUMABLES"));
        core.grantRole(Roles.LOCKER, addresses.getAddress("ERC1155_SALE_PLACEABLES"));
        core.grantRole(Roles.LOCKER, addresses.getAddress("ERC1155_SALE_WEARABLES"));
        core.grantRole(Roles.LOCKER, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES"));
        core.grantRole(Roles.LOCKER, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"));
        core.grantRole(Roles.LOCKER, addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES"));
        core.grantRole(Roles.LOCKER, addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER"));

        /// MINTER role
        core.grantRole(Roles.MINTER, addresses.getAddress("ERC1155_SALE_CONSUMABLES"));
        core.grantRole(Roles.MINTER, addresses.getAddress("ERC1155_SALE_PLACEABLES"));
        core.grantRole(Roles.MINTER, addresses.getAddress("ERC1155_SALE_WEARABLES"));
        core.grantRole(Roles.MINTER, addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER"));

        /// TOKEN_GOVERNOR role
        core.grantRole(Roles.TOKEN_GOVERNOR, addresses.getAddress("GOVERNOR_DAO"));

        /// GUARDIAN role
        core.grantRole(Roles.GUARDIAN, addresses.getAddress("FINANCE_GUARDIAN"));
        core.grantRole(Roles.GUARDIAN, addresses.getAddress("GUARDIAN_MULTISIG"));

        /// FINANCIAL_CONTROLLER role
        core.grantRole(Roles.FINANCIAL_CONTROLLER, addresses.getAddress("FINANCE_GUARDIAN"));
        core.grantRole(Roles.FINANCIAL_CONTROLLER, addresses.getAddress("TREASURY_WALLET"));
        core.grantRole(Roles.FINANCIAL_CONTROLLER, addresses.getAddress("WETH_TREASURY_WALLET"));

        /// FINANCIAL_GUARDIAN Role
        core.grantRole(Roles.FINANCIAL_GUARDIAN, addresses.getAddress("FINANCE_GUARDIAN_MULTISIG"));

        /// Remove admin role from the deployer
        core.revokeRole(Roles.ADMIN, deployer);
    }

    function build(Addresses addresses) public {
        _pushTimelockAction(
            addresses.getAddress("CORE"),
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                Roles.FINANCIAL_CONTROLLER,
                addresses.getAddress("GOVERNOR_DAO_TIMELOCK_CONTROLLER")
            ),
            "Grant Governor DAO timelock controller the role FINANCIAL_CONTROLLER"
        );
    }

    function run(Addresses addresses, address deployer) public {
        _simulateTimelockActions(
            addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"), // timelockAddress
            addresses.getAddress("ADMIN_MULTISIG"), // proposerAddress
            addresses.getAddress("ADMIN_MULTISIG") // executorAddress
        );
    }

    function teardown(Addresses addresses, address deployer) public pure {}

    function validate(Addresses addresses, address deployer) public {
        /// Check that everything is pointing to the right core contract address
        Core core = Core(addresses.getAddress("CORE"));

        /// Check Treasury balance
        assertEq(
            IERC20(addresses.getAddress("TOKEN")).balanceOf(addresses.getAddress("TREASURY_WALLET")),
            10_000_000_000e18
        );

        /// Reentrancy lock
        assertEq(address(GlobalReentrancyLock(addresses.getAddress("GLOBAL_REENTRANCY_LOCK")).core()), address(core));

        /// ERC1155MaxSupplyMintable
        assertEq(
            address(ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES")).core()),
            address(core)
        );
        assertEq(
            address(ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")).core()),
            address(core)
        );
        assertEq(
            address(ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")).core()),
            address(core)
        );
        assertEq(
            address(ERC1155AutoGraphMinter(addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER")).core()),
            address(core)
        );

        assertEq(address(ERC1155Sale(addresses.getAddress("ERC1155_SALE_CONSUMABLES")).core()), address(core));
        assertEq(address(ERC1155Sale(addresses.getAddress("ERC1155_SALE_WEARABLES")).core()), address(core));
        assertEq(address(ERC1155Sale(addresses.getAddress("ERC1155_SALE_PLACEABLES")).core()), address(core));

        assertEq(
            address(ERC20HoldingDeposit(addresses.getAddress("WETH_ERC20_HOLDING_DEPOSIT")).core()),
            address(core)
        );

        assertEq(address(FinanceGuardian(addresses.getAddress("FINANCE_GUARDIAN")).core()), address(core));

        assertEq(address(CoreRef(addresses.getAddress("CONSUMABLE_SPLITTER")).core()), address(core));
        assertEq(address(CoreRef(addresses.getAddress("GAME_CONSUMABLE")).core()), address(core));
        assertEq(address(CoreRef(addresses.getAddress("BURNER_WALLET")).core()), address(core));

        /// ERC1155Sale
        ERC20Splitter.Allocation[] memory erc1155SaleAllocations = ERC20Splitter(
            addresses.getAddress("ERC1155_SALE_SPLITTER")
        ).getAllocations();

        assertEq(erc1155SaleAllocations.length, 2);
        assertEq(erc1155SaleAllocations[0].deposit, addresses.getAddress("WETH_TREASURY_WALLET"));
        assertEq(erc1155SaleAllocations[0].ratio, 5_000);
        assertEq(erc1155SaleAllocations[1].deposit, addresses.getAddress("WETH_TREASURY_WALLET"));
        assertEq(erc1155SaleAllocations[1].ratio, 5_000);

        assertEq(address(ERC20Splitter(addresses.getAddress("ERC1155_SALE_SPLITTER")).core()), address(core));

        /// Game consumable
        ERC20Splitter.Allocation[] memory consumableAllocations = ERC20Splitter(
            addresses.getAddress("CONSUMABLE_SPLITTER")
        ).getAllocations();

        assertEq(consumableAllocations.length, 2);
        assertEq(consumableAllocations[0].deposit, addresses.getAddress("BURNER_WALLET"));
        assertEq(consumableAllocations[0].ratio, 5_000);
        assertEq(consumableAllocations[1].deposit, addresses.getAddress("TREASURY_WALLET"));
        assertEq(consumableAllocations[1].ratio, 5_000);

        assertEq(address(ERC20Splitter(addresses.getAddress("CONSUMABLE_SPLITTER")).core()), address(core));

        /// Check that right number of roles has been assigned
        assertEq(core.getRoleMemberCount(Roles.ADMIN), 2);
        assertEq(core.getRoleMemberCount(Roles.FINANCIAL_CONTROLLER), 4);
        assertEq(core.getRoleMemberCount(Roles.GUARDIAN), 2);
        assertEq(core.getRoleMemberCount(Roles.FINANCIAL_GUARDIAN), 1);
        assertEq(core.getRoleMemberCount(Roles.LOCKER), 7);
        assertEq(core.getRoleMemberCount(Roles.MINTER), 4);

        /// ADMIN role
        assertEq(core.getRoleMember(Roles.ADMIN, 0), addresses.getAddress("ADMIN_MULTISIG"));
        assertEq(core.getRoleMember(Roles.ADMIN, 1), addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"));

        /// LOCKER role
        assertEq(core.getRoleMember(Roles.LOCKER, 0), addresses.getAddress("ERC1155_SALE_CONSUMABLES"));
        assertEq(core.getRoleMember(Roles.LOCKER, 1), addresses.getAddress("ERC1155_SALE_PLACEABLES"));
        assertEq(core.getRoleMember(Roles.LOCKER, 2), addresses.getAddress("ERC1155_SALE_WEARABLES"));
        assertEq(core.getRoleMember(Roles.LOCKER, 3), addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES"));
        assertEq(core.getRoleMember(Roles.LOCKER, 4), addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"));
        assertEq(core.getRoleMember(Roles.LOCKER, 5), addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES"));
        assertEq(core.getRoleMember(Roles.LOCKER, 6), addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER"));

        /// MINTER role
        assertEq(core.getRoleMember(Roles.MINTER, 0), addresses.getAddress("ERC1155_SALE_CONSUMABLES"));
        assertEq(core.getRoleMember(Roles.MINTER, 1), addresses.getAddress("ERC1155_SALE_PLACEABLES"));
        assertEq(core.getRoleMember(Roles.MINTER, 2), addresses.getAddress("ERC1155_SALE_WEARABLES"));
        assertEq(core.getRoleMember(Roles.MINTER, 3), addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER"));

        /// TOKEN_GOVERNOR role
        assertEq(core.getRoleMember(Roles.TOKEN_GOVERNOR, 0), addresses.getAddress("GOVERNOR_DAO"));

        /// GUARDIAN role
        assertEq(core.getRoleMember(Roles.GUARDIAN, 0), addresses.getAddress("FINANCE_GUARDIAN"));
        assertEq(core.getRoleMember(Roles.GUARDIAN, 1), addresses.getAddress("GUARDIAN_MULTISIG"));

        /// FINANCIAL_CONTROLLER role
        assertEq(core.getRoleMember(Roles.FINANCIAL_CONTROLLER, 0), addresses.getAddress("FINANCE_GUARDIAN"));
        assertEq(core.getRoleMember(Roles.FINANCIAL_CONTROLLER, 1), addresses.getAddress("TREASURY_WALLET"));
        assertEq(core.getRoleMember(Roles.FINANCIAL_CONTROLLER, 2), addresses.getAddress("WETH_TREASURY_WALLET"));

        /// FINANCIAL_GUARDIAN role
        assertEq(core.getRoleMember(Roles.FINANCIAL_GUARDIAN, 0), addresses.getAddress("FINANCE_GUARDIAN_MULTISIG"));
    }
}
