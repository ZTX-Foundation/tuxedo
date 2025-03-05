// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import {HashValidator} from "./HashValidator.sol";
import {Core} from "@protocol/core/Core.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {RateManager} from "./RateManager.sol";

/// @title BatchProcessor
/// @notice Library for batch processing of NFT minting operations
library BatchProcessor {
    /// @dev Struct to hold batch processing parameters
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

    /// @dev Results of batch processing
    struct BatchResults {
        uint256[] tokenIds;
        uint256[] units;
        uint256 totalPayment;
        uint256 totalUnits;
    }
    
    /// @dev Processes a batch of mint requests
    /// @param core Core contract reference
    /// @param expiryHoursValid Hours validity for expiry tokens
    /// @param expiredHashes Mapping of expired hashes
    /// @param completedJobs Mapping of completed jobs
    /// @param nftContract NFT contract address
    /// @param recipient Recipient of the minted tokens
    /// @param paymentToken Payment token address
    /// @param params Batch mint parameters
    /// @return results The batch results including tokenIds and units
    function processBatch(
        Core core,
        uint8 expiryHoursValid,
        mapping(bytes32 => bool) storage expiredHashes,
        mapping(uint256 => bool) storage completedJobs,
        address nftContract,
        address recipient,
        address paymentToken,
        MintBatchParams[] memory params
    ) internal returns (BatchResults memory results) {
        require(params.length > 0, "ERC1155AutoGraphMinter: Empty batch");
        
        // Initialize arrays for batch minting
        results.tokenIds = new uint256[](params.length);
        results.units = new uint256[](params.length);
        results.totalPayment = 0;
        results.totalUnits = 0;
        
        for (uint256 i = 0; i < params.length; i++) {
            MintBatchParams memory param = params[i];
            
            // First check if hash is already expired (this check should happen before hash validation)
            require(!expiredHashes[param.hash], "ERC1155AutoGraphMinter: Hash expired");
            require(!completedJobs[param.jobId], "ERC1155AutoGraphMinter: Job already completed");
            
            // Next check expiry token
            require(
                HashValidator.isExpiryValid(param.expiryToken, expiryHoursValid, block.timestamp),
                "ERC1155AutoGraphMinter: Expiry token is expired"
            );
            
            // Finally verify hash
            bytes32 expectedHash = HashValidator.generateHash(
                recipient,
                param.jobId,
                param.tokenId,
                param.units,
                param.salt,
                nftContract,
                paymentToken,
                param.paymentAmount,
                param.expiryToken
            );
            require(expectedHash == param.hash, "ERC1155AutoGraphMinter: Hash mismatch");
            
            // Verify signature
            address signer = HashValidator.recoverSigner(param.hash, param.signature);
            require(HashValidator.verifySigner(core, signer), "ERC1155AutoGraphMinter: Missing MINTER_NOTARY Role");
            
            // Mark as processed
            expiredHashes[param.hash] = true;
            completedJobs[param.jobId] = true;
            
            // Add to batch arrays
            results.tokenIds[i] = param.tokenId;
            results.units[i] = param.units;
            results.totalPayment += param.paymentAmount;
            results.totalUnits += param.units;
        }
        
        return results;
    }
    
    /// @notice Process a complete batch operation with ETH payment
    /// @param core Core contract reference
    /// @param expiryHoursValid Hours validity for expiry tokens
    /// @param expiredHashes Mapping of expired hashes
    /// @param completedJobs Mapping of completed jobs
    /// @param nftContract NFT contract address
    /// @param recipient Recipient address
    /// @param rateState Rate state storage
    /// @param replenishRate Replenish rate per second
    /// @param bufferCap Buffer capacity
    /// @param params Batch parameters
    /// @return results The batch results
    /// @return bufferRemaining Remaining buffer after depletion
    function processCompleteBatchWithEth(
        Core core,
        uint8 expiryHoursValid,
        mapping(bytes32 => bool) storage expiredHashes,
        mapping(uint256 => bool) storage completedJobs,
        address nftContract,
        address recipient,
        RateManager.RateState storage rateState,
        uint128 replenishRate,
        uint128 bufferCap,
        MintBatchParams[] memory params
    ) internal returns (BatchResults memory, uint128) {
        // Process batch directly without creating too many local variables
        BatchResults memory results = processBatch(
            core,
            expiryHoursValid,
            expiredHashes,
            completedJobs,
            nftContract,
            recipient,
            address(0),
            params
        );
        
        // Apply rate limit directly
        uint128 bufferRemaining = RateManager.deplete(
            rateState, 
            results.totalUnits, 
            replenishRate, 
            bufferCap
        );
        
        // Mint tokens
        ERC1155MaxSupplyMintable(nftContract).mintBatch(
            recipient, 
            results.tokenIds, 
            results.units
        );
        
        return (results, bufferRemaining);
    }
    
    /// @notice Process a complete batch operation with token payment
    /// @param core Core contract reference
    /// @param expiryHoursValid Hours validity for expiry tokens
    /// @param expiredHashes Mapping of expired hashes
    /// @param completedJobs Mapping of completed jobs
    /// @param nftContract NFT contract address
    /// @param recipient Recipient address
    /// @param paymentToken Payment token address
    /// @param rateState Rate state storage
    /// @param replenishRate Replenish rate per second
    /// @param bufferCap Buffer capacity
    /// @param params Batch parameters
    /// @return results The batch results
    /// @return bufferRemaining Remaining buffer after depletion
    function processCompleteBatchWithToken(
        Core core,
        uint8 expiryHoursValid,
        mapping(bytes32 => bool) storage expiredHashes,
        mapping(uint256 => bool) storage completedJobs,
        address nftContract,
        address recipient,
        address paymentToken,
        RateManager.RateState storage rateState,
        uint128 replenishRate,
        uint128 bufferCap,
        MintBatchParams[] memory params
    ) internal returns (BatchResults memory results, uint128 bufferRemaining) {
        // Process batch and verify signatures, etc.
        results = processBatch(
            core,
            expiryHoursValid,
            expiredHashes,
            completedJobs,
            nftContract,
            recipient,
            paymentToken,
            params
        );
        
        // Calculate total units for rate limiting
        uint256 totalUnits = results.totalUnits;
        
        // Apply rate limit
        bufferRemaining = RateManager.deplete(rateState, totalUnits, replenishRate, bufferCap);
        
        // Mint the tokens
        ERC1155MaxSupplyMintable(nftContract).mintBatch(recipient, results.tokenIds, results.units);
        
        return (results, bufferRemaining);
    }

    /// @notice Process a complete batch operation for free minting
    /// @param core Core contract reference
    /// @param expiryHoursValid Hours validity for expiry tokens
    /// @param expiredHashes Mapping of expired hashes
    /// @param completedJobs Mapping of completed jobs
    /// @param nftContract NFT contract address
    /// @param recipient Recipient address
    /// @param rateState Rate state storage
    /// @param replenishRate Replenish rate per second
    /// @param bufferCap Buffer capacity
    /// @param params Batch parameters
    /// @return results The batch results
    /// @return bufferRemaining Remaining buffer after depletion
    function processCompleteBatchForFree(
        Core core,
        uint8 expiryHoursValid,
        mapping(bytes32 => bool) storage expiredHashes,
        mapping(uint256 => bool) storage completedJobs,
        address nftContract,
        address recipient,
        RateManager.RateState storage rateState,
        uint128 replenishRate,
        uint128 bufferCap,
        MintBatchParams[] memory params
    ) internal returns (BatchResults memory results, uint128 bufferRemaining) {
        // Process batch and verify signatures, etc.
        results = processBatch(
            core,
            expiryHoursValid,
            expiredHashes,
            completedJobs,
            nftContract,
            recipient,
            address(0),
            params
        );
        
        // Apply rate limit
        bufferRemaining = RateManager.deplete(rateState, results.totalUnits, replenishRate, bufferCap);
        
        // Mint the tokens
        ERC1155MaxSupplyMintable(nftContract).mintBatch(recipient, results.tokenIds, results.units);
        
        return (results, bufferRemaining);
    }
} 