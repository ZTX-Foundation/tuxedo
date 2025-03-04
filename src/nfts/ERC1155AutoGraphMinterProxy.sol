// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

/// @title ERC1155AutoGraphMinterProxy
/// @notice Ultra-minimal proxy for ZKSync deployment
contract ERC1155AutoGraphMinterProxy {
    /// @notice Address of the implementation contract
    address public immutable implementation;
    /// @notice Address of the admin
    address public admin;

    /// @notice Creates a new proxy
    /// @param _implementation Address of the implementation contract
    /// @param _admin Address of the admin
    constructor(address _implementation, address _admin) {
        implementation = _implementation;
        admin = _admin;
    }

    /// @notice Changes the admin address
    /// @param _newAdmin Address of the new admin
    function changeAdmin(address _newAdmin) external {
        require(msg.sender == admin, "Proxy: not admin");
        admin = _newAdmin;
    }

    /// @dev Fallback function delegates all calls to implementation
    fallback() external payable {
        address _impl = implementation;
        assembly {
            // Copy msg.data
            calldatacopy(0, 0, calldatasize())
            // Call implementation
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            // Copy return data
            returndatacopy(0, 0, returndatasize())
            // Return or revert based on result
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /// @dev Allow proxy to receive ETH
    receive() external payable {}
}
