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

    function setDebug(bool value) external {
        DEBUG = value;
    }

    /// @notice run the deployment for testing only. ie intergration testing with foundry
    /// @dev this is not run on-chain, and is only used with the foundry `forge test` command
    function deployForTestingOnly(Addresses addresses, address deployer) public {
        vm.startBroadcast(deployer);

        _beforeDeploy(addresses, deployer);
        _deploy(addresses, deployer);
        _afterDeploy(addresses, deployer);
        _aferDeployForTestingOnly(addresses, deployer);

        vm.stopBroadcast();

        _build(addresses, deployer);
        _run(addresses, deployer);

        _teardown(addresses, deployer);
        _validate(addresses, deployer);
        _validateForTestingOnly(addresses, deployer);
    }

    /// @notice run the deployment on-chain
    /// @dev this is run on-chain and is used with the foundry `forge script` command
    function deployOnChain(Addresses addresses, uint256 privateKey) public {
        address deployer = vm.addr(privateKey);

        // start broadcast
        vm.startBroadcast(privateKey);
        _beforeDeploy(addresses, deployer);
        _deploy(addresses, deployer);
        _afterDeploy(addresses, deployer);
        _afterDeployOnChain(addresses, deployer);
        vm.stopBroadcast();

        _build(addresses, deployer);
        _run(addresses, deployer);

        _teardown(addresses, deployer);
        _validate(addresses, deployer);
        _validateOnChain(addresses, deployer); // check admin role was revoked
    }

    function validOnChain(Addresses addresses, uint256 privateKey) public {
        address deployer = address(0);

        _beforeDeploy(addresses, deployer);

        _build(addresses, deployer);
        _run(addresses, deployer);

        _teardown(addresses, deployer);
        _validate(addresses, deployer);
        _validateOnChain(addresses, deployer); // check admin role was revoked
    }

    /// @notice runs before all deployments.
    /// @dev a place to put pre-deployment checks
    function _beforeDeploy(Addresses addresses, address deployer) internal virtual;

    /// @notice deployment of zip's contracts/features
    function _deploy(Addresses addresses, address deployer) internal virtual;

    /// @notice runs after all deployments
    function _afterDeploy(Addresses addresses, address deployer) internal virtual;

    /// @notice runs after all deployments for testing only
    /// @dev as an example in testing mode we dont drop the admin role as its needed for further deployments in an automated test
    function _aferDeployForTestingOnly(Addresses, address deployer) internal virtual;

    /// @notice runs after all deployments on-chain only and will ensure that admin role is revoked from deployer
    /// @dev Revoked admin role after all deployments and needs to added again before another deployment can be done.
    function _afterDeployOnChain(Addresses, address deployer) internal virtual;

    /// @notice build governance proposal
    function _build(Addresses addresses, address deployer) internal virtual;

    /// @notice run governance proposal onchain
    function _run(Addresses addresses, address deployer) internal virtual;

    /// @notice teardown anything required
    function _teardown(Addresses addresses, address deployer) internal virtual;

    /// @notice validate the deployment
    function _validate(Addresses addresses, address deployer) internal virtual;

    /// @notice validate the deployment for testing only
    /// @dev as an example in testing mode we dont drop the admin role as its needed for further deployments in an automated test
    function _validateForTestingOnly(Addresses, address deployer) internal virtual;

    /// @notice validate the deployment on-chain only
    function _validateOnChain(Addresses, address deployer) internal virtual;
}
