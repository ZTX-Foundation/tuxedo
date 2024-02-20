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
import {GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {ERC20HoldingDeposit} from "@protocol/finance/ERC20HoldingDeposit.sol";
import {ERC1155SeasonOne} from "@protocol/nfts/seasons/ERC1155SeasonOne.sol";
import {ERC1155SeasonTwo} from "@protocol/nfts/seasons/ERC1155SeasonTwo.sol";
import {SeasonsTokenIdRegistry} from "@protocol/nfts/seasons/SeasonsTokenIdRegistry.sol";
import {TokenIdRewardAmount} from "@protocol/nfts/seasons/SeasonsBase.sol";

contract zipTest is Proposal, TimelockProposal {
    address[] public whitelistAddresses;

    constructor() {
        name = "ZIPTest";
        description = "The Last ZTX Proposal (For Testing only)";
    }

    function _beforeDeploy(Addresses addresses, address) internal override {
        _core = Core(addresses.getCore());
    }

    function _deploy(Addresses addresses, address deployer) internal override {
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
            addresses.addAddress("BURNER_HOLDING_DEPOSIT", address(burnHoldingDeposit));

            ERC20HoldingDeposit wethTreasuryHoldingDeposit = new ERC20HoldingDeposit(
                address(_core),
                addresses.getAddress("WETH")
            );
            addresses.addAddress("WETH_TREASURY_HOLDING_DEPOSIT", address(wethTreasuryHoldingDeposit));

            /// ERC1155Sale Splitter
            ERC20Splitter.Allocation[] memory wethAllocations = new ERC20Splitter.Allocation[](2);
            wethAllocations[0].deposit = addresses.getAddress("WETH_TREASURY_HOLDING_DEPOSIT");
            wethAllocations[0].ratio = 5_000;
            wethAllocations[1].deposit = addresses.getAddress("WETH_TREASURY_HOLDING_DEPOSIT");
            wethAllocations[1].ratio = 5_000;

            ERC20Splitter erc1155SaleSplitter = new ERC20Splitter(
                address(_core),
                addresses.getAddress("WETH"),
                wethAllocations
            );
            addresses.addAddress("ERC1155_SALE_SPLITTER", address(erc1155SaleSplitter));
        }
    }

    function _afterDeploy(Addresses addresses, address) internal override {
        /// ADMIN role
        _core.grantRole(Roles.ADMIN, addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"));

        /// LOCKER role
        _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_SALE_CONSUMABLES"));
        _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_SALE_PLACEABLES"));
        _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_SALE_WEARABLES"));

        /// MINTER role
        _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_SALE_CONSUMABLES"));
        _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_SALE_PLACEABLES"));
        _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, addresses.getAddress("ERC1155_SALE_WEARABLES"));

        /// TOKEN_GOVERNOR role
        _core.grantRole(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, addresses.getAddress("GOVERNOR_DAO"));

        /// GUARDIAN role
        _core.grantRole(Roles.GUARDIAN, addresses.getAddress("GUARDIAN_MULTISIG"));

        /// FINANCIAL_CONTROLLER role
        _core.grantRole(Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE, addresses.getAddress("TREASURY_WALLET_MULTISIG"));
        _core.grantRole(
            Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE,
            addresses.getAddress("WETH_TREASURY_HOLDING_DEPOSIT")
        );
        _core.grantRole(
            Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE,
            addresses.getAddress("GOVERNOR_DAO_TIMELOCK_CONTROLLER")
        );

        /// FINANCIAL_GUARDIAN Role
        _core.grantRole(Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE, addresses.getAddress("FINANCE_GUARDIAN_MULTISIG"));
    }

    function _aferDeployForTestingOnly(Addresses, address deployer) internal virtual override {}

    function _afterDeployOnMainNet(Addresses, address deployer) internal virtual override {}

    function _build(Addresses addresses, address deployer) internal override {}

    function _run(Addresses addresses, address deployer) internal override {}

    function _teardown(Addresses addresses, address deployer) internal override {}

    function _validate(Addresses addresses, address) internal override {
        assertEq(
            address(ERC1155Sale(addresses.getAddress("ERC1155_SALE_CONSUMABLES")).core()),
            address(_core),
            "ERC1155Sale core address is not equal to core address"
        );
        assertEq(
            address(ERC1155Sale(addresses.getAddress("ERC1155_SALE_WEARABLES")).core()),
            address(_core),
            "ERC1155Sale core address is not equal to core address"
        );
        assertEq(
            address(ERC1155Sale(addresses.getAddress("ERC1155_SALE_PLACEABLES")).core()),
            address(_core),
            "ERC1155Sale core address is not equal to core address"
        );

        assertEq(
            address(ERC20HoldingDeposit(addresses.getAddress("WETH_ERC20_HOLDING_DEPOSIT")).core()),
            address(_core),
            "ERC20HoldingDeposit core address is not equal to core address"
        );

        assertEq(
            address(CoreRef(addresses.getAddress("CONSUMABLE_SPLITTER")).core()),
            address(_core),
            "CONSUMABLE_SPLITTER is pointing to wrong core"
        );
        assertEq(
            address(CoreRef(addresses.getAddress("BURNER_HOLDING_DEPOSIT")).core()),
            address(_core),
            "BURNER_HOLDING_DEPOSIT is pointing to wrong core"
        );

        /// ERC1155Sale
        ERC20Splitter.Allocation[] memory erc1155SaleAllocations = ERC20Splitter(
            addresses.getAddress("ERC1155_SALE_SPLITTER")
        ).getAllocations();

        assertEq(erc1155SaleAllocations.length, 2, "ERC1155Sale allocations length is not equal to 2");
        assertEq(
            erc1155SaleAllocations[0].deposit,
            addresses.getAddress("WETH_TREASURY_HOLDING_DEPOSIT"),
            "ERC1155Sale allocation deposit is not equal to WETH_TREASURY_HOLDING_DEPOSIT"
        );
        assertEq(erc1155SaleAllocations[0].ratio, 5_000);
        assertEq(
            erc1155SaleAllocations[1].deposit,
            addresses.getAddress("WETH_TREASURY_HOLDING_DEPOSIT"),
            "ERC1155Sale allocation deposit is not equal to WETH_TREASURY_HOLDING_DEPOSIT"
        );
        assertEq(erc1155SaleAllocations[1].ratio, 5_000, "ERC1155Sale allocation ratio is not equal to 5_000");

        assertEq(
            address(ERC20Splitter(addresses.getAddress("ERC1155_SALE_SPLITTER")).core()),
            address(_core),
            "ERC1155_SALE_SPLITTER is pointing to wrong core"
        );

        /// Check that right number of roles has been assigned
        assertEq(
            _core.getRoleMemberCount(Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE),
            4,
            "FINANCIAL_CONTROLLER_PROTOCOL_ROLE count is not equal to 4"
        );
        assertEq(_core.getRoleMemberCount(Roles.GUARDIAN), 1, "GUARDIAN count is not equal to 1");
        assertEq(
            _core.getRoleMemberCount(Roles.LOCKER_PROTOCOL_ROLE),
            8,
            "LOCKER_PROTOCOL_ROLE count is not equal to 8"
        );
        assertEq(
            _core.getRoleMemberCount(Roles.MINTER_PROTOCOL_ROLE),
            6,
            "MINTER_PROTOCOL_ROLE count is not equal to 8"
        );

        /// TOKEN_GOVERNOR role
        assertEq(_core.getRoleMember(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, 0), addresses.getAddress("GOVERNOR_DAO"));

        /// GUARDIAN role
        assertEq(_core.getRoleMember(Roles.GUARDIAN, 0), addresses.getAddress("GUARDIAN_MULTISIG"));

        /// FINANCIAL_CONTROLLER role
        assertEq(
            _core.getRoleMember(Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE, 0),
            addresses.getAddress("TREASURY_WALLET_MULTISIG")
        );
        assertEq(
            _core.getRoleMember(Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE, 1),
            addresses.getAddress("WETH_TREASURY_HOLDING_DEPOSIT")
        );
    }

    function _validateForTestingOnly(Addresses, address deployer) internal virtual override {}

    function _validateOnMainNet(Addresses, address deployer) internal virtual override {}

    function _validateOnTestNet(Addresses, address deployer) internal virtual override {}
}
