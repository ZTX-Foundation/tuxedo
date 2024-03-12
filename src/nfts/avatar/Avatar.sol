// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import {Roles} from "@protocol/core/Roles.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";

contract Avatar is ERC721, ERC721URIStorage, ERC721Burnable, CoreRef {
    /// @notice construct the Avatar ERC-721 with CoreRef
    constructor(
        address _core,
        string memory name,
        string memory symbol
    ) CoreRef(_core) ERC721(name, symbol) {}

    /// @notice Burn
    /// @param tokenId The token to burn
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /// @notice Current token URI
    /// @param tokenId The token to query
    /// @return token URI
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
