// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title IFinanceGuardian
/// @notice an interface for defining how the FinanceGuardian functions
/// @dev any implementation of this contract should be granted the roles of Guardian and Finance Controller in order to work correctly
interface IFinanceGuardian {
    // ---------- Events ----------
    event FinanceGuardianWithdrawal(address indexed holdingDeposit, uint256 amount);

    event FinanceGuardianERC20Withdrawal(
        address indexed holdingDeposit,
        address indexed token,
        uint256 amount
    );

    event SafeAddressUpdated(
        address indexed oldSafeAddress,
        address indexed newSafeAddress
    );

    // ---------- Read-Only API ----------

    // ---------- Governor-Only State-Changing API ----------

    /// @notice governor-only method to change the safe address
    /// @param newSafeAddress new safe address
    function setSafeAddress(address newSafeAddress) external;

    /// @notice governor-only method to whitelist a financeDeposit address to withdraw funds from
    /// @param financeDeposit the address to whitelist
    function addWhitelistAddress(address financeDeposit) external;

    /// @notice batch version of addWhitelistAddress
    /// @param whitelistAddresses the finance deposit addresses to whitelist, as calldata
    function addWhitelistAddresses(
        address[] calldata whitelistAddresses
    ) external;

    // ---------- Governor-or-Guardian-Only State-Changing API ----------

    /// @notice governor-or-guardian-only method to remove financeDeposit address from the whitelist to withdraw funds from
    /// @param financeDeposit the address to un-whitelist
    function removeWhitelistAddress(address financeDeposit) external;

    /// @notice batch version of removeWhitelistAddress
    /// @param whitelistAddresses the addresses to un-whitelist
    function removeWhitelistAddresses(
        address[] calldata whitelistAddresses
    ) external;

    /// @notice governor-or-guardian-or-finance-guard method to withdraw funds from a finance deposit, by calling the withdraw() method on it
    /// @param financeDeposit the address of the finance deposit contract
    /// @param amount the amount to withdraw
    function withdrawToSafeAddress(address financeDeposit, uint256 amount) external;

    /// @notice governor-or-guardian-or-finance-guard method to withdraw all at once funds from a finance deposit, by calling the withdraw() method on it
    /// @param financeDeposit the address of the finance deposit contract
    function withdrawAllToSafeAddress(address financeDeposit) external;

    /// @notice governor-or-guardian-or-finance-guard method to withdraw an ERC20 from a finance deposit, by calling the withdrawERC20() method on it
    /// @param financeDeposit the deposit to pull funds from
    /// @param token the address of the token to withdraw
    /// @param amount the amount of funds to withdraw
    function withdrawERC20ToSafeAddress(
        address financeDeposit,
        address token,
        uint256 amount
    ) external;

    /// @notice governor-or-guardian-or-finance-guard method to withdraw all of an ERC20 balance from a finance deposit, by calling the withdrawERC20() method on it
    /// @param financeDeposit the deposit to pull funds from
    /// @param token the address of the token to withdraw
    function withdrawAllERC20ToSafeAddress(
        address financeDeposit,
        address token
    ) external;
}
