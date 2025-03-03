// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {ERC1155AutoGraphMinterBase} from "./ERC1155AutoGraphMinterBase.sol";
import {ERC1155AutoGraphMinterLib} from "./ERC1155AutoGraphMinterLib.sol";
import {Roles} from "@protocol/core/Roles.sol";

/**
 * @title ERC1155AutoGraphMinterCore
 * @notice Core implementation with minting business logic
 */
contract ERC1155AutoGraphMinterCore is ERC1155AutoGraphMinterBase {
    using ERC1155AutoGraphMinterLib for *;

    constructor(
        address _core,
        address[] memory _nftContracts,
        uint128 _replenishRatePerSecond,
        uint128 _bufferCap,
        address _paymentRecipient,
        uint8 _expiryTokenHoursValid
    )
        ERC1155AutoGraphMinterBase(
            _core,
            _nftContracts,
            _replenishRatePerSecond,
            _bufferCap,
            _paymentRecipient,
            _expiryTokenHoursValid
        )
    {}

    /// @dev - Verifies the inputs and processes the mint
    function _verifyHashAndSignerRoleExpireHashAndDepleteBuffer(
        ERC1155AutoGraphMinterLib.VerifyInputParams memory params
    ) internal {
        require(
            ERC1155AutoGraphMinterLib.isExpiryTokenValid(params.expiryToken, expiryTokenHoursValid),
            "ERC1155AutoGraphMinter: Expiry token is expired"
        );
        require(params.inputHash == params.generatedHash, "ERC1155AutoGraphMinter: Hash mismatch");
        require(!expiredHashes[params.inputHash], "ERC1155AutoGraphMinter: Hash expired");
        require(!completedJobs[params.jobId], "ERC1155AutoGraphMinter: Job already completed");
        require(
            core.hasRole(
                Roles.MINTER_NOTARY_PROTOCOL_ROLE,
                ERC1155AutoGraphMinterLib.recoverSigner(params.inputHash, params.signature)
            ),
            "ERC1155AutoGraphMinter: Missing MINTER_NOTARY Role"
        );

        // expire that hash
        expiredHashes[params.inputHash] = true;

        // expire the job
        completedJobs[params.jobId] = true;

        // deplete the rate limit buffer
        _depleteBuffer(params.units);
    }

    /// @dev - Internal batch minting implementation
    function _mintBatch(
        address nftContract,
        address recipient,
        address paymentToken,
        ERC1155AutoGraphMinterLib.MintBatchParams[] memory inputs
    ) internal returns (uint256[] memory tokenIds, uint256[] memory units, uint256 totalPayment) {
        tokenIds = new uint256[](inputs.length);
        units = new uint256[](inputs.length);
        totalPayment = 0;

        for (uint256 i = 0; i < inputs.length; i++) {
            ERC1155AutoGraphMinterLib.HashInputsParams memory hashInput = ERC1155AutoGraphMinterLib.HashInputsParams(
                recipient,
                inputs[i].jobId,
                inputs[i].tokenId,
                inputs[i].units,
                inputs[i].salt,
                nftContract,
                paymentToken,
                inputs[i].paymentAmount,
                inputs[i].expiryToken
            );

            ERC1155AutoGraphMinterLib.VerifyInputParams memory verifyInput = ERC1155AutoGraphMinterLib
                .VerifyInputParams(
                    inputs[i].hash,
                    inputs[i].jobId,
                    ERC1155AutoGraphMinterLib.getHash(hashInput),
                    inputs[i].signature,
                    inputs[i].units,
                    nftContract,
                    inputs[i].expiryToken
                );

            _verifyHashAndSignerRoleExpireHashAndDepleteBuffer(verifyInput);

            tokenIds[i] = inputs[i].tokenId;
            units[i] = inputs[i].units;
            totalPayment += inputs[i].paymentAmount;
        }

        return (tokenIds, units, totalPayment);
    }
}
