// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";

/// @title HashVerifier
/// @notice Library for hash verification, validation and other helper functions
library HashVerifier {
    using ECDSA for bytes32;

    /// @dev Struct containing all parameters needed for hash generation
    struct HashInputsParams {
        address recipient;
        uint256 jobId;
        uint256 tokenId;
        uint256 units;
        uint256 salt;
        address nftContract;
        address paymentToken;
        uint256 paymentAmount;
        uint256 expiryToken;
    }

    /// @dev Struct containing all parameters needed for hash verification
    struct VerifyInputParams {
        bytes32 inputHash;
        uint256 jobId;
        bytes32 generatedHash;
        bytes signature;
        uint256 units;
        address nftContract;
        uint256 expiryToken;
    }

    /// @dev Checks if a value is within a specified range
    /// @param value The value to check
    /// @param min The minimum allowed value
    /// @param max The maximum allowed value
    /// @return True if the value is within range
    function isValidRange(uint8 value, uint8 min, uint8 max) internal pure returns (bool) {
        return value >= min && value <= max;
    }

    /// @dev Generates a hash from the input parameters
    /// @param input The hash input parameters
    /// @return The generated Ethereum signed message hash
    function getHash(HashInputsParams memory input) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encode(
                input.recipient,
                input.jobId,
                input.tokenId,
                input.units,
                input.salt,
                input.nftContract,
                input.paymentToken,
                input.paymentAmount,
                input.expiryToken
            )
        );
        return hash.toEthSignedMessageHash();
    }

    /// @dev Recovers the signer address from a hash and signature
    /// @param hash The hash that was signed
    /// @param signature The signature to verify
    /// @return The recovered signer address
    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        return hash.recover(signature);
    }

    /// @dev Checks if an expiry token is still valid
    /// @param expiryToken The expiry token timestamp
    /// @param hoursValid Number of hours the token is valid for
    /// @param currentTime The current timestamp
    /// @return True if the expiry token is still valid
    function isExpiryValid(uint256 expiryToken, uint8 hoursValid, uint256 currentTime) internal pure returns (bool) {
        require(expiryToken <= currentTime, "Expiry token must be in the past");
        uint256 hoursInSeconds = uint256(hoursValid) * 1 hours;
        uint256 diff = currentTime - expiryToken;
        return diff < hoursInSeconds;
    }

    /// @dev Verifies if an address has the minter notary role
    /// @param core The Core contract
    /// @param signer The address to check
    /// @return True if the address has the role
    function verifySignerRole(Core core, address signer) internal view returns (bool) {
        return core.hasRole(Roles.MINTER_NOTARY_PROTOCOL_ROLE, signer);
    }

    /// @dev Validates an ETH payment
    /// @param msgValue The amount of ETH sent
    /// @param expectedAmount The expected payment amount
    function validateEthPayment(uint256 msgValue, uint256 expectedAmount) internal pure {
        require(msgValue == expectedAmount, "Payment amount does not match");
        require(expectedAmount > 0, "Payment amount must be greater than 0");
    }

    /// @dev Validates a token payment
    /// @param token The token address
    /// @param amount The payment amount
    function validateTokenPayment(address token, uint256 amount) internal pure {
        require(token != address(0), "Payment token cannot be address(0)");
        require(amount > 0, "Payment amount must be greater than 0");
    }
}
