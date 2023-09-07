// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IDepositBalances} from "@protocol/finance/IDepositBalances.sol";

/// @title a Finance Deposit interface
interface IDepositBase is IDepositBalances {
    // ----------- Events -----------
    event Deposit(address indexed _from, uint256 _amount);

    event Withdrawal(address indexed _caller, address indexed _to, uint256 _amount);

    event WithdrawERC20(address indexed _caller, address indexed _token, address indexed _to, uint256 _amount);

    // ----------- Financial Controller only state changing api -----------

    function withdraw(address to, uint256 amount) external;

    function withdrawERC20(address token, address to, uint256 amount) external;
}
