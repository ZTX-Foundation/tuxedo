// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/Create2.sol";

import {IRegistry} from "@protocol/nfts/registry/IRegistry.sol";
import {Bytecode} from "@protocol/nfts/lib/Bytecode.sol";

/// @title Registry contract
contract Registry is IRegistry {
    /// @dev emitted when an account creation fails
    error InitializationFailed();

    /// @notice create a new token bound account
    /// @param implementation The address of the implementation contract
    /// @param chainId The chain id of the token contract
    /// @param tokenContract The address of the token contract
    /// @param tokenId The id of the token
    /// @param salt The seed for the account
    /// @param initData The data to be called after the account is created
    /// @return the address of the account
    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt,
        bytes calldata initData
    ) external returns (address) {
        bytes memory code = Bytecode.getCreationCode(
            implementation,
            chainId,
            tokenContract,
            tokenId,
            salt
        );

        address _account = Create2.computeAddress(bytes32(salt), keccak256(code));

        if (_account.code.length != 0) return _account;

        emit AccountCreated(_account, implementation, chainId, tokenContract, tokenId, salt);

        _account = Create2.deploy(0, bytes32(salt), code);

        if (initData.length != 0) {
            (bool success, ) = _account.call(initData);
            if (!success) revert InitializationFailed();
        }

        return _account;
    }

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
    ) external view returns (address) {
        bytes32 bytecodeHash = keccak256(
            Bytecode.getCreationCode(
                implementation,
                chainId,
                tokenContract,
                tokenId,
                salt
            )
        );

        return Create2.computeAddress(bytes32(salt), bytecodeHash);
    }
}
