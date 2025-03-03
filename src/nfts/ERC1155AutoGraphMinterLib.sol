// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title ERC1155AutoGraphMinterLib
 * @notice Library with data structures and helper functions
 */
library ERC1155AutoGraphMinterLib {
    using ECDSA for bytes32;

    /// --------- Structs ---------- ///

    /// @dev - MintBatchParams is a struct that contains the params for minting a batch of NFTs
    struct MintBatchParams {
        uint256 jobId;
        uint256 tokenId;
        uint256 units;
        bytes32 hash;
        uint256 salt;
        bytes signature;
        uint256 paymentAmount;
        uint256 expiryToken;
    }

    /// @dev - HashInputsParams is a struct that contains the params for generating a hash
    struct HashInputsParams {
        address recipient;
        uint256 jobId;
        uint256 tokenId; // nft token id to be minted
        uint256 units; // units to be minted
        uint256 salt;
        address nftContract; // nft contract address
        address paymentToken; // token to be used for payment if payment is required
        uint256 paymentAmount; // amount of token to be used for payment if payment is required
        uint256 expiryToken;
    }

    /// @dev helper function to verify and process mint inputs
    struct VerifyInputParams {
        bytes32 inputHash;
        uint256 jobId;
        bytes32 generatedHash;
        bytes signature;
        uint256 units;
        address nftContract;
        uint256 expiryToken;
    }

    /// @param recipient - Address of the receiver of the NFT
    /// @param tokenId - ID of the NFT
    /// @param jobId - ID of the job
    /// @param units - Amount of NFTs to mint
    /// @param hash - Hash of the message to be signed
    /// @param salt - Salt of the message to be signed
    /// @param signature - Signature of the message to be signed
    /// @param nftContract - Address of the NFT contract to Mint from
    /// @param paymentToken - Address of the token to be used for payment. Cant be address(0)
    /// @param paymentAmount - Amount of the token to be used for payment. Cant be 0
    /// @param expiryToken - Expiry token timestamp. ie create a timestamp.now on creation of the hash
    struct MintWithPaymentTokenAsFeeParams {
        address recipient;
        uint256 jobId;
        uint256 tokenId;
        uint256 units;
        bytes32 hash;
        uint256 salt;
        bytes signature;
        address nftContract;
        address paymentToken;
        uint256 paymentAmount;
        uint256 expiryToken;
    }

    /// @param recipient - Address of the receiver of the NFT
    /// @param jobId - ID of the job
    /// @param tokenId - ID of the NFT
    /// @param units - Amount of NFTs to mint
    /// @param hash - Hash of the message to be signed
    /// @param salt - Salt of the message to be signed
    /// @param signature - Signature of the message to be signed
    /// @param nftContract - Address of the NFT contract to Mint from
    /// @param paymentAmount - Amount of the token to be used for payment
    /// @param expiryToken - Expiry token timestamp. ie create a timestamp.now on creation of the hash
    struct MintWithEthAsFeeParams {
        address recipient;
        uint256 jobId;
        uint256 tokenId;
        uint256 units;
        bytes32 hash;
        uint256 salt;
        bytes signature;
        address nftContract;
        uint256 paymentAmount;
        uint256 expiryToken;
    }

    /// @dev - Returns the hash of the message
    /// @param input - hashInputs struct
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

    /// @dev - Returns the address that signed a given string message
    /// @param hash - Keccak-256 hash
    /// @param signature - Signature of the signed hash
    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        return hash.recover(signature);
    }

    /// @dev checks if the expiry token is valid
    function isExpiryTokenValid(uint256 expiryToken, uint8 expiryHours) internal view returns (bool) {
        require(expiryToken <= block.timestamp, "ERC1155AutoGraphMinter: Expiry token must be in the past");

        // Convert hours to seconds
        uint256 hoursInSeconds = uint256(expiryHours) * 1 hours;

        // get time diff
        uint256 diff = block.timestamp - expiryToken;

        return diff < hoursInSeconds;
    }

    /// @dev checks to make sure the payment token is set to a non address(0) address and the payment amount greater than 0
    function validatePaymentTokenFee(address paymentToken, uint256 paymentAmount) internal pure {
        require(paymentToken != address(0), "ERC1155AutoGraphMinter: paymentToken must not be address(0)");
        require(paymentAmount > 0, "ERC1155AutoGraphMinter: paymentAmount must be greater than 0");
    }

    /// @dev checks to make sure the payment amount matches the msg.value
    function validateEthFee(uint256 paymentAmount) internal view {
        require(paymentAmount > 0, "ERC1155AutoGraphMinter: paymentAmount must be greater than 0");
        require(msg.value == paymentAmount, "ERC1155AutoGraphMinter: msg.value must match paymentAmount");
    }
}
