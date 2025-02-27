// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {console} from "forge-std/console.sol";
import {BaseProposal} from "./BaseProposal.sol";
import {IAddressRegistry} from "../addresses/IAddressRegistry.sol";
import {AddressRegistryFactory} from "../utils/AddressRegistryFactory.sol";

/// @notice Proposal for multisig execution
abstract contract MultisigProposal is BaseProposal {
    // Gnosis Safe selectors
    bytes4 constant EXEC_TRANSACTION_FROM_MODULE = bytes4(keccak256("execTransactionFromModule(address,uint256,bytes,uint8)"));
    bytes4 constant EXEC_TRANSACTION = bytes4(keccak256("execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)"));
    
    /// @notice gnosis safe multisig address
    address public gnosisSafe;

    /// @notice operation type (call, delegatecall, etc)
    uint8 public operation;

    /// @notice Unified constructor that supports both initialization methods
    /// @param addressesPath Path to the addresses JSON file (optional)
    /// @param multisigName Name of the multisig in the address registry (optional)
    /// @param directSafe Direct address of the gnosis safe (optional)
    /// @param directOperation Operation type when using direct address (optional)
    constructor(
        string memory addressesPath,
        string memory multisigName,
        address directSafe,
        uint8 directOperation
    ) {
        // Case 1: Initialize from address registry file
        if (bytes(addressesPath).length > 0 && bytes(multisigName).length > 0) {
            // Load addresses from file using factory
            AddressRegistryFactory factory = new AddressRegistryFactory();
            addressRegistry = factory.createFromFile(addressesPath);
            
            // Set multisig address from registry
            gnosisSafe = addressRegistry.getAddress(multisigName);
            require(gnosisSafe != address(0), "MultisigProposal: multisig address not found");
            
            // Default to Call operation (0)
            operation = 0;
        }
        // Case 2: Initialize with direct address
        else if (directSafe != address(0)) {
            gnosisSafe = directSafe;
            operation = directOperation;
        }
        else {
            revert("MultisigProposal: invalid constructor parameters");
        }
    }

    // /// @notice Constructor with only file-based initialization (backward compatibility)
    // /// @param addressesPath Path to the addresses JSON file
    // /// @param multisigName Name of the multisig in the address registry
    // constructor(string memory addressesPath, string memory multisigName) 
    //     MultisigProposal(addressesPath, multisigName, address(0), 0) {}

    // /// @notice Constructor with only direct address initialization (backward compatibility)
    // /// @param _gnosisSafe Address of the gnosis safe multisig
    // /// @param _operation Operation type (0 = Call, 1 = DelegateCall)
    // constructor(address _gnosisSafe, uint8 _operation)
    //     MultisigProposal("", "", _gnosisSafe, _operation) {}

    /// @notice build function to populate actions
    function build() public virtual override {
        buildMultisig(gnosisSafe);
    }

    /// @notice internal function to build the multisig proposal
    /// @param multisig address of the multisig
    function buildMultisig(address multisig) internal virtual;

    /// @notice returns the calldata for the proposal
    function getCalldata() public view virtual override returns (bytes memory data) {
        (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory arguments
        ) = getProposalActions();

        require(targets.length > 0, "MultisigProposal: no actions");
        
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
            // For multiple actions, batch them
            // Use multicall pattern for Gnosis Safe
            data = abi.encodeWithSelector(
                bytes4(keccak256("multiSend(bytes)")),
                _encodeMultiSend(targets, values, arguments)
            );
        }
    }

    /// @notice Encode multiple calls for Gnosis Safe's multiSend
    function _encodeMultiSend(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) internal view returns (bytes memory) {
        bytes memory multiSendData = new bytes(0);
        
        for (uint256 i = 0; i < targets.length; i++) {
            multiSendData = abi.encodePacked(
                multiSendData,
                uint8(operation), // 0 for Call, 1 for DelegateCall
                targets[i],
                values[i],
                uint256(calldatas[i].length),
                calldatas[i]
            );
        }
        
        return multiSendData;
    }
    
    /// @notice Simulate the multisig proposal
    function simulate() public virtual override {
        console.log("\nSimulating proposal actions:");
        
        // Create snapshot before simulation
        uint256 snapshot = vm.snapshot();
        
        // Get proposal actions
        (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory arguments
        ) = getProposalActions();
        
        for (uint256 i = 0; i < targets.length; i++) {
            console.log("\nAction %s:", i);
            console.log("  Target: %s", targets[i]);
            console.log("  Value: %s", values[i]);
            console.log("  Arguments: %s", _toHex(arguments[i]));
            console.log("  Description: %s", actions[i].description);
            
            // Directly execute the call to simulate its effect
            vm.startPrank(gnosisSafe);
            
            (bool success, bytes memory returnData) = targets[i].call{value: values[i]}(arguments[i]);
            
            if (success) {
                console.log("  Result: Success");
                if (returnData.length > 0) {
                    console.log("  Return data: %s", _toHex(returnData));
                }
            } else {
                console.log("  Result: Failed");
                console.log("  Error: %s", _toHex(returnData));
                
                // Optionally revert to surface the error
                if (returnData.length > 0) {
                    assembly {
                        revert(add(returnData, 32), mload(returnData))
                    }
                } else {
                    revert("Simulation failed with no return data");
                }
            }
            
            vm.stopPrank();
        }
        
        // Revert to snapshot after simulation
        vm.revertTo(snapshot);
        
        console.log("\nAll actions simulated successfully");
    }
}
