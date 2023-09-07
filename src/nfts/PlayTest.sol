// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/// @title PlayTest contract for controlling access to the play test builds
contract PlayTest is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    /// @notice Before token transfer hook to prevent transfers
    /// @param from The address transferring from
    /// @param to The address transferring to
    /// @param tokenId The token Id
    /// @param batchSize The number of tokens to transfer
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721) {
        require(from == address(0), "Computer says no; token not transferable");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /// @notice Airdrop NFTs
    /// @param wAddresses The addresses to airdrop to
    /// @param _tokenURI The token URI
    function airdropNfts(address[] calldata wAddresses, string memory _tokenURI) public onlyOwner {
        for (uint i = 0; i < wAddresses.length; i++) {
            safeMint(wAddresses[i], _tokenURI);
        }
    }

    /// @notice Mint a new token
    /// @param to The address of the new token owner
    /// @param _tokenURI The token URI
    function safeMint(address to, string memory _tokenURI) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    /// @notice Burn
    /// @param tokenId The token to burn
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /// @notice Current token URI
    /// @param tokenId The token to query
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
