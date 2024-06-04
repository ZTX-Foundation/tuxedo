//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";
import {TimelockProposal} from "@proposals/proposalTypes/TimelockProposal.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {Token, MAX_SUPPLY} from "@protocol/token/Token.sol";
import {ERC20HoldingDeposit} from "@protocol/finance/ERC20HoldingDeposit.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {Constants} from '@proposals/utils/Constants.sol';

contract zip002 is TimelockProposal {
    TimelockController private _adminTimelock;
    Core private _core;

    string private constant ADDRESSES_PATH = "proposals/Addresses.json";

    constructor() Proposal("ADMIN_MULTISIG") {}

    // Returns the name of the proposal.
    function name() public pure override returns (string memory) {
        return "ZIP002";
    }

    // Provides a brief description of the proposal.
    function description() public pure override returns (string memory) {
        return "The ZTX TimeLock contract proposal";
    }

    function _beforeDeploy() internal override {
        /// Get Core Address
        _core = Core(addresses.getAddress("CORE"));
    }

    function _deploy() internal override {
        /// Admin timelock controller
        address[] memory adminTimelockProposersExecutors = new address[](1);

        adminTimelockProposersExecutors[0] = address(addresses.getAddress("ADMIN_MULTISIG"));
        _adminTimelock = new TimelockController(
            0, // zero delay
            adminTimelockProposersExecutors,
            adminTimelockProposersExecutors,
            address(0) // No admin requried
        );
        addresses.addAddress("ADMIN_TIMELOCK_CONTROLLER", address(_adminTimelock), true);
    }

    function _afterDeploy() internal override {
        /// For the sake of testing, give the ADMIN role to the ADMIN_TIMELOCK_CONTROLLER.
        /// This is not possible onchain as the deployer is not an Admin
        if (block.chainid != Constants.ARBITRUM_MAINNET) {
            _core.grantRole(Roles.ADMIN, addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"));
        }

        /// The ADMIN_MULTISIG now needs to give the ADMIN role to the ADMIN_TIMELOCK_CONTROLLER
        console.log("Please give Roles.Admin to the ADMIN_TIMELOCK_CONTROLLER from the ADMIN_MULTISIG");
    }

    function _validate() internal override {
        /// Check that the ADMIN_MULTISIG has the PROPOSER role
        assertEq(
            _adminTimelock.hasRole(_adminTimelock.PROPOSER_ROLE(), addresses.getAddress("ADMIN_MULTISIG")),
            true,
            "ADMIN_MULTISIG does not have PROPOSER_ROLE"
        );

        /// Check that the ADMIN_MULTISIG has the EXECUTOR role
        assertEq(
            _adminTimelock.hasRole(_adminTimelock.EXECUTOR_ROLE(), addresses.getAddress("ADMIN_MULTISIG")),
            true,
            "ADMIN_MULTISIG does not have EXECUTOR_ROLE"
        );

        /// Check that the ADMIN_MULTISIG has the CANCELLER rol`e
        assertEq(
            _adminTimelock.hasRole(_adminTimelock.CANCELLER_ROLE(), addresses.getAddress("ADMIN_MULTISIG")),
            true,
            "ADMIN_MULTISIG does not have CANCELLER_ROLE"
        );
    }
}
