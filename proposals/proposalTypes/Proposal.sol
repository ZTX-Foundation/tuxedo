//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Test} from "@forge-std/Test.sol";
import {IProposal} from "@proposals/proposalTypes/IProposal.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {Addresses} from "@proposals/Addresses.sol";

abstract contract Proposal is IProposal, Test {
    bool public DEBUG = true;

    Core _core;

    function setDebug(bool value) external override {
        DEBUG = value;
    }

    /// @notice deployment of zip's contracts/features
    function deploy(Addresses addresses, address deployer) public virtual override;

    /// @notice runs after all deployments
    function afterDeploy(Addresses addresses, address deployer) public virtual override;

    /// @notice build governance proposal
    function build(Addresses addresses, address deployer) public virtual override;

    /// @notice run governance proposal onchain
    function run(Addresses addresses, address deployer) public virtual override;

    /// @notice teardown anything required
    function teardown(Addresses addresses, address deployer) public virtual override;

    /// @notice validate the deployment
    function validate(Addresses addresses, address deployer) public virtual override;

    function printProposalActionSteps() public virtual;    
}
