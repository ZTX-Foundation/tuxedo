// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {AddressRegistry} from "../addresses/AddressRegistry.sol";
import {ZKAddressRegistry} from "../addresses/ZKAddressRegistry.sol";
import {IAddressRegistry} from "../addresses/IAddressRegistry.sol";

/// @notice Factory for creating address registries
contract AddressRegistryFactory is Test {
    /// @notice Create a standard address registry from a file
    function createFromFile(string memory path) external returns (AddressRegistry) {
        if (bytes(path).length == 0) {
            path = "addresses/addresses.json";
        }
        vm.setEnv("ADDRESSES_PATH", path);
        return new AddressRegistry();
    }

    /// @notice Create a ZK-compatible address registry with predefined addresses
    function createZKRegistry(
        string[] memory names,
        address[] memory addrs,
        uint256[] memory chainIds,
        bool[] memory isContracts
    ) external returns (ZKAddressRegistry) {
        return new ZKAddressRegistry(names, addrs, chainIds, isContracts);
    }

    /// @notice Create a ZK registry with mainnet addresses
    function createMainnetRegistry() external returns (ZKAddressRegistry) {
        // These values would come from your actual mainnet addresses
        // Shown here with placeholders
        string[] memory names = new string[](3);
        address[] memory addrs = new address[](3);
        uint256[] memory chainIds = new uint256[](3);
        bool[] memory isContracts = new bool[](3);
        
        /// TODO: Replace with actual addresses
        names[0] = "MULTISIG";
        addrs[0] = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
        chainIds[0] = 1; // Mainnet
        isContracts[0] = true;
        
        names[1] = "DEPLOYER_EOA";
        addrs[1] = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
        chainIds[1] = 1;
        isContracts[1] = false;
        
        names[2] = "VAULT";
        addrs[2] = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
        chainIds[2] = 1;
        isContracts[2] = true;
        
        return new ZKAddressRegistry(names, addrs, chainIds, isContracts);
    }
}
