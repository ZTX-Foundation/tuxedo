// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IWETH} from "@protocol/interface/IWETH.sol";

library Constants {
    /// @notice the denominator for basis points granularity (10,000)
    uint256 public constant BASIS_POINTS_GRANULARITY = 10_000;

    uint256 public constant ONE_YEAR = 365.25 days;

    /// @notice the denominator for basis points granularity (10,000) expressed as an int data type
    int256 public constant BP_INT = int256(BASIS_POINTS_GRANULARITY);

    /// @notice WETH9 address on ethereum mainnet
    IWETH public constant WETH_MAINNET = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /// @notice WETH9 address on arbitrum
    IWETH public constant WETH_ARBITRUM = IWETH(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    /// @notice USD stand-in address
    address public constant USD = 0x1111111111111111111111111111111111111111;

    /// @notice Wei per ETH, i.e. 10**18
    uint256 public constant ETH_GRANULARITY = 1e18;

    /// @notice number of decimals in ETH, 18
    uint256 public constant ETH_DECIMALS = 18;

    /// @notice max-uint
    uint256 public constant MAX_UINT = type(uint256).max;
}
