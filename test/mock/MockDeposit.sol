// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Roles} from "@protocol/core/Roles.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {IDepositBase} from "@protocol/finance/IDepositBase.sol";

contract MockDeposit is IDepositBase, CoreRef {
    address public override balanceReportedIn;

    uint256 private resistantBalance;

    constructor(
        address _core,
        address _token,
        uint256 _resistantBalance
    ) CoreRef(_core) {
        balanceReportedIn = _token;
        resistantBalance = _resistantBalance;
    }

    receive() external payable {}

    function set(
        uint256 _resistantBalance
    ) public {
        resistantBalance = _resistantBalance;
    }

    function deposit() external {
        resistantBalance = IERC20(balanceReportedIn).balanceOf(address(this));
    }

    function withdraw(address to, uint256 amount) external override {
        IERC20(balanceReportedIn).transfer(to, amount);
        resistantBalance = IERC20(balanceReportedIn).balanceOf(address(this));
    }

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external override {
        IERC20(token).transfer(to, amount);
    }

    function withdrawETH(
        address payable to,
        uint256 amount
    ) external onlyRole(Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE) {
        to.transfer(amount);
    }

    function balance() external view override returns (uint256) {
        return IERC20(balanceReportedIn).balanceOf(address(this));
    }
}