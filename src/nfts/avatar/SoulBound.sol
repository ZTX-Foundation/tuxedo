// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC1155} from  "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {Roles} from "@protocol/core/Roles.sol";

/// @title SoulBound ERC1155 Token
/// @dev Implementation of a SoulBound token using the ERC1155 standard, where tokens are non-transferable.
contract SoulBound is ERC1155, CoreRef, Ownable {
    /// @dev Mapping from token ID to owner's address
    mapping(uint256 => address) private _owners;

    /// @notice Creates a new SoulBound token contract
    /// @param uri URI for token metadata
    /// @param _core Address of the Core contract
    constructor(string memory uri, address _core) CoreRef(_core) ERC1155(uri) {}

    /// @notice Checks the balance of a SoulBound token for a given account
    /// @dev Overrides the ERC1155 balanceOf function to support SoulBound logic
    /// @param account The address of the token holder
    /// @param id The token ID to query
    /// @return The balance of the token (1 if owned, 0 otherwise)
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _owners[id] == account ? 1 : 0;
    }

    /// @notice Mints a new SoulBound token to a specified address
    /// @dev Mints a token and assigns it to an owner, tokens are non-transferable
    /// @param to The address that will own the minted token
    /// @param id The token ID to mint
    function mint(address to, uint256 id) external onlyRole(Roles.MINTER_PROTOCOL_ROLE) whenNotPaused globalLock(1) {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(_owners[id] == address(0), "Token is already owned");
        _owners[id] = to;
        _mint(to, id, 1, "");
        emit TransferSingle(msg.sender, address(0), to, id, 1);
    }


    /// @notice Prevents the transfer of SoulBound tokens
    /// @dev Overrides the ERC1155 safeTransferFrom function to block token transfers
    /// @param from The address attempting to transfer
    /// @param to Intended recipient address
    /// @param id The token ID being transferred
    /// @param amount The amount of tokens being transferred
    /// @param data Additional data with no specified format
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public pure override {
        revert("SoulBound tokens cannot be transferred");
    }

    /// @notice Prevents the batch transfer of SoulBound tokens
    /// @dev Overrides the ERC1155 safeBatchTransferFrom function to block token transfers
    /// @param from The address attempting to transfer
    /// @param to Intended recipient address
    /// @param ids An array of token IDs being transferred
    /// @param amounts An array of the amount of tokens being transferred for each ID
    /// @param data Additional data with no specified format
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public pure override {
        revert("SoulBound tokens cannot be transferred");
    }

    /// @notice Gets the owner of a specific token ID
    /// @param tokenId The token ID to query for ownership
    /// @return The address of the owner of the specified token ID
    function ownerOf(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return _owners[tokenId];
    }
}