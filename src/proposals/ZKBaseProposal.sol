// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {IProposal} from "./IProposal.sol";
import {IAddressRegistry} from "@protocol/addresses/IAddressRegistry.sol";

/// @notice Base contract for ZK-compatible governance proposals
abstract contract ZKBaseProposal is IProposal {
    struct Action {
        address target;
        uint256 value;
        bytes arguments;
        string description;
    }

    /// @notice list of actions to be executed
    Action[] public actions;

    /// @notice Address registry
    IAddressRegistry public addressRegistry;

    /// @notice primary fork id (used only for compatibility)
    uint256 public primaryForkId;

    /// @notice build modifier for ZK context (simplified version)
    /// @dev In ZK context, we can't use VM for recording transactions
    /// Instead, actions must be added manually in buildMultisig implementation
    modifier buildModifier(address toPrank) {
        // In ZK context, this is a no-op
        _;
    }

    /// @notice run method (simplified for ZK context)
    function run() public virtual override {
        // Execute all stages
        deploy();
        afterDeployMock();
        build();
        simulate();
        validate();
        // No print in ZK context
    }

    /// @notice return proposal actions.
    function getProposalActions()
        public
        view
        virtual
        override
        returns (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory arguments
        )
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
        // ZK implementation doesn't check anything on-chain
        return false;
    }

    /// @notice add an action to the proposal
    function _addAction(
        address target,
        uint256 value,
        bytes memory data,
        string memory description
    ) internal virtual {
        require(target != address(0), "Target cannot be zero address");
        
        // Add action to list
        actions.push(Action({
            target: target,
            value: value,
            arguments: data,
            description: description
        }));
    }

    /// @notice helper to convert bytes to hex string (pure function)
    function _toHex(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = 0x30; // '0'
        str[1] = 0x78; // 'x'
        
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint8(data[i] >> 4)];
            str[3 + i * 2] = alphabet[uint8(data[i] & 0x0f)];
        }
        
        return string(str);
    }

    /// @notice helper to convert address to hex string (pure function)
    function _toHexString(address addr) internal pure returns (string memory) {
        bytes memory data = abi.encodePacked(addr);
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = 0x30; // '0'
        str[1] = 0x78; // 'x'
        
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

    /// @notice print function (no-op in ZK context)
    function print() public virtual override {
        // This is a no-op in ZK environments
        // Cannot use console in ZK context
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
}
