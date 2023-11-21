// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Governor, IGovernor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {GovernorTimelockControl} from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import {GovernorVotes, IERC165} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {Roles} from "@protocol/core/Roles.sol";

/// @title Governor contract.
contract GovernorDAO is
    CoreRef,
    Governor,
    GovernorVotes,
    GovernorTimelockControl,
    GovernorSettings,
    GovernorCountingSimple
{
    /// @notice Private storage variable for quorum (the minimum number of votes needed for a vote to pass).
    uint256 private _quorum;

    /// @notice Emitted when quorum is updated.
    event QuorumUpdated(uint256 oldQuorum, uint256 newQuorum);

    constructor(
        string memory name,
        address _core,
        address _timelock,
        address _token,
        uint256 initialVotingDelay,
        uint256 initialVotingPeriod,
        uint256 initialProposalThreshold,
        uint256 initialQuorum
    )
        CoreRef(_core)
        Governor(name)
        GovernorVotes(IVotes(_token))
        GovernorTimelockControl(TimelockController(payable(_timelock)))
        GovernorSettings(initialVotingDelay, initialVotingPeriod, initialProposalThreshold)
    {
        require(initialQuorum > 0, "GovernorDAO: quorum must be greater than 0");
        _setQuorum(initialQuorum);
    }

    /// @notice The minimum number of votes needed for a vote to pass.
    function quorum(uint256 /* blockNumber*/) public view override returns (uint256) {
        return _quorum;
    }

    // @dev Internal setter for the proposal quorum. Emits a {QuorumUpdated} event.
    function _setQuorum(uint256 newQuorum) internal {
        emit QuorumUpdated(_quorum, newQuorum);
        _quorum = newQuorum;
    }

    /// @notice Override of a GovernorSettings function, to restrict to TOKEN_GOVERNOR role.
    /// @param newVotingDelay The new voting delay, in blocks
    function setVotingDelay(uint256 newVotingDelay) public override onlyRole(Roles.DAO_GOVERNOR_PROTOCOL_ROLE) {
        _setVotingDelay(newVotingDelay);
    }

    /// @notice Override of a GovernorSettings function, to restrict to Core TOKEN_GOVERNOR role.
    /// @param newVotingPeriod The new voting period, in blocks
    function setVotingPeriod(uint256 newVotingPeriod) public override onlyRole(Roles.DAO_GOVERNOR_PROTOCOL_ROLE) {
        _setVotingPeriod(newVotingPeriod);
    }

    /// @notice Override of a GovernorSettings.sol function, to restrict to Core TOKEN_GOVERNOR role.
    function setProposalThreshold(uint256 newProposalThreshold) public override onlyRole(Roles.DAO_GOVERNOR_PROTOCOL_ROLE) {
        _setProposalThreshold(newProposalThreshold);
    }

    /// @notice Adjust quorum, restricted to TOKEN_GOVERNOR role.
    function setQuorum(uint256 newQuorum) public onlyRole(Roles.DAO_GOVERNOR_PROTOCOL_ROLE) {
        require(newQuorum > 0, "GovernorDAO: quorum must be greater than 0");
        _setQuorum(newQuorum);
    }

    /// @notice Allow guardian to cancel a proposal in progress.
    function cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public onlyRole(Roles.GUARDIAN) returns (uint256) {
        return _cancel(targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    function state(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (ProposalState) {
        return super.state(proposalId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(Governor, GovernorTimelockControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
