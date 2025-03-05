// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {RateManager} from "./RateManager.sol";
import {HashValidator} from "./HashValidator.sol";
import {Core} from "@protocol/core/Core.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title MintProcessor
/// @notice Library for handling NFT minting operations
library MintProcessor {
    using SafeERC20 for IERC20;

    /// @notice Struct to pack the ETH mint parameters to avoid stack too deep
    struct EthMintParams {
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
    
    /// @notice Struct to pack the free mint parameters to avoid stack too deep
    struct FreeMintParams {
        address recipient;
        uint256 jobId;
        uint256 tokenId;
        uint256 units;
        bytes32 hash;
        uint256 salt;
        bytes signature;
        address nftContract;
        uint256 expiryToken;
    }

    /// @notice Process the entire token mint operation with payment
    /// @return bufferRemaining The remaining buffer after minting
    function processTokenMintWithPayment(
        Core core,
        uint8 expiryTokenHoursValid,
        mapping(bytes32 => bool) storage expiredHashes,
        mapping(uint256 => bool) storage completedJobs,
        RateManager.RateState storage rateState,
        address payer,
        address paymentRecipient,
        address recipient,
        uint256 jobId,
        uint256 tokenId,
        uint256 units,
        bytes32 hash,
        uint256 salt,
        bytes memory signature,
        address nftContract,
        address paymentToken,
        uint256 paymentAmount,
        uint256 expiryToken
    ) internal returns (uint128 bufferRemaining) {
        // Verify not already processed
        require(!expiredHashes[hash], "Hash expired");
        require(!completedJobs[jobId], "Job already completed");
        
        // Verify expiry
        require(
            HashValidator.isExpiryValid(expiryToken, expiryTokenHoursValid, block.timestamp),
            "Expiry token is expired"
        );
        
        // Verify hash
        bytes32 expectedHash = HashValidator.generateHash(
            recipient,
            jobId,
            tokenId,
            units,
            salt,
            nftContract,
            paymentToken,
            paymentAmount,
            expiryToken
        );
        require(expectedHash == hash, "Hash mismatch");
        
        // Verify signature
        address signer = HashValidator.recoverSigner(hash, signature);
        require(HashValidator.verifySigner(core, signer), "Invalid signer");
        
        // Process payment
        if (paymentToken != address(0) && paymentAmount > 0) {
            IERC20(paymentToken).safeTransferFrom(
                payer,
                paymentRecipient,
                paymentAmount
            );
        }
        
        // Mark as processed
        expiredHashes[hash] = true;
        completedJobs[jobId] = true;
        
        // Use rate limit
        bufferRemaining = RateManager.deplete(rateState, units);
        
        // Mint tokens
        ERC1155MaxSupplyMintable(nftContract).mint(recipient, tokenId, units);
        
        return bufferRemaining;
    }

    /// @notice Complete minting process for a single token
    /// @param expiredHashes Mapping of expired hashes
    /// @param completedJobs Mapping of completed jobs
    /// @param rateState Rate state storage
    /// @param hash Hash to mark as expired
    /// @param jobId Job to mark as completed
    /// @param nftContract NFT contract address
    /// @param recipient Recipient of minted token
    /// @param tokenId Token ID to mint
    /// @param units Number of tokens to mint
    /// @return bufferRemaining Remaining buffer after depletion
    function processMint(
        mapping(bytes32 => bool) storage expiredHashes,
        mapping(uint256 => bool) storage completedJobs,
        RateManager.RateState storage rateState,
        bytes32 hash,
        uint256 jobId,
        address nftContract,
        address recipient,
        uint256 tokenId,
        uint256 units
    ) internal returns (uint128 bufferRemaining) {
        // Mark as processed
        expiredHashes[hash] = true;
        completedJobs[jobId] = true;
        
        // Use rate limit
        bufferRemaining = RateManager.deplete(rateState, units);
        
        // Mint tokens
        ERC1155MaxSupplyMintable(nftContract).mint(recipient, tokenId, units);
        
        return bufferRemaining;
    }

    /// @notice Verify the mint parameters
    /// @param core Contract core
    /// @param expiryTokenHoursValid Hours that expiry tokens are valid
    /// @param expiredHashes Mapping of expired hashes
    /// @param completedJobs Mapping of completed jobs
    /// @param recipient Recipient address
    /// @param jobId Job identifier
    /// @param tokenId Token ID
    /// @param units Number of tokens
    /// @param hash Hash to verify
    /// @param salt Salt for hash
    /// @param signature Signature to verify
    /// @param nftContract NFT contract address
    /// @param paymentToken Payment token address (0 for free mints)
    /// @param paymentAmount Payment amount
    /// @param expiryToken Expiration timestamp
    function verifyMint(
        Core core,
        uint8 expiryTokenHoursValid,
        mapping(bytes32 => bool) storage expiredHashes,
        mapping(uint256 => bool) storage completedJobs,
        address recipient,
        uint256 jobId,
        uint256 tokenId,
        uint256 units,
        bytes32 hash,
        uint256 salt,
        bytes memory signature,
        address nftContract,
        address paymentToken,
        uint256 paymentAmount,
        uint256 expiryToken
    ) internal view {
        // Verify not already processed
        require(!expiredHashes[hash], "Hash expired");
        require(!completedJobs[jobId], "Job already completed");
        
        // Verify expiry
        require(
            HashValidator.isExpiryValid(expiryToken, expiryTokenHoursValid, block.timestamp),
            "Expiry token is expired"
        );
        
        // Verify hash
        bytes32 expectedHash = HashValidator.generateHash(
            recipient,
            jobId,
            tokenId,
            units,
            salt,
            nftContract,
            paymentToken,
            paymentAmount,
            expiryToken
        );
        require(expectedHash == hash, "Hash mismatch");
        
        // Verify signature
        address signer = HashValidator.recoverSigner(hash, signature);
        require(HashValidator.verifySigner(core, signer), "Invalid signer");
    }

    /// @notice Mark job as completed and hash as expired
    /// @param expiredHashes Mapping of expired hashes
    /// @param completedJobs Mapping of completed jobs
    /// @param hash Hash to mark as expired
    /// @param jobId Job to mark as completed
    function markAsProcessed(
        mapping(bytes32 => bool) storage expiredHashes,
        mapping(uint256 => bool) storage completedJobs,
        bytes32 hash,
        uint256 jobId
    ) internal {
        expiredHashes[hash] = true;
        completedJobs[jobId] = true;
    }

    /// @notice Mint a single token
    /// @param nftContract NFT contract address
    /// @param recipient Recipient of minted token
    /// @param tokenId Token ID to mint
    /// @param units Number of tokens to mint
    function mintToken(
        address nftContract,
        address recipient,
        uint256 tokenId,
        uint256 units
    ) internal {
        ERC1155MaxSupplyMintable(nftContract).mint(recipient, tokenId, units);
    }

    /// @notice Mint a batch of tokens
    /// @param nftContract NFT contract address
    /// @param recipient Recipient of minted tokens
    /// @param tokenIds Token IDs to mint
    /// @param units Number of tokens to mint for each ID
    function mintBatchTokens(
        address nftContract,
        address recipient,
        uint256[] memory tokenIds,
        uint256[] memory units
    ) internal {
        ERC1155MaxSupplyMintable(nftContract).mintBatch(recipient, tokenIds, units);
    }

    /// @notice Calculate and use rate limit
    /// @param rateState Rate state storage
    /// @param units Number of units to deplete
    /// @return bufferRemaining Remaining buffer after depletion
    function useRateLimit(
        RateManager.RateState storage rateState,
        uint256 units
    ) internal returns (uint128) {
        return RateManager.deplete(rateState, units);
    }

    /// @notice Calculate and use rate limit for batch
    /// @param rateState Rate state storage
    /// @param units Array of units to deplete
    /// @return bufferRemaining Remaining buffer after depletion
    function useRateLimitForBatch(
        RateManager.RateState storage rateState,
        uint256[] memory units
    ) internal returns (uint128) {
        uint256 totalUnits = 0;
        for (uint256 i = 0; i < units.length; i++) {
            totalUnits += units[i];
        }
        return RateManager.deplete(rateState, totalUnits);
    }

    /// @notice Process mint with ETH payment validation using packed parameters
    /// @return bufferRemaining The remaining buffer after minting
    function processEthMintWithParams(
        Core core,
        uint8 expiryTokenHoursValid,
        mapping(bytes32 => bool) storage expiredHashes,
        mapping(uint256 => bool) storage completedJobs,
        RateManager.RateState storage rateState,
        EthMintParams memory params
    ) internal returns (uint128 bufferRemaining) {
        // Verify not already processed
        require(!expiredHashes[params.hash], "Hash expired");
        require(!completedJobs[params.jobId], "Job already completed");
        
        // Verify expiry
        require(
            HashValidator.isExpiryValid(params.expiryToken, expiryTokenHoursValid, block.timestamp),
            "Expiry token is expired"
        );
        
        // Verify hash
        bytes32 expectedHash = HashValidator.generateHash(
            params.recipient,
            params.jobId,
            params.tokenId,
            params.units,
            params.salt,
            params.nftContract,
            address(0),
            params.paymentAmount,
            params.expiryToken
        );
        require(expectedHash == params.hash, "Hash mismatch");
        
        // Verify signature
        address signer = HashValidator.recoverSigner(params.hash, params.signature);
        require(HashValidator.verifySigner(core, signer), "Invalid signer");
        
        // Mark as processed
        expiredHashes[params.hash] = true;
        completedJobs[params.jobId] = true;
        
        // Use rate limit
        bufferRemaining = RateManager.deplete(rateState, params.units);
        
        // Mint tokens
        ERC1155MaxSupplyMintable(params.nftContract).mint(params.recipient, params.tokenId, params.units);
        
        return bufferRemaining;
    }

    /// @notice Process a free mint operation with packed parameters
    /// @return bufferRemaining The remaining buffer after minting
    function processFreeMintWithParams(
        Core core,
        uint8 expiryTokenHoursValid,
        mapping(bytes32 => bool) storage expiredHashes,
        mapping(uint256 => bool) storage completedJobs,
        RateManager.RateState storage rateState,
        FreeMintParams memory params
    ) internal returns (uint128 bufferRemaining) {
        // Verify not already processed
        require(!expiredHashes[params.hash], "Hash expired");
        require(!completedJobs[params.jobId], "Job already completed");
        
        // Verify expiry
        require(
            HashValidator.isExpiryValid(params.expiryToken, expiryTokenHoursValid, block.timestamp),
            "Expiry token is expired"
        );
        
        // Verify hash
        bytes32 expectedHash = HashValidator.generateHash(
            params.recipient,
            params.jobId,
            params.tokenId,
            params.units,
            params.salt,
            params.nftContract,
            address(0),
            0,
            params.expiryToken
        );
        require(expectedHash == params.hash, "Hash mismatch");
        
        // Verify signature
        address signer = HashValidator.recoverSigner(params.hash, params.signature);
        require(HashValidator.verifySigner(core, signer), "Invalid signer");
        
        // Mark as processed
        expiredHashes[params.hash] = true;
        completedJobs[params.jobId] = true;
        
        // Use rate limit
        bufferRemaining = RateManager.deplete(rateState, params.units);
        
        // Mint tokens
        ERC1155MaxSupplyMintable(params.nftContract).mint(params.recipient, params.tokenId, params.units);
        
        return bufferRemaining;
    }
} 