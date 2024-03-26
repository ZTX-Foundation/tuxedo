// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title Registry contract interface
interface IRegistry {
    /// @notice emitted when an account is created
    event AccountCreated(
        address account,
        address indexed implementation,
        uint256 chainId,
        address indexed tokenContract,
        uint256 indexed tokenId,
        uint256 salt
    );

    /// @notice create a new token bound account
    /// @param implementation The address of the implementation contract
    /// @param chainId The chain id of the token contract
    /// @param tokenContract The address of the token contract
    /// @param tokenId The id of the token
    /// @param seed The seed for the account
    /// @param initData The data to be called after the account is created
    /// @return the address of the account
    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 seed,
        bytes calldata initData
    ) external returns (address);

    /// @notice get the account address
    /// @param implementation The address of the implementation contract
    /// @param chainId The chain id of the token contract
    /// @param tokenContract The address of the token contract
    /// @param tokenId The id of the token
    /// @param salt The seed for the account
    /// @return the address of the account
    function account(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    ) external view returns (address);
}
