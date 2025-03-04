// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import {HashVerifier} from "./HashVerifier.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {Core} from "@protocol/core/Core.sol";

/**
 * @title BatchMinting
 * @notice Library for complex batch minting operations
 */
library BatchMinting {
    /// @dev reuse structs from HashVerifier
    using HashVerifier for HashVerifier.HashInputsParams;

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

    struct BatchProcessingResult {
        uint256[] tokenIds;
        uint256[] units;
        uint256 totalPayment;
    }

    struct BatchContext {
        Core core;
        uint8 expiryTokenHoursValid;
    }

    function processBatch(
        BatchContext memory context,
        mapping(bytes32 => bool) storage expiredHashes,
        mapping(uint256 => bool) storage completedJobs,
        address nftContract,
        address recipient,
        address paymentToken,
        MintBatchParams[] memory params,
        function(uint256) internal returns (uint128) depleteBufferFn
    ) internal returns (BatchProcessingResult memory result) {
        result.tokenIds = new uint256[](params.length);
        result.units = new uint256[](params.length);
        result.totalPayment = 0;

        for (uint256 i = 0; i < params.length; i++) {
            MintBatchParams memory param = params[i];

            HashVerifier.HashInputsParams memory input = HashVerifier.HashInputsParams({
                recipient: recipient,
                jobId: param.jobId,
                tokenId: param.tokenId,
                units: param.units,
                salt: param.salt,
                nftContract: nftContract,
                paymentToken: paymentToken,
                paymentAmount: param.paymentAmount,
                expiryToken: param.expiryToken
            });

            /// @dev generate hash
            bytes32 generatedHash = HashVerifier.getHash(input);

            /// @dev verify hash
            require(!expiredHashes[param.hash], "Hash expired");
            require(!completedJobs[param.jobId], "Job already completed");
            require(param.hash == generatedHash, "Hash verification failed");

            /// @dev verify signer
            address signer = HashVerifier.recoverSigner(param.hash, param.signature);
            require(HashVerifier.verifySignerRole(context.core, signer), "Signer does not have MINTER_NOTARY role");

            /// @dev verify expiry
            require(
                HashVerifier.isExpiryValid(param.expiryToken, context.expiryTokenHoursValid, block.timestamp),
                "Expiry token is expired"
            );

            /// @dev mark as expired and completed
            expiredHashes[param.hash] = true;
            completedJobs[param.jobId] = true;

            /// @dev deplete buffer
            depleteBufferFn(param.units);

            /// @dev store results
            result.tokenIds[i] = param.tokenId;
            result.units[i] = param.units;
            result.totalPayment += param.paymentAmount;
        }

        return result;
    }
}
