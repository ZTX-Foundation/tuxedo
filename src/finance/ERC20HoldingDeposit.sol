// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Roles} from "@protocol/core/Roles.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {Constants} from "../Constants.sol";
import {DepositBase} from "./DepositBase.sol";

/// @title ERC20HoldingDeposit
/// @notice Finance Deposit that is used to hold ERC20 tokens as a safe harbour. Deposit is a no-op
contract ERC20HoldingDeposit is DepositBase {
    using SafeERC20 for IERC20;

    /// @notice Token which the balance is reported in
    IERC20 public immutable token;

    constructor(address _core, address _token) CoreRef(_core) {
        require(_token != address(0), "ERC20HoldingDeposit: token cannot be 0x0");
        token = IERC20(_token);
    }

    ///////   READ-ONLY Methods /////////////

    /// @notice returns total balance of assets in the deposit
    function balance() public view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    /// @notice display the related token of the balance reported
    function balanceReportedIn() public view override returns (address) {
        return address(token);
    }

    /// @notice Withdraw underlying
    /// @param amountUnderlying of tokens withdrawn
    /// @param to the address to send funds to
    function withdraw(
        address to,
        uint256 amountUnderlying
    ) external override onlyRole(Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE) whenNotPaused {
        token.safeTransfer(to, amountUnderlying);
        emit Withdrawal(msg.sender, to, amountUnderlying);
    }
}
