//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";
import {TimelockProposal} from "@proposals/proposalTypes/TimelockProposal.sol";

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

contract zipTest is Proposal, TimelockProposal {
    string public name = "ZIPTest";
    string public description = "The Last ZTX Proposal (For Testing only)";

    address[] public whitelistAddresses;

    function deploy(Addresses addresses, address deployer) public override {
        {
            ERC20HoldingDeposit wethErc20HoldingDeposit = new ERC20HoldingDeposit(
                address(_core),
                addresses.getAddress("WETH")
            );

            addresses.addAddress("WETH_ERC20_HOLDING_DEPOSIT", address(wethErc20HoldingDeposit));
        }

        {
            /// ERC1155Sale
            ERC1155Sale consumablesERC1155Sale = new ERC1155Sale(
                address(_core),
                addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES"),
                addresses.getAddress("WETH")
            );
            addresses.addAddress("ERC1155_SALE_CONSUMABLES", address(consumablesERC1155Sale));

            ERC1155Sale placeablesERC1155Sale = new ERC1155Sale(
                address(_core),
                addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
                addresses.getAddress("WETH")
            );
            addresses.addAddress("ERC1155_SALE_PLACEABLES", address(placeablesERC1155Sale));

            ERC1155Sale wearablesERC1155Sale = new ERC1155Sale(
                address(_core),
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
                address(_core),
                addresses.getAddress("FINANCE_GUARDIAN_SAFE_ADDRESS"),
                whitelistAddresses
            );

            addresses.addAddress("FINANCE_GUARDIAN", address(financeGuardian));
        }

        {
            /// Timelock Controller (Governor Bravo DAO)
            address governorDAOTimelockAdmin = deployer;

            // /// @notice set a temporary admin and then transfer
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
                address(_core),
                addresses.getAddress("TOKEN")
            );
            addresses.addAddress("BURNER_WALLET", address(burnHoldingDeposit));

            ERC20HoldingDeposit wethTreasuryHoldingDeposit = new ERC20HoldingDeposit(
                address(_core),
                addresses.getAddress("WETH")
            );
            addresses.addAddress("WETH_TREASURY_WALLET", address(wethTreasuryHoldingDeposit));

            ERC20Splitter.Allocation[] memory allocations = new ERC20Splitter.Allocation[](2);
            allocations[0].deposit = addresses.getAddress("BURNER_WALLET");
            allocations[0].ratio = 5_000;
            allocations[1].deposit = addresses.getAddress("TREASURY_WALLET");
            allocations[1].ratio = 5_000;

            /// ERC20Splitter
            ERC20Splitter consumableSplitter = new ERC20Splitter(
                address(_core),
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
                address(_core),
                addresses.getAddress("WETH"),
                wethAllocations
            );
            addresses.addAddress("ERC1155_SALE_SPLITTER", address(erc1155SaleSplitter));

            /// Game consumer
            GameConsumer consumer = new GameConsumer(
                address(_core),
                addresses.getAddress("TOKEN"),
                addresses.getAddress("GAME_CONSUMER_PAYMENT_RECIPIENT"),
                addresses.getAddress("WETH")
            );

            addresses.addAddress("GAME_CONSUMABLE", address(consumer));
        }
    }

    function afterDeploy(Addresses addresses, address) public override {
        /// ADMIN role
        _core.grantRole(Roles.ADMIN, addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"));

        /// LOCKER role
        _core.grantRole(Roles.LOCKER, addresses.getAddress("ERC1155_SALE_CONSUMABLES"));
        _core.grantRole(Roles.LOCKER, addresses.getAddress("ERC1155_SALE_PLACEABLES"));
        _core.grantRole(Roles.LOCKER, addresses.getAddress("ERC1155_SALE_WEARABLES"));

        /// MINTER role
        _core.grantRole(Roles.MINTER, addresses.getAddress("ERC1155_SALE_CONSUMABLES"));
        _core.grantRole(Roles.MINTER, addresses.getAddress("ERC1155_SALE_PLACEABLES"));
        _core.grantRole(Roles.MINTER, addresses.getAddress("ERC1155_SALE_WEARABLES"));

        /// TOKEN_GOVERNOR role
        _core.grantRole(Roles.TOKEN_GOVERNOR, addresses.getAddress("GOVERNOR_DAO"));

        /// GUARDIAN role
        _core.grantRole(Roles.GUARDIAN, addresses.getAddress("FINANCE_GUARDIAN"));
        _core.grantRole(Roles.GUARDIAN, addresses.getAddress("GUARDIAN_MULTISIG"));

        /// FINANCIAL_CONTROLLER role
        _core.grantRole(Roles.FINANCIAL_CONTROLLER, addresses.getAddress("FINANCE_GUARDIAN"));
        _core.grantRole(Roles.FINANCIAL_CONTROLLER, addresses.getAddress("TREASURY_WALLET"));
        _core.grantRole(Roles.FINANCIAL_CONTROLLER, addresses.getAddress("WETH_TREASURY_WALLET"));
        _core.grantRole(Roles.FINANCIAL_CONTROLLER, addresses.getAddress("GOVERNOR_DAO_TIMELOCK_CONTROLLER"));

        /// FINANCIAL_GUARDIAN Role
        _core.grantRole(Roles.FINANCIAL_GUARDIAN, addresses.getAddress("FINANCE_GUARDIAN_MULTISIG"));
    }

    function build(Addresses addresses, address deployer) public override {}

    function run(Addresses addresses, address deployer) public override {}

    function teardown(Addresses addresses, address deployer) public override {}

    function validate(Addresses addresses, address) public override {
        assertEq(address(ERC1155Sale(addresses.getAddress("ERC1155_SALE_CONSUMABLES")).core()), address(_core));
        assertEq(address(ERC1155Sale(addresses.getAddress("ERC1155_SALE_WEARABLES")).core()), address(_core));
        assertEq(address(ERC1155Sale(addresses.getAddress("ERC1155_SALE_PLACEABLES")).core()), address(_core));

        assertEq(
            address(ERC20HoldingDeposit(addresses.getAddress("WETH_ERC20_HOLDING_DEPOSIT")).core()),
            address(_core)
        );

        assertEq(address(FinanceGuardian(addresses.getAddress("FINANCE_GUARDIAN")).core()), address(_core));

        assertEq(address(CoreRef(addresses.getAddress("CONSUMABLE_SPLITTER")).core()), address(_core));
        assertEq(address(CoreRef(addresses.getAddress("BURNER_WALLET")).core()), address(_core));

        /// ERC1155Sale
        ERC20Splitter.Allocation[] memory erc1155SaleAllocations = ERC20Splitter(
            addresses.getAddress("ERC1155_SALE_SPLITTER")
        ).getAllocations();

        assertEq(erc1155SaleAllocations.length, 2);
        assertEq(erc1155SaleAllocations[0].deposit, addresses.getAddress("WETH_TREASURY_WALLET"));
        assertEq(erc1155SaleAllocations[0].ratio, 5_000);
        assertEq(erc1155SaleAllocations[1].deposit, addresses.getAddress("WETH_TREASURY_WALLET"));
        assertEq(erc1155SaleAllocations[1].ratio, 5_000);

        assertEq(address(ERC20Splitter(addresses.getAddress("ERC1155_SALE_SPLITTER")).core()), address(_core));

        /// Game consumable
        ERC20Splitter.Allocation[] memory consumableAllocations = ERC20Splitter(
            addresses.getAddress("CONSUMABLE_SPLITTER")
        ).getAllocations();

        assertEq(consumableAllocations.length, 2);
        assertEq(consumableAllocations[0].deposit, addresses.getAddress("BURNER_WALLET"));
        assertEq(consumableAllocations[0].ratio, 5_000);
        assertEq(consumableAllocations[1].deposit, addresses.getAddress("TREASURY_WALLET"));
        assertEq(consumableAllocations[1].ratio, 5_000);

        assertEq(address(ERC20Splitter(addresses.getAddress("CONSUMABLE_SPLITTER")).core()), address(_core));

        /// Check that right number of roles has been assigned
        assertEq(_core.getRoleMemberCount(Roles.FINANCIAL_CONTROLLER), 4);
        assertEq(_core.getRoleMemberCount(Roles.GUARDIAN), 2);
        assertEq(_core.getRoleMemberCount(Roles.FINANCIAL_GUARDIAN), 1);
        assertEq(_core.getRoleMemberCount(Roles.LOCKER), 8);
        assertEq(_core.getRoleMemberCount(Roles.MINTER), 8);

        /// ADMIN role
        // assertEq(_core.getRoleMember(Roles.ADMIN, 1), addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"));

        /// TOKEN_GOVERNOR role
        assertEq(_core.getRoleMember(Roles.TOKEN_GOVERNOR, 0), addresses.getAddress("GOVERNOR_DAO"));

        /// GUARDIAN role
        assertEq(_core.getRoleMember(Roles.GUARDIAN, 0), addresses.getAddress("FINANCE_GUARDIAN"));
        assertEq(_core.getRoleMember(Roles.GUARDIAN, 1), addresses.getAddress("GUARDIAN_MULTISIG"));

        /// FINANCIAL_CONTROLLER role
        assertEq(_core.getRoleMember(Roles.FINANCIAL_CONTROLLER, 0), addresses.getAddress("FINANCE_GUARDIAN"));
        assertEq(_core.getRoleMember(Roles.FINANCIAL_CONTROLLER, 1), addresses.getAddress("TREASURY_WALLET"));
        assertEq(_core.getRoleMember(Roles.FINANCIAL_CONTROLLER, 2), addresses.getAddress("WETH_TREASURY_WALLET"));

        /// FINANCIAL_GUARDIAN role
        assertEq(_core.getRoleMember(Roles.FINANCIAL_GUARDIAN, 0), addresses.getAddress("FINANCE_GUARDIAN_MULTISIG"));
    }
}
