// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {console} from "@forge-std/console.sol";
import {Test} from "@forge-std/Test.sol";
import {IAddressRegistry} from "./IAddressRegistry.sol";

/// @notice This is a contract that stores addresses for different networks.
contract AddressRegistry is IAddressRegistry, Test {
    struct Address {
        address addr;
        bool isContract;
    }

    /// @notice mapping from contract name to network chain id to address
    mapping(string name => mapping(uint256 chainId => Address)) public _addresses;

    /// @notice mapping from address to chain id to whether it exists
    mapping(address addr => mapping(uint256 chainId => bool exist)) public addressToChainId;

    /// @notice struct to record addresses deployed during a proposal
    struct RecordedAddress {
        string name;
        uint256 chainId;
        address addr;
    }

    /// @notice struct to record address changes during a proposal
    struct ChangedAddress {
        string name;
        uint256 chainId;
        address oldAddr;
        address newAddr;
    }

    /// @notice array of addresses deployed during a proposal
    RecordedAddress[] public recordedAddresses;

    /// @notice array of addresses changed during a proposal
    ChangedAddress[] public changedAddresses;

    /// @notice json structure to read addresses into storage from file
    struct SavedAddresses {
        /// address to store
        address addr;
        /// chain id of network to store for
        uint256 chainId;
        /// whether the address is a contract
        bool isContract;
        /// name of contract to store
        string name;
    }

    constructor() {
        string memory addressesPath = vm.envOr("ADDRESSES_PATH", string("addresses/addresses.json"));
        string memory addressesJSON = vm.readFile(addressesPath);
        bytes memory addressesRaw = vm.parseJson(addressesJSON);
        SavedAddresses[] memory addresses = abi.decode(addressesRaw, (SavedAddresses[]));

        for (uint256 i = 0; i < addresses.length; i++) {
            SavedAddresses memory savedAddress = addresses[i];
            
            // Ensure address isn't already used for another name
            require(!addressToChainId[savedAddress.addr][savedAddress.chainId], 
                    "Address already registered with a different name");
            
            _addresses[savedAddress.name][savedAddress.chainId] = Address({
                addr: savedAddress.addr,
                isContract: savedAddress.isContract
            });
            
            addressToChainId[savedAddress.addr][savedAddress.chainId] = true;
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
        require(!addressToChainId[addr][chainId], "Address already registered with a different name");
        require(_addresses[name][chainId].addr == address(0), "Name already registered with a different address");
        
        _addresses[name][chainId] = Address({addr: addr, isContract: isContract});
        addressToChainId[addr][chainId] = true;
        
        recordedAddresses.push(RecordedAddress({
            name: name,
            chainId: chainId,
            addr: addr
        }));
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
        addressToChainId[oldAddr][chainId] = false;
        
        // Check if new address is already used
        require(!addressToChainId[addr][chainId], "New address already registered with a different name");
        
        // Set new address mapping
        _addresses[name][chainId] = Address({addr: addr, isContract: isContract});
        addressToChainId[addr][chainId] = true;
        
        changedAddresses.push(ChangedAddress({
            name: name,
            chainId: chainId,
            oldAddr: oldAddr,
            newAddr: addr
        }));
    }

    /// @notice remove recorded addresses
    function resetRecordingAddresses() external override {
        delete recordedAddresses;
    }

    /// @notice remove changed addresses
    function resetChangedAddresses() external override {
        delete changedAddresses;
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
        uint256 recordedLength = recordedAddresses.length;
        names = new string[](recordedLength);
        chainIds = new uint256[](recordedLength);
        addresses = new address[](recordedLength);
        
        for (uint256 i = 0; i < recordedLength; i++) {
            names[i] = recordedAddresses[i].name;
            chainIds[i] = recordedAddresses[i].chainId;
            addresses[i] = recordedAddresses[i].addr;
        }
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
        uint256 changedLength = changedAddresses.length;
        names = new string[](changedLength);
        chainIds = new uint256[](changedLength);
        oldAddresses = new address[](changedLength);
        newAddresses = new address[](changedLength);
        
        for (uint256 i = 0; i < changedLength; i++) {
            names[i] = changedAddresses[i].name;
            chainIds[i] = changedAddresses[i].chainId;
            oldAddresses[i] = changedAddresses[i].oldAddr;
            newAddresses[i] = changedAddresses[i].newAddr;
        }
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
    
    /// @notice print current address changes as JSON for easy updating
    function printJSONChanges() external view override {
        uint256 recordedLength = recordedAddresses.length;
        uint256 changedLength = changedAddresses.length;
        
        if (recordedLength == 0 && changedLength == 0) {
            return;
        }
        
        console.log("Address changes:");
        console.log("[");
        
        // Print recorded addresses
        for (uint256 i = 0; i < recordedLength; i++) {
            RecordedAddress memory recorded = recordedAddresses[i];
            printAddress(
                recorded.name, 
                recorded.addr, 
                recorded.chainId, 
                _addresses[recorded.name][recorded.chainId].isContract
            );
            
            if (i < recordedLength - 1 || changedLength > 0) {
                console.log(",");
            }
        }
        
        // Print changed addresses
        for (uint256 i = 0; i < changedLength; i++) {
            ChangedAddress memory changed = changedAddresses[i];
            printAddress(
                changed.name, 
                changed.newAddr, 
                changed.chainId, 
                _addresses[changed.name][changed.chainId].isContract
            );
            
            if (i < changedLength - 1) {
                console.log(",");
            }
        }
        
        console.log("]");
    }
    
    /// @notice helper function to print address in JSON format
    function printAddress(string memory name, address addr, uint256 chainId, bool isContract) internal view {
        console.log("  {");
        console.log(
            string(
                abi.encodePacked(
                    "    \"name\": \"",
                    name,
                    "\","
                )
            )
        );
        console.log(
            string(
                abi.encodePacked(
                    "    \"addr\": \"",
                    vm.toString(addr),
                    "\","
                )
            )
        );
        console.log(
            string(
                abi.encodePacked(
                    "    \"chainId\": ",
                    vm.toString(chainId),
                    ","
                )
            )
        );
        console.log(
            string(
                abi.encodePacked(
                    "    \"isContract\": ",
                    isContract ? "true" : "false"
                )
            )
        );
        console.log("  }");
    }
}
