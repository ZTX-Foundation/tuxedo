// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {Roles} from "@protocol/core/Roles.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {IDepositBase} from "./IDepositBase.sol";

/// @title abstract contract for withdrawing ERC-20 tokens using a Financial Controller
abstract contract DepositBase is IDepositBase, CoreRef {
    using SafeERC20 for IERC20;

    /// @notice withdraw ERC20 from the contract
    /// @param token address of the ERC20 to send
    /// @param to address destination of the ERC20
    /// @param amount quantity of ERC20 to send
    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) public virtual override onlyRole(Roles.FINANCIAL_CONTROLLER) whenNotPaused {
        IERC20(token).safeTransfer(to, amount);
        emit WithdrawERC20(msg.sender, token, to, amount);
    }

    function balance() public view virtual override returns (uint256);

    function balanceReportedIn() public view virtual override returns (address);
}
