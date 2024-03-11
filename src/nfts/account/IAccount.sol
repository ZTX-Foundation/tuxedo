// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title Token account interface
interface IAccount {
    /// @notice receive ETH
    receive() external payable;

    /// @notice get the token information
    function token()
        external
        view
        returns (
            uint256 chainId,
            address tokenContract,
            uint256 tokenId
        );

    /// @notice get the account state
    /// @return state The account state
    function state() external view returns (uint256);

    /// @notice check if the signer is valid
    /// @param signer The address to check signing authorization for
    /// @param context Additional data used to determine whether the signer is valid
    /// @return magicValue Magic value indicating whether the signer is valid
    function isValidSigner(address signer, bytes calldata context)
        external
        view
        returns (bytes4 magicValue);
}
