// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title PaymentProcessor
/// @notice Library for handling payments in ETH and ERC20 tokens
library PaymentProcessor {
    using SafeERC20 for IERC20;

    /// @notice Process ETH payment
    /// @param amount Amount of ETH to transfer
    /// @param recipient Recipient of the payment
    function processEthPayment(uint256 amount, address recipient) internal {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ERC1155AutoGraphMinter: ETH transfer failed");
    }

    /// @notice Process ERC20 token payment
    /// @param token Token contract address
    /// @param amount Amount of tokens to transfer
    /// @param payer Address to transfer tokens from
    /// @param recipient Recipient of the payment
    function processTokenPayment(
        address token,
        uint256 amount,
        address payer,
        address recipient
    ) internal {
        IERC20(token).safeTransferFrom(payer, recipient, amount);
    }
} 