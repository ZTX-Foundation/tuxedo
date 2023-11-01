// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

interface IWhitelistedAddresses {
    // ---------- Events ----------
    event WhitelistAddressAdded(address indexed _address);

    event WhitelistAddressRemoved(address indexed _address);

    // ---------- Read-Only API ----------

    /// @notice returns true if the financeDeposit address is whitelisted
    /// @param _address to check
    function isWhitelistedAddress(address _address) external view returns (bool);

    /// @notice returns all whitelisted addresses
    function getWhitelistedAddresses() external view returns (address[] memory);
}

