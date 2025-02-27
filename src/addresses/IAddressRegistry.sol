// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

/// @notice Interface for the address registry that stores addresses for different networks.
interface IAddressRegistry {
    /// @notice get an address for the current chainId
    function getAddress(string memory name) external view returns (address);

    /// @notice get an address for a specific chainId
    function getAddress(string memory name, uint256 chainId) external view returns (address);

    /// @notice add an address for the current chainId
    function addAddress(string memory name, address addr, bool isContract) external;

    /// @notice add an address for a specific chainId
    function addAddress(string memory name, address addr, uint256 chainId, bool isContract) external;

    /// @notice change an address for the current chainId
    function changeAddress(string memory name, address addr, bool isContract) external;

    /// @notice change an address for a specific chainId
    function changeAddress(string memory name, address addr, uint256 chainId, bool isContract) external;

    /// @notice remove recorded addresses
    function resetRecordingAddresses() external;

    /// @notice remove changed addresses
    function resetChangedAddresses() external;

    /// @notice get recorded addresses from a proposal's deployment
    function getRecordedAddresses()
        external
        view
        returns (
            string[] memory names,
            uint256[] memory chainIds,
            address[] memory addresses
        );

    /// @notice get changed addresses from a proposal
    function getChangedAddresses()
        external
        view
        returns (
            string[] memory names,
            uint256[] memory chainIds,
            address[] memory oldAddresses,
            address[] memory newAddresses
        );

    /// @notice check if an address is a contract
    function isAddressContract(string memory name) external view returns (bool);

    /// @notice check if an address is set
    function isAddressSet(string memory name) external view returns (bool);

    /// @notice check if an address is set for a specific chain id
    function isAddressSet(string memory name, uint256 chainId) external view returns (bool);
    
    /// @notice print current address changes as JSON for easy updating
    function printJSONChanges() external view;
}
