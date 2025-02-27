// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {IAddressRegistry} from "@protocol/addresses/IAddressRegistry.sol";

/// @notice Interface for governance proposals
interface IProposal {
    /// @notice proposal name, e.g. "BIP15".
    function name() external view returns (string memory);

    /// @notice proposal description.
    function description() external view returns (string memory);

    /// @notice function to be used by forge script.
    function run() external;

    /// @notice return proposal actions.
    function getProposalActions()
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory arguments
        );

    /// @notice return proposal calldata
    function getCalldata() external returns (bytes memory data);

    /// @notice check if there are any on-chain proposal that matches the proposal calldata
    function checkOnChainCalldata() external view returns (bool);

    /// @notice deploy any contracts needed for the proposal.
    function deploy() external;

    /// @notice helper function to mock on-chain data after deployment
    function afterDeployMock() external;

    /// @notice build the proposal actions
    function build() external;

    /// @notice actually simulates the proposal.
    function simulate() external;

    /// @notice execute post-proposal checks.
    function validate() external;

    /// @notice print proposal description, actions and calldata
    function print() external;

    /// @notice set the Address Registry
    function setAddressRegistry(IAddressRegistry _registry) external;

    /// @notice set the primary fork id
    function setPrimaryForkId(uint256 _forkId) external;
}
