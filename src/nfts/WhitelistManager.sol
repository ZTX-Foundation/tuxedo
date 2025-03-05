// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

/// @title WhitelistManager
/// @notice Library for managing whitelisted contracts
library WhitelistManager {
    /// @notice Add a contract to the whitelist
    /// @param whitelist Mapping of whitelisted contracts
    /// @param contractAddress Contract to add
    function addWhitelisted(
        mapping(address => bool) storage whitelist, 
        address contractAddress
    ) internal {
        require(contractAddress != address(0), "ERC1155AutoGraphMinter: Cannot whitelist zero address");
        whitelist[contractAddress] = true;
    }

    /// @notice Remove a contract from the whitelist
    /// @param whitelist Mapping of whitelisted contracts
    /// @param contractAddress Contract to remove
    function removeWhitelisted(
        mapping(address => bool) storage whitelist, 
        address contractAddress
    ) internal {
        require(contractAddress != address(0), "ERC1155AutoGraphMinter: Cannot remove zero address");
        whitelist[contractAddress] = false;
    }

    /// @notice Check if a contract is whitelisted
    /// @param whitelist Mapping of whitelisted contracts
    /// @param contractAddress Contract to check
    /// @return result True if contract is whitelisted
    function isWhitelisted(
        mapping(address => bool) storage whitelist,
        address contractAddress
    ) internal view returns (bool result) {
        return whitelist[contractAddress];
    }
} 