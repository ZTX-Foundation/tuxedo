// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

interface IWETH {
    function deposit() external payable;
    function approve(address to, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint256);
}
