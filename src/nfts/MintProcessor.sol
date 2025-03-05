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
    
    /// @notice Struct to pack the token mint parameters to avoid stack too deep
    struct TokenMintParams {
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

    /// @notice Process a token mint with payment
    /// @return bufferRemaining The remaining buffer after minting
    function processTokenMint(
        Core core,
        uint8 expiryTokenHoursValid,
        mapping(bytes32 => bool) storage expiredHashes,
        mapping(uint256 => bool) storage completedJobs,
        RateManager.RateState storage rateState,
        uint128 replenishRate,
        uint128 bufferCap,
        TokenMintParams memory params
    ) internal returns (uint128 bufferRemaining) {
        // First check if already processed
        require(!expiredHashes[params.hash], "ERC1155AutoGraphMinter: Hash expired");
        require(!completedJobs[params.jobId], "ERC1155AutoGraphMinter: Job already completed");
        
        // Next verify expiry
        require(
            HashValidator.isExpiryValid(params.expiryToken, expiryTokenHoursValid, block.timestamp),
            "ERC1155AutoGraphMinter: Expiry token is expired"
        );
        
        // Finally verify hash
        bytes32 expectedHash = HashValidator.generateHash(
            params.recipient,
            params.jobId,
            params.tokenId,
            params.units,
            params.salt,
            params.nftContract,
            params.paymentToken,
            params.paymentAmount,
            params.expiryToken
        );
        require(expectedHash == params.hash, "ERC1155AutoGraphMinter: Hash mismatch");
        
        // Verify signature
        address signer = HashValidator.recoverSigner(params.hash, params.signature);
        require(HashValidator.verifySigner(core, signer), "ERC1155AutoGraphMinter: Missing MINTER_NOTARY Role");
        
        // Mark as processed
        expiredHashes[params.hash] = true;
        completedJobs[params.jobId] = true;
        
        // Use rate limit
        bufferRemaining = RateManager.deplete(rateState, params.units, replenishRate, bufferCap);
        
        // Mint tokens
        ERC1155MaxSupplyMintable(params.nftContract).mint(params.recipient, params.tokenId, params.units);
        
        return bufferRemaining;
    }

    /// @notice Process ETH mint with packed parameters
    /// @return bufferRemaining The remaining buffer after minting
    function processEthMintWithParams(
        Core core,
        uint8 expiryTokenHoursValid,
        mapping(bytes32 => bool) storage expiredHashes,
        mapping(uint256 => bool) storage completedJobs,
        RateManager.RateState storage rateState,
        uint128 replenishRate,
        uint128 bufferCap,
        EthMintParams memory params
    ) internal returns (uint128 bufferRemaining) {
        // First check if already processed
        require(!expiredHashes[params.hash], "ERC1155AutoGraphMinter: Hash expired");
        require(!completedJobs[params.jobId], "ERC1155AutoGraphMinter: Job already completed");
        
        // Next verify expiry
        require(
            HashValidator.isExpiryValid(params.expiryToken, expiryTokenHoursValid, block.timestamp),
            "ERC1155AutoGraphMinter: Expiry token is expired"
        );
        
        // Finally verify hash
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
        require(expectedHash == params.hash, "ERC1155AutoGraphMinter: Hash mismatch");
        
        // Verify signature
        address signer = HashValidator.recoverSigner(params.hash, params.signature);
        require(HashValidator.verifySigner(core, signer), "ERC1155AutoGraphMinter: Missing MINTER_NOTARY Role");
        
        // Mark as processed
        expiredHashes[params.hash] = true;
        completedJobs[params.jobId] = true;
        
        // Use rate limit
        bufferRemaining = RateManager.deplete(rateState, params.units, replenishRate, bufferCap);
        
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
        uint128 replenishRate,
        uint128 bufferCap,
        FreeMintParams memory params
    ) internal returns (uint128 bufferRemaining) {
        // First check if already processed
        require(!expiredHashes[params.hash], "ERC1155AutoGraphMinter: Hash expired");
        require(!completedJobs[params.jobId], "ERC1155AutoGraphMinter: Job already completed");
        
        // Next verify expiry
        require(
            HashValidator.isExpiryValid(params.expiryToken, expiryTokenHoursValid, block.timestamp),
            "ERC1155AutoGraphMinter: Expiry token is expired"
        );
        
        // Finally verify hash
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
        require(expectedHash == params.hash, "ERC1155AutoGraphMinter: Hash mismatch");
        
        // Verify signature
        address signer = HashValidator.recoverSigner(params.hash, params.signature);
        require(HashValidator.verifySigner(core, signer), "ERC1155AutoGraphMinter: Missing MINTER_NOTARY Role");
        
        // Mark as processed
        expiredHashes[params.hash] = true;
        completedJobs[params.jobId] = true;
        
        // Use rate limit
        bufferRemaining = RateManager.deplete(rateState, params.units, replenishRate, bufferCap);
        
        // Mint tokens
        ERC1155MaxSupplyMintable(params.nftContract).mint(params.recipient, params.tokenId, params.units);
        
        return bufferRemaining;
    }
} 