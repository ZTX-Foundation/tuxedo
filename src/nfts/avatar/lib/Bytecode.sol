// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title Bytecode library
library Bytecode {
    /// @notice get the creation code for a new account
    /// @param implementation_ The address of the implementation contract
    /// @param chainId_ The chain id of the token contract
    /// @param tokenContract_ The address of the token contract
    /// @param tokenId_ The id of the token
    /// @param salt_ The seed for the account
    /// @return the creation code
    function getCreationCode(
        address implementation_,
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_,
        uint256 salt_
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
                implementation_,
                hex"5af43d82803e903d91602b57fd5bf3",
                abi.encode(salt_, chainId_, tokenContract_, tokenId_)
            );
    }
}
