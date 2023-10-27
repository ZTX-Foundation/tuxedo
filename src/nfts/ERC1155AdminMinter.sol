// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Roles} from "@protocol/core/Roles.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

contract ERC1155AdminMinter is CoreRef {
    /// --------- Structs ---------- ///

    struct BulkMint {
        address nftContract;
        uint256 tokenId;
        uint256 amount;
        address recipient;
    }

    /// --------- Events ---------- ///

    /// @notice - Event emitted when the admin mint is successful
    event TokensMinted(
        address indexed nftContract,
        address indexed recipient,
        uint256 amount,
        uint256 tokenId
    );

    constructor(address _core) CoreRef(_core) {}

    /// @notice mint ERC1155 tokens as admin
    /// @param nftContract the token contract to mint from
    /// @param tokenId the id of the token to mint
    /// @param amount the amounts of the token to buy
    /// @param recipient the address to send the ERC11-55 tokens
    /// @dev locks up to level 1
    function mintToken(
        address nftContract,
        address recipient,
        uint256 tokenId,
        uint256 amount
    ) external onlyRole(Roles.ADMIN) globalLock(1) {
        _mintTokens(nftContract, tokenId, amount, recipient);
    }

    /// @notice mint ERC1155 tokens as admin
    /// @param toMint the tokens, amounts and token ids to mint
    function bulkMintTokens(BulkMint[] calldata toMint) external onlyRole(Roles.ADMIN) globalLock(1) {
        for (uint256 i = 0; i < toMint.length; i++) {
            _mintTokens(toMint[i].nftContract, toMint[i].tokenId, toMint[i].amount, toMint[i].recipient);
        }
    }

    /// @notice helper function that mints tokens and emits an event for each token minted
    function _mintTokens(address nftContract, uint256 tokenId, uint256 amount, address recipient) private {
        ERC1155MaxSupplyMintable(nftContract).mint(recipient, tokenId, amount); /// trusted contract, can make untrusted calls via annoying after transfer hook

        emit TokensMinted(nftContract, recipient, amount, tokenId);
    }
}
