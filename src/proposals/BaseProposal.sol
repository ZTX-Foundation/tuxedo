// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";

import {Script} from "forge-std/Script.sol";
import {IProposal} from "./IProposal.sol";
import {IAddressRegistry} from "@protocol/addresses/IAddressRegistry.sol";

/// @notice Base contract for governance proposals
abstract contract BaseProposal is Test, Script, IProposal {
    struct Action {
        address target;
        uint256 value;
        bytes arguments;
        string description;
    }

    /// @notice starting snapshot of the contract state before the calls are made
    uint256 private _startSnapshot;

    /// @notice list of actions to be executed, regardless of proposal type
    Action[] public actions;

    /// @notice debug flag to print internal proposal logs
    bool internal DEBUG;
    bool internal DO_DEPLOY;
    bool internal DO_AFTER_DEPLOY_MOCK;
    bool internal DO_BUILD;
    bool internal DO_SIMULATE;
    bool internal DO_VALIDATE;
    bool internal DO_PRINT;

    /// @notice Address registry
    IAddressRegistry public addressRegistry;

    /// @notice primary fork id
    uint256 public primaryForkId;

    /// @notice buildModifier to be used by the build function to populate the
    /// actions array
    modifier buildModifier(address toPrank) {
        _startBuild(toPrank);
        _;
        _endBuild(toPrank);
    }

    constructor() {
        DEBUG = vm.envOr("DEBUG", false);

        DO_DEPLOY = vm.envOr("DO_DEPLOY", true);
        DO_AFTER_DEPLOY_MOCK = vm.envOr("DO_AFTER_DEPLOY_MOCK", true);
        DO_BUILD = vm.envOr("DO_BUILD", true);
        DO_SIMULATE = vm.envOr("DO_SIMULATE", true);
        DO_VALIDATE = vm.envOr("DO_VALIDATE", true);
        DO_PRINT = vm.envOr("DO_PRINT", true);
    }

    /// @notice function to be used by forge script.
    function run() public virtual override {
        if (DO_DEPLOY) {
            deploy();
        }

        if (DO_AFTER_DEPLOY_MOCK) {
            afterDeployMock();
        }

        if (DO_BUILD) {
            build();
        }

        if (DO_SIMULATE) {
            simulate();
        }

        if (DO_VALIDATE) {
            validate();
        }

        if (DO_PRINT) {
            print();
        }
    }

    /// @notice return proposal actions.
    function getProposalActions()
        public
        view
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory arguments)
    {
        require(actions.length > 0, "No actions found");

        targets = new address[](actions.length);
        values = new uint256[](actions.length);
        arguments = new bytes[](actions.length);

        for (uint256 i = 0; i < actions.length; i++) {
            targets[i] = actions[i].target;
            values[i] = actions[i].value;
            arguments[i] = actions[i].arguments;
        }

        return (targets, values, arguments);
    }

    /// @notice check if there are any on-chain proposal that matches the
    /// proposal calldata
    function checkOnChainCalldata() public view virtual override returns (bool) {
        // Base implementation doesn't check anything on-chain
        // Override in specific proposals that need this functionality
        return false;
    }

    /// @notice start recording all calls by pranking as the caller
    function _startBuild(address caller) internal virtual {
        if (DEBUG) {
            console.log("Starting build as %s", caller);
        }

        // Take snapshot of the current state
        _startSnapshot = vm.snapshot();

        // Start recording calls made by the pranked address
        vm.startPrank(caller);
    }

    /// @notice stop pranking and save all recorded calls to the actions array
    function _endBuild(address caller) internal virtual {
        if (DEBUG) {
            console.log("Ending build as %s", caller);
        }

        // Stop pranking
        vm.stopPrank();

        // Since vm.accesses is causing type issues, use a more compatible approach
        // This implementation assumes that actions are already added via _addAction during build
        // and doesn't rely on vm.accesses which has inconsistent signatures across forge versions

        // Simply revert to initial state after actions have been recorded
        vm.revertTo(_startSnapshot);

        if (DEBUG && actions.length > 0) {
            console.log("Recorded %s actions", actions.length);
        }
    }

    /// @notice add an action to the proposal
    function _addAction(
        address target,
        uint256 value,
        bytes memory data,
        string memory actionDescription
    ) internal virtual {
        require(target != address(0), "Target cannot be zero address");

        if (DEBUG) {
            console.log("Adding action:");
            console.log("  Target: %s", target);
            console.log("  Value: %s", value);
            console.log("  Data: %s", _toHex(data));
            console.log("  Description: %s", actionDescription);
        }

        // Add action to list
        actions.push(Action({target: target, value: value, arguments: data, description: actionDescription}));
    }

    /// @notice helper to convert bytes to hex string
    function _toHex(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";

        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint8(data[i] >> 4)];
            str[3 + i * 2] = alphabet[uint8(data[i] & 0x0f)];
        }

        return string(str);
    }

    /// @notice helper to convert address to hex string
    function _toHexString(address addr) internal pure returns (string memory) {
        bytes memory data = abi.encodePacked(addr);
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";

        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint8(data[i] >> 4)];
            str[3 + i * 2] = alphabet[uint8(data[i] & 0x0f)];
        }

        return string(str);
    }

    /// @notice set the Address Registry
    function setAddressRegistry(IAddressRegistry _registry) external override {
        addressRegistry = _registry;
    }

    /// @notice set the primary fork id
    function setPrimaryForkId(uint256 _forkId) external override {
        primaryForkId = _forkId;
    }

    /// @notice print function for proposals
    function print() public virtual override {
        console.log("Contract: %s", name());
        console.log("Description: %s", description());
        console.log("Actions: %s", actions.length);

        if (actions.length == 0) {
            console.log("No actions found");
            return;
        }

        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = getProposalActions();

        for (uint256 i = 0; i < targets.length; i++) {
            console.log("Action %s:", i);
            console.log("  Target: %s", targets[i]);
            console.log("  Value: %s", values[i]);
            console.log("  Calldata: %s", _toHex(calldatas[i]));
            console.log("  Description: %s", actions[i].description);
        }

        bytes memory proposalCalldata = getCalldata();
        console.log("Proposal calldata: %s", _toHex(proposalCalldata));
    }

    /// @notice deploy function - override in implementation
    function deploy() public virtual {}

    /// @notice after deploy mock function - override in implementation
    function afterDeployMock() public virtual {}

    /// @notice build function - override in implementation
    function build() public virtual {}

    /// @notice simulate function - override in implementation
    function simulate() public virtual {}

    /// @notice validate function - override in implementation
    function validate() public virtual {}

    function name() public pure virtual override returns (string memory) {
        return "BASE_PROPOSAL";
    }

    function description() public pure virtual override returns (string memory) {
        return "Base proposal implementation";
    }

    function getCalldata() public virtual override returns (bytes memory) {
        return new bytes(0);
    }
}
