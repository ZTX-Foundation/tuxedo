// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

/// @title WhitelistManager
/// @notice Library for managing whitelisted addresses
library WhitelistManager {
    /// @dev Adds an address to the whitelist
    /// @param whitelist The whitelist mapping
    /// @param addr Address to add to whitelist
    function addAddress(mapping(address => bool) storage whitelist, address addr) internal {
        require(addr != address(0), "Cannot whitelist zero address");
        whitelist[addr] = true;
    }
    
    /// @dev Removes an address from the whitelist
    /// @param whitelist The whitelist mapping
    /// @param addr Address to remove from whitelist
    function removeAddress(mapping(address => bool) storage whitelist, address addr) internal {
        whitelist[addr] = false;
    }
    
    /// @dev Adds multiple addresses to the whitelist
    /// @param whitelist The whitelist mapping
    /// @param addrs Addresses to add to whitelist
    function addAddresses(mapping(address => bool) storage whitelist, address[] memory addrs) internal {
        for (uint256 i = 0; i < addrs.length; i++) {
            require(addrs[i] != address(0), "Cannot whitelist zero address");
            whitelist[addrs[i]] = true;
        }
    }
    
    /// @dev Removes multiple addresses from the whitelist
    /// @param whitelist The whitelist mapping
    /// @param addrs Addresses to remove from whitelist
    function removeAddresses(mapping(address => bool) storage whitelist, address[] memory addrs) internal {
        for (uint256 i = 0; i < addrs.length; i++) {
            whitelist[addrs[i]] = false;
        }
    }
} 