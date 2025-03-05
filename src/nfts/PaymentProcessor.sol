// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title PaymentProcessor
/// @notice Library for handling payments in ETH and ERC20 tokens
library PaymentProcessor {
    using SafeERC20 for IERC20;

    /// @notice Process ETH payment
    /// @param paymentAmount Amount to be paid
    /// @param paymentRecipient Recipient of payment
    function processEthPayment(uint256 paymentAmount, address paymentRecipient) internal {
        require(msg.value == paymentAmount, "Payment amount mismatch");
        require(paymentAmount > 0, "Payment must be greater than 0");
        
        // Forward payment
        (bool success, ) = paymentRecipient.call{value: msg.value}("");
        require(success, "ETH transfer failed");
    }

    /// @notice Process ERC20 token payment
    /// @param paymentToken Token to be paid
    /// @param paymentAmount Amount to be paid
    /// @param payer Address paying
    /// @param paymentRecipient Recipient of payment
    function processTokenPayment(
        address paymentToken,
        uint256 paymentAmount,
        address payer,
        address paymentRecipient
    ) internal {
        require(paymentToken != address(0), "Payment token cannot be zero");
        
        if (paymentAmount > 0) {
            IERC20(paymentToken).safeTransferFrom(
                payer,
                paymentRecipient,
                paymentAmount
            );
        }
    }
} 