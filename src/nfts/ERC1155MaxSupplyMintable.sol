// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ERC1155, ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Roles} from "@protocol/core/Roles.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {Sealable} from "@protocol/utils/extensions/Sealable.sol";

/// Base ERC 1155 NFT with total supply
/// Inherits CoreRef for roles and access
contract ERC1155MaxSupplyMintable is ERC1155Supply, ERC1155Burnable, CoreRef, Sealable {
    /// @notice contract name
    string private _name;

    /// @notice contract symbol
    string private _symbol;

    /// @notice an event emitted when a token's supply cap is updated
    event SupplyCapUpdated(uint256 tokenId, uint256 previousMaxSupply, uint256 maxSupply);

    /// @notice an event emitted when the URI is updated for a token
    event URIUpdated(string newuri);

    /// @notice an event emitted when a token is minted
    event TokenMinted(address indexed account, uint256 indexed tokenId, uint256 amount);

    /// @notice an event emitted when a token is burned
    event TokenBurned(address indexed account, uint256 indexed tokenId, uint256 amount);

    /// @notice an event emitted when a batch of tokens are minted
    event BatchMinted(address indexed account, uint256[] tokenIds, uint256[] amounts);

    /// @notice the maximum supply of a given token
    mapping(uint256 tokenId => uint256 tokenMaxSupply) public maxTokenSupply;

    /// @notice construct the ERC1155 with total supply and CoreRef
    constructor(
        address _core,
        string memory _uri,
        string memory name_,
        string memory symbol_
    ) CoreRef(_core) ERC1155(_uri) {
        _name = name_;
        _symbol = symbol_;
    }

    /// @notice set the supply cap for a given token, cannot be less than current supply
    /// @param tokenId the id of the token to update
    /// @param maxSupply the new max supply of the token
    function setSupplyCap(uint256 tokenId, uint256 maxSupply) external onlyRole(Roles.ADMIN) {
        _setSupplyCap(tokenId, maxSupply);
    }

    /// @notice set the supply cap for a given token, cannot be less than current supply. Can only be called once by the DEPLOYER role
    /// @param tokenId the id of the token to update
    /// @param maxSupply the new max supply of the token
    function setSupplyCapAtDeployment(uint256 tokenId, uint256 maxSupply) external onlyRole(Roles.DEPLOYER) sealAfter {
        _setSupplyCap(tokenId, maxSupply);
    }

    /// @dev internal function to set the supply cap for a given token, cannot be less than current supply
    /// @param tokenId the id of the token to update
    /// @param maxSupply the new max supply of the token
    function _setSupplyCap(uint256 tokenId, uint256 maxSupply) internal {
        require(maxSupply >= totalSupply(tokenId), "BaseERC1155NFT: maxSupply cannot be less than current supply");

        uint256 oldSupplyCap = maxTokenSupply[tokenId];
        maxTokenSupply[tokenId] = maxSupply;

        emit SupplyCapUpdated(tokenId, oldSupplyCap, maxSupply);
    }

    /// @notice set the URI for the token
    /// @param newuri the new URI
    /// callable by admin
    function setURI(string memory newuri) external onlyRole(Roles.ADMIN) {
        _setURI(newuri);

        emit URIUpdated(newuri);
    }

    /// @notice mint tokens, can only mint as many exist left to be minted from the max token supply
    /// @param recipient the address to mint to
    /// @param tokenId the id of the token to mint
    /// @param amount the amount of tokens to mint
    /// callable only by minter role
    /// can only be accessed if global lock is at level 1
    /// @dev pauseable
    function mint(
        address recipient,
        uint256 tokenId,
        uint256 amount
    ) external onlyRole(Roles.MINTER) whenNotPaused globalLock(2) {
        require(totalSupply(tokenId) + amount <= maxTokenSupply[tokenId], "BaseERC1155NFT: supply exceeded");

        /// no bytes passed on mint
        _mint(recipient, tokenId, amount, "");

        /// check for SMT solver and echidna
        assert(totalSupply(tokenId) <= maxTokenSupply[tokenId]);

        emit TokenMinted(recipient, tokenId, amount);
    }

    /// @notice mint tokens in a batch, can only mint as many exist left to be minted from the max token supply
    /// @param recipient the address to mint to
    /// @param tokenIds the ids of the tokens to mint
    /// @param amounts the amounts of tokens to mint
    function mintBatch(
        address recipient,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external onlyRole(Roles.MINTER) whenNotPaused globalLock(2) {
        /// arity check on tokenIds.length and amounts.length done in ERC1155 _mintBatch
        _mintBatch(recipient, tokenIds, amounts, "");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(totalSupply(tokenIds[i]) <= maxTokenSupply[tokenIds[i]], "BaseERC1155NFT: supply exceeded");
        }

        emit BatchMinted(recipient, tokenIds, amounts);
    }

    /// ----------- VIEW ONLY API ------------

    /// @notice returns the amount of tokens left to mint from the max supply
    /// @param tokenId the id of the token to query
    function getMintAmountLeft(uint256 tokenId) public view returns (uint256) {
        return maxTokenSupply[tokenId] - totalSupply(tokenId);
    }

    /// @notice returns the name of the token
    function name() public view returns (string memory) {
        return _name;
    }

    /// @notice returns the symbol of the token
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// ----------- INTERNAL OVERRIDES ------------

    /// @notice disallow sending of tokens to the token contract itself
    /// @param to the address that receives tokens
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal override(ERC1155, ERC1155Supply) {
        ERC1155Supply._beforeTokenTransfer(operator, from, to, ids, amounts, "");
    }

    // Needed for openSea with ERC1155
    function uri(uint256 _id) public view virtual override(ERC1155) returns (string memory) {
        //slither-disable-next-line encode-packed-collision
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }
}
