// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title a Finance Deposit interface for only balance getters
interface IDepositBalances {
    // ----------- Getters -----------

    /// @notice gets the effective balance of "balanceReportedIn" token if the deposit were fully withdrawn
    function balance() external view returns (uint256);

    /// @notice gets the token address in which this deposit returns its balance
    function balanceReportedIn() external view returns (address);
}
