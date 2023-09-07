// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract ERC721ZepetoUA is AccessControlEnumerable, ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    using ECDSA for bytes32;

    /// ------------------------ Constants --------------------------------- ///

    bytes32 internal constant ADMIN = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_NOTARY = keccak256("MINTER_NOTARY_ROLE");

    /// ------------------------ Events --------------------------------- ///

    event TokenMinted(address indexed _to, uint256 indexed _tokenId);

    /// ------------------------ Storage --------------------------------- ///

    /// @notice - Hashes that have been registered
    mapping(bytes32 hash => bool used) public usedHashes;

    /// @notice - expiryToken value for x amount hours
    uint8 public expiryTokenHoursValid; // 1 - 24 hours

    struct HashInputsParams {
        address recipient;
        uint256 tokenId; // nft token id to be minted
        uint256 salt;
        uint256 expiryToken;
    }

    struct VerifyInputParams {
        bytes32 inputHash;
        bytes32 generatedHash;
        bytes signature;
        uint256 expiryToken;
    }

    /// @dev allow minting of tokens
    bool public isClaimable = true;

    /// @dev claimable modifier
    modifier claimable() {
        require(isClaimable == true, "Claiming is currently disabled.");
        _;
    }

    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param _expiryTokenHoursValid The expiry token value in hours
    constructor(
        string memory name,
        string memory symbol,
        uint8 _expiryTokenHoursValid,
        address signer
    ) ERC721(name, symbol) {
        require(_isValidRange(_expiryTokenHoursValid, 1, 24), "Hours must be between 1 and 24");
        expiryTokenHoursValid = _expiryTokenHoursValid;

        _setRoleAdmin(ADMIN, ADMIN);
        _setRoleAdmin(MINTER_NOTARY, ADMIN);

        /// @dev Set admin role to contract deployer
        _grantRole(ADMIN, msg.sender);
        _grantRole(MINTER_NOTARY, signer);
    }

    /// @notice Returns the address that signed a given string message
    /// @param hash Keccak-256 hash
    /// @param signature Signature of the signed hash
    function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address) {
        return hash.recover(signature);
    }

    /// @notice Set claimable status
    /// @param _isClaimable Enabled or not
    function setClaimable(bool _isClaimable) public onlyOwner {
        isClaimable = _isClaimable;
    }

    /// ------------------- Internal Helpers ----------------------------------- ///

    /// @notice Verify a hash
    /// @param params The claim params
    function _verifyHash(VerifyInputParams memory params) internal {
        require(_isExpiryTokenValid(params.expiryToken), "Expiry token has expired");
        require(params.inputHash == params.generatedHash, "Hash mismatch");
        require(!usedHashes[params.inputHash], "Hash has already been used");
        require(hasRole(MINTER_NOTARY, recoverSigner(params.inputHash, params.signature)), "Invalid signer");

        // expire that hash baby
        usedHashes[params.inputHash] = true;
    }

    /// @notice Is the expiry token valid
    /// @param expiryToken The expiry token
    /// @return bool
    function _isExpiryTokenValid(uint256 expiryToken) internal view returns (bool) {
        // Convert hours to seconds
        uint256 hoursInSeconds = uint256(expiryTokenHoursValid) * 1 hours;

        // get time diff
        uint256 diff = block.timestamp - expiryToken;

        if (diff < hoursInSeconds) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice helper function to check if a uint8 is within a range
    /// @param input The input to check
    /// @param minRange The minimum range
    /// @param maxRange The maximum range
    /// @return bool
    function _isValidRange(uint8 input, uint8 minRange, uint8 maxRange) private pure returns (bool) {
        return input >= minRange && input <= maxRange;
    }

    /// ------------------- Hashing functions ----------------------------------- ///

    /// @notice Get the hash for the claim
    /// @param params The hash params
    /// @return The hash
    function getHash(HashInputsParams memory params) public pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encode(params.recipient, params.tokenId, params.salt, params.expiryToken));
        return hash.toEthSignedMessageHash();
    }

    /// ------------------- ERC721 ----------------------------------- ///

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
        require(from == address(0) || to == address(0), "Computer says no; token not transferable");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

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

    /// @notice A Zepeto User can call this and claim their NFT
    /// @param recipient The recipient of the NFT
    /// @param tokenId The token ID to mint
    /// @param hash The generated hash
    /// @param salt Salt
    /// @param signature Signature
    /// @param expiryToken Expiry token
    /// @param _tokenURI The token URI
    function claim(
        address recipient,
        uint256 tokenId,
        bytes32 hash,
        uint256 salt,
        bytes memory signature,
        uint256 expiryToken,
        string memory _tokenURI
    ) external claimable {
        HashInputsParams memory input = HashInputsParams(recipient, tokenId, salt, expiryToken);
        VerifyInputParams memory params = VerifyInputParams(hash, getHash(input), signature, expiryToken);

        _verifyHash(params);

        /// @dev limit to 1 token per address
        require(balanceOf(recipient) == 0, "Only one NFT per address can be claimed");

        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        emit TokenMinted(recipient, tokenId);
    }

    /// @dev Override
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlEnumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
