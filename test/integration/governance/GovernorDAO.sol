// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Test} from "@forge-std/Test.sol";

import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {Addresses} from "@test/proposals/Addresses.sol";
import {TestProposals} from "@test/proposals/TestProposals.sol";
import {BaseTest} from "@test/integration/BaseTest.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {GovernorDAO} from "@protocol/governance/GovernorDAO.sol";
import {ERC20HoldingDeposit} from "@protocol/finance/ERC20HoldingDeposit.sol";
import {Token} from "@protocol/token/Token.sol";

/// @title Integration test for GovernorDAO
contract IntegrationTestGovernorDAO is BaseTest {
    enum VoteType {
        Against,
        For,
        Abstain
    }

    /// @notice setup the integration tests and select the fork
    function setUp() public override {
        super.setUp();
    }

    /// @notice Test and raise a DAO proposal to send funds
    function testRaiseAndVoteOnDAOProposal() public {
        address treasuryWallet = addresses.getAddress("TREASURY_WALLET");
        GovernorDAO governorDAO = GovernorDAO(payable(addresses.getAddress("GOVERNOR_DAO")));
        ERC20HoldingDeposit erc20HoldingDeposit = ERC20HoldingDeposit(treasuryWallet);

        /// setup calldata
        bytes memory func = abi.encodeWithSignature("withdraw(address,uint256)", address(this), 10_000e18);

        /// setup targets
        address[] memory targets = new address[](1);
        targets[0] = treasuryWallet;

        /// setup values
        uint256[] memory values = new uint256[](1);
        values[0] = 0; // no ETH will be sent

        /// setup calldata
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = func;

        /// Create users
        address user1 = address(1);
        address user2 = address(2);

        /// Fund users
        vm.prank(treasuryWallet);
        erc20HoldingDeposit.withdraw(user1, 100_000_000e18);

        vm.prank(treasuryWallet);
        erc20HoldingDeposit.withdraw(user2, 100_000_000e18);

        /// Test user balances are correct
        Token token = Token(addresses.getAddress("TOKEN"));
        assertEq(token.balanceOf(address(user1)), 100_000_000e18);
        assertEq(token.balanceOf(address(user2)), 100_000_000e18);

        /// Delegate votes
        vm.prank(user1);
        token.delegate(user1);

        vm.prank(user2);
        token.delegate(user2);

        /// Submit a proposal
        vm.prank(user1);
        vm.roll(block.number + 1);
        string memory description = "Funding request";
        uint256 proposalId = governorDAO.propose(targets, values, calldatas, description);
        vm.roll(block.number + 1);

        /// Check proposal
        vm.roll(block.number + 1);
        assertEq(uint256(governorDAO.state(proposalId)), uint256(IGovernor.ProposalState.Active));

        /// Vote and test voting weight
        vm.prank(user1);
        assertEq(governorDAO.castVote(proposalId, uint8(VoteType.For)), 100_000_000e18);

        vm.prank(user2);
        assertEq(governorDAO.castVote(proposalId, uint8(VoteType.For)), 100_000_000e18);

        /// Test voting weight
        assertEq(token.getVotes(address(user1)), 100_000_000e18);
        assertEq(token.getVotes(address(user2)), 100_000_000e18);

        /// Check still active
        assertEq(uint256(governorDAO.state(proposalId)), uint256(IGovernor.ProposalState.Active));
        vm.roll(block.number + 1);

        /// Check proposal passed
        vm.roll(block.number + 200_000);
        assertEq(uint256(governorDAO.state(proposalId)), uint256(IGovernor.ProposalState.Succeeded));

        /// Queue proposal
        _queueProposal(governorDAO, targets, values, calldatas, description);
        assertEq(uint256(governorDAO.state(proposalId)), uint256(IGovernor.ProposalState.Queued));

        /// Execute proposal
        _executeProposal(governorDAO, targets, values, calldatas, description);
        assertEq(uint256(governorDAO.state(proposalId)), uint256(IGovernor.ProposalState.Executed));

        /// Check balance
        assertEq(token.balanceOf(address(this)), 10_000e18);
    }

    /// @notice queue a proposal
    /// @param governorDAO the governor dao contract
    /// @param targets the targets of the proposal
    /// @param values the values of the proposal
    /// @param calldatas the calldatas of the proposal
    /// @param description the description of the proposal
    function _queueProposal(
        GovernorDAO governorDAO,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) private {
        governorDAO.queue(targets, values, calldatas, keccak256(bytes(description)));
    }

    /// @notice execute a proposal
    /// @param governorDAO the GovernorDAO contract
    /// @param targets the targets of the proposal
    /// @param values the values of the proposal
    /// @param calldatas the calldatas of the proposal
    /// @param description the description of the proposal
    function _executeProposal(
        GovernorDAO governorDAO,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) private {
        /// Time machine
        vm.warp(block.timestamp + 3 days);
        governorDAO.execute(targets, values, calldatas, keccak256(bytes(description)));
    }
}
