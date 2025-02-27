// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {IAddressRegistry} from "./IAddressRegistry.sol";

/// @notice ZK-compatible address registry with no file system or VM dependencies
contract ZKAddressRegistry is IAddressRegistry {
    struct Address {
        address addr;
        bool isContract;
    }

    /// @notice mapping from contract name to network chain id to address
    mapping(string name => mapping(uint256 chainId => Address)) internal _addresses;

    /// @notice mapping from address to chain id to whether it exists
    mapping(address addr => mapping(uint256 chainId => bool exist)) internal _addressToChainId;

    /// @notice arrays for recorded addresses
    string[] internal _recordedNames;
    uint256[] internal _recordedChainIds;
    address[] internal _recordedAddrs;

    /// @notice arrays for changed addresses
    string[] internal _changedNames;
    uint256[] internal _changedChainIds;
    address[] internal _oldAddrs;
    address[] internal _newAddrs;

    /// @notice initialize with predefined addresses
    constructor(
        string[] memory names,
        address[] memory addrs,
        uint256[] memory chainIds,
        bool[] memory isContracts
    ) {
        require(
            names.length == addrs.length && 
            names.length == chainIds.length && 
            names.length == isContracts.length,
            "ZKAddressRegistry: Invalid input lengths"
        );
        
        for (uint256 i = 0; i < names.length; i++) {
            _addresses[names[i]][chainIds[i]] = Address({
                addr: addrs[i],
                isContract: isContracts[i]
            });
            _addressToChainId[addrs[i]][chainIds[i]] = true;
        }
    }

    /// @notice get an address for the current chainId
    function getAddress(string memory name) public view override returns (address) {
        return getAddress(name, block.chainid);
    }

    /// @notice get an address for a specific chainId
    function getAddress(string memory name, uint256 chainId) public view override returns (address) {
        Address memory addr = _addresses[name][chainId];
        require(addr.addr != address(0), "Address not found");
        return addr.addr;
    }

    /// @notice add an address for the current chainId
    function addAddress(string memory name, address addr, bool isContract) public override {
        addAddress(name, addr, block.chainid, isContract);
    }

    /// @notice add an address for a specific chainId
    function addAddress(string memory name, address addr, uint256 chainId, bool isContract) public override {
        require(addr != address(0), "Cannot add zero address");
        require(!_addressToChainId[addr][chainId], "Address already registered with a different name");
        require(_addresses[name][chainId].addr == address(0), "Name already registered with a different address");
        
        _addresses[name][chainId] = Address({addr: addr, isContract: isContract});
        _addressToChainId[addr][chainId] = true;
        
        _recordedNames.push(name);
        _recordedChainIds.push(chainId);
        _recordedAddrs.push(addr);
    }

    /// @notice change an address for the current chainId
    function changeAddress(string memory name, address addr, bool isContract) public override {
        changeAddress(name, addr, block.chainid, isContract);
    }

    /// @notice change an address for a specific chainId
    function changeAddress(string memory name, address addr, uint256 chainId, bool isContract) public override {
        require(addr != address(0), "Cannot change to zero address");
        require(_addresses[name][chainId].addr != address(0), "Address not found");
        
        address oldAddr = _addresses[name][chainId].addr;
        
        // Remove old address mapping
        _addressToChainId[oldAddr][chainId] = false;
        
        // Check if new address is already used
        require(!_addressToChainId[addr][chainId], "New address already registered with a different name");
        
        // Set new address mapping
        _addresses[name][chainId] = Address({addr: addr, isContract: isContract});
        _addressToChainId[addr][chainId] = true;
        
        _changedNames.push(name);
        _changedChainIds.push(chainId);
        _oldAddrs.push(oldAddr);
        _newAddrs.push(addr);
    }

    /// @notice remove recorded addresses
    function resetRecordingAddresses() external override {
        delete _recordedNames;
        delete _recordedChainIds;
        delete _recordedAddrs;
    }

    /// @notice remove changed addresses
    function resetChangedAddresses() external override {
        delete _changedNames;
        delete _changedChainIds;
        delete _oldAddrs;
        delete _newAddrs;
    }

    /// @notice get recorded addresses
    function getRecordedAddresses()
        external
        view
        override
        returns (
            string[] memory names,
            uint256[] memory chainIds,
            address[] memory addresses
        )
    {
        return (_recordedNames, _recordedChainIds, _recordedAddrs);
    }

    /// @notice get changed addresses
    function getChangedAddresses()
        external
        view
        override
        returns (
            string[] memory names,
            uint256[] memory chainIds,
            address[] memory oldAddresses,
            address[] memory newAddresses
        )
    {
        return (_changedNames, _changedChainIds, _oldAddrs, _newAddrs);
    }

    /// @notice check if an address is a contract
    function isAddressContract(string memory name) external view override returns (bool) {
        return _addresses[name][block.chainid].isContract;
    }

    /// @notice check if an address is set
    function isAddressSet(string memory name) external view override returns (bool) {
        return _addresses[name][block.chainid].addr != address(0);
    }

    /// @notice check if an address is set for a specific chain id
    function isAddressSet(string memory name, uint256 chainId) external view override returns (bool) {
        return _addresses[name][chainId].addr != address(0);
    }
    
    /// @notice print current address changes (ZK-safe version is a no-op)
    function printJSONChanges() external view override {
        // This is a no-op in ZK environments
        // In ZK context, we can't print to console
    }
}
