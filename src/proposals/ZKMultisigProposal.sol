// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {ZKBaseProposal} from "./ZKBaseProposal.sol";

/// @notice ZK-compatible multisig proposal implementation
abstract contract ZKMultisigProposal is ZKBaseProposal {
    // Gnosis Safe selectors
    bytes4 constant EXEC_TRANSACTION_FROM_MODULE = bytes4(keccak256("execTransactionFromModule(address,uint256,bytes,uint8)"));
    bytes4 constant EXEC_TRANSACTION = bytes4(keccak256("execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)"));
    
    /// @notice gnosis safe multisig address
    address public gnosisSafe;

    /// @notice operation type (call, delegatecall, etc)
    uint8 public operation;

    /// @notice Constructor with direct multisig address
    /// @param _gnosisSafe Address of the gnosis safe multisig
    /// @param _operation Operation type (0 = Call, 1 = DelegateCall)
    constructor(address _gnosisSafe, uint8 _operation) {
        require(_gnosisSafe != address(0), "ZKMultisigProposal: zero address");
        gnosisSafe = _gnosisSafe;
        operation = _operation;
    }

    /// @notice Check if there are any on-chain proposals that match this calldata
    /// @dev ZK-safe implementation always returns false
    function checkOnChainCalldata() public view virtual override returns (bool) {
        return false; // ZK-safe implementation
    }

    /// @notice Build the multisig proposal actions
    function build() public virtual override {
        buildMultisig(gnosisSafe);
    }

    /// @notice Build function for multisig proposals
    /// @dev Override this method to define the proposal's actions
    function buildMultisig(address multisig) internal virtual;

    /// @notice Get calldata for executing the proposal via gnosis multisig
    function getCalldata() public virtual override returns (bytes memory data) {
        (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory arguments
        ) = getProposalActions();

        require(targets.length > 0, "ZKMultisigProposal: no actions");
        
        // For a single action, return the direct calldata
        if (targets.length == 1) {
            data = abi.encodeWithSelector(
                EXEC_TRANSACTION,
                targets[0],
                values[0],
                arguments[0],
                operation,
                0, // safeTxGas
                0, // baseGas
                0, // gasPrice
                address(0), // gasToken
                address(0), // refundReceiver
                new bytes(0) // signatures
            );
        } else {
            // In ZK context, we don't handle multiple actions for simplicity
            // A more complete implementation would compute this properly
            data = new bytes(0);
        }
    }
    
    /// @notice Simulate the multisig proposal (ZK-compatible no-op version)
    function simulate() public virtual override {
        // In ZK context, we don't have VM to simulate execution
        // This function is a no-op or would contain custom ZK-specific logic
    }
}
