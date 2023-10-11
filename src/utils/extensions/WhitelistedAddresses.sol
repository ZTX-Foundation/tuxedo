// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IWhitelistedAddresses} from "@protocol/utils/extensions/IWhitelistedAddresses.sol";

abstract contract WhitelistedAddresses is IWhitelistedAddresses {
    using EnumerableSet for EnumerableSet.AddressSet;

    // @notice set of whitelistedAddresses
    EnumerableSet.AddressSet private whitelistedAddresses;

    /// @dev checks if a deposit address is whitelisted, reverts if not
    modifier onlyWhitelist(address addr) {
        require(isWhitelistedAddress(addr), "WhitelistedAddress: Provided address is not whitelisted");
        _;
    }

    constructor(address[] memory _addresses) {
        // improbable to ever overflow
        unchecked {
            for (uint256 i = 0; i < _addresses.length; i++) {
                _addWhitelistAddress(_addresses[i]);
            }
        }
    }

    function _addWhitelistAddress(address _address) internal {
        require(whitelistedAddresses.add(_address), "WhitelistedAddress: Failed to add address to whitelist");
        emit WhitelistAddressAdded(_address);
    }

    function _removeWhitelistAddress(address _address) internal {
        require(whitelistedAddresses.remove(_address), "WhitelistedAddress: Failed to remove address from whitelist");
        emit WhitelistAddressRemoved(_address);
    }

    function _addWhitelistAddresses(address[] calldata _addresses) internal {
        unchecked {
            for (uint256 i = 0; i < _addresses.length; i++) {
                _addWhitelistAddress(_addresses[i]);
            }
        }
    }

    function _removeWhitelistAddresses(address[] calldata _addresses) internal {
        // improbable to ever overflow
        unchecked {
            for (uint256 i = 0; i < _addresses.length; i++) {
                _removeWhitelistAddress(_addresses[i]);
            }
        }
    }

    // ---------- Read-Only API ----------

    /// @notice returns true if the the provided address is a contained in the whitelist
    /// @param _address to check if whitelisted
    function isWhitelistedAddress(address _address) public view override returns (bool) {
        return whitelistedAddresses.contains(_address);
    }

    /// @notice returns all whitelisted addresses
    function getWhitelistedAddresses() external view returns (address[] memory) {
        return whitelistedAddresses.values();
    }
}
