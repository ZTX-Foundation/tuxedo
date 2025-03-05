// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";

/// @title HashValidator
/// @notice Library for validating hashes, signatures and related operations
library HashValidator {
    using ECDSA for bytes32;

    /// @dev Generates a hash from input parameters
    /// @param recipient Address to receive NFT
    /// @param jobId Job identifier 
    /// @param tokenId ID of token to mint
    /// @param units Quantity to mint
    /// @param salt Random value for uniqueness
    /// @param nftContract Address of NFT contract
    /// @param paymentToken Payment token address (or zero for ETH)
    /// @param paymentAmount Amount to pay
    /// @param expiryToken Timestamp for expiration
    /// @return Hash of the parameters with ETH signed message prefix
    function generateHash(
        address recipient,
        uint256 jobId,
        uint256 tokenId,
        uint256 units,
        uint256 salt,
        address nftContract,
        address paymentToken,
        uint256 paymentAmount,
        uint256 expiryToken
    ) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encode(
                recipient,
                jobId,
                tokenId,
                units,
                salt,
                nftContract,
                paymentToken,
                paymentAmount,
                expiryToken
            )
        );
        return hash.toEthSignedMessageHash();
    }

    /// @dev Recovers signer from a hash and signature
    /// @param hash The hash that was signed
    /// @param signature The signature
    /// @return The address that signed the hash
    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        return hash.recover(signature);
    }

    /// @dev Checks if expiry token is still valid
    /// @param expiryToken Timestamp when token was created
    /// @param hoursValid How many hours the token is valid for
    /// @param currentTime Current timestamp
    /// @return True if token is still valid
    function isExpiryValid(uint256 expiryToken, uint8 hoursValid, uint256 currentTime) internal pure returns (bool) {
        require(expiryToken <= currentTime, "Expiry token must be in the past");
        uint256 hoursInSeconds = uint256(hoursValid) * 1 hours;
        uint256 diff = currentTime - expiryToken;
        return diff < hoursInSeconds;
    }

    /// @dev Verifies if an address has the minter notary role
    /// @param core Core contract reference
    /// @param signer Address to check role for
    /// @return True if address has the role
    function verifySigner(Core core, address signer) internal view returns (bool) {
        return core.hasRole(Roles.MINTER_NOTARY_PROTOCOL_ROLE, signer);
    }

    /// @dev Validates range of a value
    /// @param value Value to check
    /// @param min Minimum allowed
    /// @param max Maximum allowed
    /// @return True if within range
    function isValidRange(uint8 value, uint8 min, uint8 max) internal pure returns (bool) {
        return value >= min && value <= max;
    }
} 