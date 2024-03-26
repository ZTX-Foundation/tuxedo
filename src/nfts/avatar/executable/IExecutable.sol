// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title Executable interface
interface IExecutable {
    /// @notice execute a low-level operation
    /// @param to The target address of the operation
    /// @param value The ETH value to be sent to the target
    /// @param data The encoded operation calldata
    /// @param operation A value indicating the type of operation to perform
    /// @return The result of the operation
    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 operation
    ) external payable returns (bytes memory);
}
