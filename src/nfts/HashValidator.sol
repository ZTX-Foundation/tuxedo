// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";

/// @title HashValidator
/// @notice Library for validating hashes and signatures
library HashValidator {
    using ECDSA for bytes32;

    /// @notice Generate a hash for minting validation
    /// @param recipient Recipient of the minted tokens
    /// @param jobId Job ID
    /// @param tokenId Token ID to mint
    /// @param units Number of tokens to mint
    /// @param salt Random salt for hash uniqueness
    /// @param nftContract NFT contract address
    /// @param paymentToken Payment token address (zero for ETH)
    /// @param paymentAmount Payment amount
    /// @param expiryToken Expiry timestamp
    /// @return hash Generated hash
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
    ) public pure returns (bytes32 hash) {
        bytes32 hashFirstPass = keccak256(
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
        return hashFirstPass.toEthSignedMessageHash();
    }

    /// @notice Verify if an expiry token is valid
    /// @param expiryToken Token timestamp
    /// @param expiryHoursValid Hours of validity
    /// @param currentTimestamp Current timestamp
    /// @return isValid True if valid
    function isExpiryValid(
        uint256 expiryToken,
        uint8 expiryHoursValid,
        uint256 currentTimestamp
    ) public pure returns (bool isValid) {
        // Expiry token must be in the past
        if (expiryToken > currentTimestamp) {
            return false;
        }

        // Expiry should not be too old
        uint256 expiryDuration = expiryHoursValid * 1 hours;
        if (currentTimestamp > expiryToken + expiryDuration) {
            return false;
        }

        return true;
    }

    /// @notice Recover the signer of a hash
    /// @param hash The hash that was signed
    /// @param signature The signature bytes
    /// @return signer The address that signed the hash
    function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address signer) {
        return hash.recover(signature);
    }

    /// @notice Verify if a signer has the MINTER_NOTARY_PROTOCOL_ROLE
    /// @param core Core contract reference
    /// @param signer Signer address to check
    /// @return hasRole True if signer has the role
    function verifySigner(Core core, address signer) public view returns (bool hasRole) {
        return core.hasRole(Roles.MINTER_NOTARY_PROTOCOL_ROLE, signer);
    }
} 