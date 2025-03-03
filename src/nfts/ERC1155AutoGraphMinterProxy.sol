// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/**
 * @title ERC1155AutoGraphMinterProxy
 * @notice Ultra-minimal proxy contract for ZKSync deployment
 * @dev Uses EIP-1967 storage slots for implementation address
 */
contract ERC1155AutoGraphMinterProxy {
    // Implementation slot follows EIP-1967
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    
    // Admin slot
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    
    event Upgraded(address indexed implementation);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    
    constructor(address _implementation, address _admin) {
        assert(_IMPLEMENTATION_SLOT != bytes32(0));
        assert(_ADMIN_SLOT != bytes32(0));
        
        _setImplementation(_implementation);
        _setAdmin(_admin);
    }
    
    modifier onlyAdmin() {
        require(msg.sender == _getAdmin(), "Proxy: caller is not admin");
        _;
    }
    
    function upgradeTo(address newImplementation) external onlyAdmin {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }
    
    function changeAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = _getAdmin();
        _setAdmin(newAdmin);
        emit AdminChanged(oldAdmin, newAdmin);
    }
    
    function implementation() external view returns (address) {
        return _getImplementation();
    }
    
    function admin() external view returns (address) {
        return _getAdmin();
    }
    
    function _getImplementation() private view returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
    
    function _setImplementation(address newImplementation) private {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }
    
    function _getAdmin() private view returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }
    
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;
        assembly {
            sstore(slot, newAdmin)
        }
    }
    
    // Delegates calls to the implementation
    fallback() external payable {
        _delegate(_getImplementation());
    }
    
    receive() external payable {
        _delegate(_getImplementation());
    }
    
    function _delegate(address impl) private {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())
            
            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            
            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())
            
            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
} 