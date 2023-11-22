// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {CoreRef} from "@protocol/refs/CoreRef.sol";

import {Roles} from "@protocol/core/Roles.sol";
import {IDepositBase} from "@protocol/finance/IDepositBase.sol";
import {IFinanceGuardian} from "@protocol/finance/IFinanceGuardian.sol";
import {WhitelistedAddresses} from "@protocol/utils/extensions/WhitelistedAddresses.sol";

/// @notice Finance Guardian is a contract to safeguard protocol funds
/// by being able to withdraw from whitelisted deposits to a safe address
contract FinanceGuardian is WhitelistedAddresses, IFinanceGuardian, CoreRef {
    ///@notice safe address where funds can be withdrawn to
    address public safeAddress;

    constructor(
        address _core,
        address _safeAddress,
        address[] memory _whitelistAddresses
    ) CoreRef(_core) WhitelistedAddresses(_whitelistAddresses) {
        require(_safeAddress != address(0), "FinanceGuardian: safe address cannot be address(0)");
        safeAddress = _safeAddress;
    }

    // ---------- Read-Only API ----------

    // ---------- Admin or Governor-Only State-Changing API ----------

    /// @notice admin-only method to change the safe address
    /// @param newSafeAddress new safe address
    function setSafeAddress(address newSafeAddress) external override onlyRole(Roles.ADMIN) {
        require(newSafeAddress != address(0), "FinanceGuardian: safe address cannot be address(0)");
        address oldSafeAddress = safeAddress;
        safeAddress = newSafeAddress;
        emit SafeAddressUpdated(oldSafeAddress, newSafeAddress);
    }

    /// @notice admin or token governor-only method to whitelist a deposit address to withdraw funds from
    /// @param deposit the address to whitelist
    function addWhitelistAddress(
        address deposit
    ) external override hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        _addWhitelistAddress(deposit);
    }

    /// @notice batch version of addWhiteListaddress
    /// @param _whitelistAddresses the addresses to whitelist, as calldata
    function addWhitelistAddresses(
        address[] calldata _whitelistAddresses
    ) external override hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        _addWhitelistAddresses(_whitelistAddresses);
    }

    // ---------- Admin, Governor-Or-Guardian-Only State-Changing API ----------

    /// @notice governor-or-guardian-only method to remove deposit address from the whitelist to withdraw funds from
    /// @param deposit the address to remove from whitelist
    function removeWhitelistAddress(
        address deposit
    ) external override hasAnyOfThreeRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN, Roles.GUARDIAN) {
        _removeWhitelistAddress(deposit);
    }

    /// @notice batch version of removeWhitelistAddress
    /// @param _whitelistAddresses the addresses to remove from whitelist
    function removeWhitelistAddresses(
        address[] calldata _whitelistAddresses
    ) external override hasAnyOfThreeRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN, Roles.GUARDIAN) {
        _removeWhitelistAddresses(_whitelistAddresses);
    }

    // ---------- Finance Guardian State-Changing API ----------

    /// @notice governor-or-guardian-or-finance-guard method to withdraw funds from a deposit, by calling the withdraw() method on it
    /// @param deposit the address of the deposit contract
    /// @param amount the amount to withdraw
    function withdrawToSafeAddress(
        address deposit,
        uint256 amount
    )
        external
        override
        hasAnyOfFourRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.GUARDIAN, Roles.FINANCIAL_GUARDIAN, Roles.ADMIN)
        globalLock(1)
        onlyWhitelist(deposit)
    {
        _withdrawToSafeAddress(deposit, amount);
    }

    /// @notice governor-or-guardian-or-finance-guard method to withdraw
    /// all at once funds from a deposit, by calling the withdraw() method on it
    /// @param deposit the address of the deposit contract
    function withdrawAllToSafeAddress(
        address deposit
    )
        external
        override
        hasAnyOfFourRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.GUARDIAN, Roles.FINANCIAL_GUARDIAN, Roles.ADMIN)
        globalLock(1)
        onlyWhitelist(deposit)
    {
        _withdrawToSafeAddress(deposit, IDepositBase(deposit).balance());
    }

    /// @notice governor-or-guardian-or-finance-guard method to withdraw
    /// an ERC20 from a deposit, by calling the withdrawERC20() method on it
    /// @param deposit the deposit to pull funds from
    /// @param token the address of the token to withdraw
    /// @param amount the amount of funds to withdraw
    function withdrawERC20ToSafeAddress(
        address deposit,
        address token,
        uint256 amount
    )
        external
        override
        hasAnyOfFourRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.GUARDIAN, Roles.FINANCIAL_GUARDIAN, Roles.ADMIN)
        globalLock(1)
        onlyWhitelist(deposit)
    {
        _withdrawERC20ToSafeAddress(deposit, token, amount);
    }

    /// @notice governor-or-guardian-or-finance-guard method to withdraw all of
    /// an ERC20 balance from a deposit, by calling the withdrawERC20() method on it
    /// @param deposit the deposit to pull funds from
    /// @param token the address of the token to withdraw
    function withdrawAllERC20ToSafeAddress(
        address deposit,
        address token
    )
        external
        override
        hasAnyOfFourRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.GUARDIAN, Roles.FINANCIAL_GUARDIAN, Roles.ADMIN)
        globalLock(1)
        onlyWhitelist(deposit)
    {
        _withdrawERC20ToSafeAddress(deposit, token, IERC20(token).balanceOf(deposit));
    }

    // ---------- Private Functions ----------

    function _withdrawToSafeAddress(address deposit, uint256 amount) private {
        if (CoreRef(deposit).paused()) {
            CoreRef(deposit).unpause();
            IDepositBase(deposit).withdraw(safeAddress, amount);
            CoreRef(deposit).pause();
        } else {
            IDepositBase(deposit).withdraw(safeAddress, amount);
        }

        emit FinanceGuardianWithdrawal(deposit, amount);
    }

    function _withdrawERC20ToSafeAddress(address deposit, address token, uint256 amount) private {
        IDepositBase(deposit).withdrawERC20(token, safeAddress, amount);
        emit FinanceGuardianERC20Withdrawal(deposit, token, amount);
    }
}
