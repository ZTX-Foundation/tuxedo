// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {ERC1155AutoGraphMinterCore} from "./ERC1155AutoGraphMinterCore.sol";
import {ERC1155AutoGraphMinterLib} from "./ERC1155AutoGraphMinterLib.sol";

/**
 * @title ERC1155AutoGraphMinter
 * @notice Main contract providing public API for minting operations
 */
contract ERC1155AutoGraphMinter is ERC1155AutoGraphMinterCore {
    using SafeERC20 for IERC20;
    using ERC1155AutoGraphMinterLib for *;

    constructor(
        address _core,
        address[] memory _nftContracts,
        uint128 _replenishRatePerSecond,
        uint128 _bufferCap,
        address _paymentRecipient,
        uint8 _expiryTokenHoursValid
    )
        ERC1155AutoGraphMinterCore(
            _core,
            _nftContracts,
            _replenishRatePerSecond,
            _bufferCap,
            _paymentRecipient,
            _expiryTokenHoursValid
        )
    {}

    /// @notice - Mint NFTs to a given address with a given signature for free
    function mintForFree(
        address recipient,
        uint256 jobId,
        uint256 tokenId,
        uint256 units,
        bytes32 hash,
        uint256 salt,
        bytes memory signature,
        address nftContract,
        uint256 expiryToken
    ) external globalLock(1) whenNotPaused onlyWhitelist(nftContract) {
        ERC1155AutoGraphMinterLib.HashInputsParams memory input = ERC1155AutoGraphMinterLib.HashInputsParams(
            recipient,
            jobId,
            tokenId,
            units,
            salt,
            nftContract,
            address(0),
            0,
            expiryToken
        );

        ERC1155AutoGraphMinterLib.VerifyInputParams memory params = ERC1155AutoGraphMinterLib.VerifyInputParams(
            hash,
            jobId,
            ERC1155AutoGraphMinterLib.getHash(input),
            signature,
            units,
            nftContract,
            expiryToken
        );

        _verifyHashAndSignerRoleExpireHashAndDepleteBuffer(params);

        ERC1155MaxSupplyMintable(nftContract).mint(recipient, tokenId, units);
        emit ERC1155Minted(nftContract, recipient, jobId, tokenId);
    }

    /// @notice - Mint NFTs to a given address with a given signature
    function mintWithPaymentTokenAsFee(
        ERC1155AutoGraphMinterLib.MintWithPaymentTokenAsFeeParams memory params
    ) external globalLock(1) whenNotPaused onlyWhitelist(params.nftContract) {
        ERC1155AutoGraphMinterLib.HashInputsParams memory input = ERC1155AutoGraphMinterLib.HashInputsParams(
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

        ERC1155AutoGraphMinterLib.VerifyInputParams memory verifyInputParams = ERC1155AutoGraphMinterLib
            .VerifyInputParams(
                params.hash,
                params.jobId,
                ERC1155AutoGraphMinterLib.getHash(input),
                params.signature,
                params.units,
                params.nftContract,
                params.expiryToken
            );

        ERC1155AutoGraphMinterLib.validatePaymentTokenFee(params.paymentToken, params.paymentAmount);
        _verifyHashAndSignerRoleExpireHashAndDepleteBuffer(verifyInputParams);

        /// make transfer for fee payment
        IERC20(params.paymentToken).safeTransferFrom(msg.sender, paymentRecipient, params.paymentAmount);

        ERC1155MaxSupplyMintable(params.nftContract).mint(params.recipient, params.tokenId, params.units);
        emit ERC1155Minted(params.nftContract, params.recipient, params.jobId, params.tokenId);
    }

    /// @notice - Mint NFTs with Eth as fee
    function mintWithEthAsFee(
        ERC1155AutoGraphMinterLib.MintWithEthAsFeeParams memory params
    ) external payable globalLock(1) whenNotPaused onlyWhitelist(params.nftContract) {
        ERC1155AutoGraphMinterLib.HashInputsParams memory input = ERC1155AutoGraphMinterLib.HashInputsParams(
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

        ERC1155AutoGraphMinterLib.VerifyInputParams memory verifyInputParams = ERC1155AutoGraphMinterLib
            .VerifyInputParams(
                params.hash,
                params.jobId,
                ERC1155AutoGraphMinterLib.getHash(input),
                params.signature,
                params.units,
                params.nftContract,
                params.expiryToken
            );

        ERC1155AutoGraphMinterLib.validateEthFee(params.paymentAmount);
        _verifyHashAndSignerRoleExpireHashAndDepleteBuffer(verifyInputParams);

        /// make transfer
        (bool sent, ) = payable(paymentRecipient).call{value: params.paymentAmount}("");
        require(sent, "ERC1155AutoGraphMinter: Failed to send Ether");

        ERC1155MaxSupplyMintable(params.nftContract).mint(params.recipient, params.tokenId, params.units);
        emit ERC1155Minted(params.nftContract, params.recipient, params.jobId, params.tokenId);
    }

    /// @dev - Mint Batch of NFTs for free
    function mintBatchForFree(
        address nftContract,
        address recipient,
        ERC1155AutoGraphMinterLib.MintBatchParams[] memory inputs
    ) external globalLock(1) whenNotPaused onlyWhitelist(nftContract) {
        (uint256[] memory tokenIds, uint256[] memory units, ) = _mintBatch(nftContract, recipient, address(0), inputs);

        ERC1155MaxSupplyMintable(nftContract).mintBatch(recipient, tokenIds, units);
        emit ERC1155BatchMinted(nftContract, recipient, tokenIds, units);
    }

    /// @dev - Mint Batch of NFTs with payment token as fee
    function mintBatchWithPaymentTokenAsFee(
        address nftContract,
        address recipient,
        address paymentToken,
        ERC1155AutoGraphMinterLib.MintBatchParams[] memory inputs
    ) external globalLock(1) whenNotPaused onlyWhitelist(nftContract) {
        (uint256[] memory tokenIds, uint256[] memory units, uint256 totalPayment) = _mintBatch(
            nftContract,
            recipient,
            paymentToken,
            inputs
        );

        ERC1155AutoGraphMinterLib.validatePaymentTokenFee(paymentToken, totalPayment);

        /// make transfer for fee payment
        IERC20(paymentToken).safeTransferFrom(msg.sender, paymentRecipient, totalPayment);

        ERC1155MaxSupplyMintable(nftContract).mintBatch(recipient, tokenIds, units);
        emit ERC1155BatchMinted(nftContract, recipient, tokenIds, units);
    }

    /// @dev - Mint Batch of NFTs with Eth as fee
    function mintBatchWithEthAsFee(
        address nftContract,
        address recipient,
        ERC1155AutoGraphMinterLib.MintBatchParams[] memory inputs
    ) external payable globalLock(1) whenNotPaused onlyWhitelist(nftContract) {
        (uint256[] memory tokenIds, uint256[] memory units, uint256 totalPayment) = _mintBatch(
            nftContract,
            recipient,
            address(0),
            inputs
        );

        require(msg.value == totalPayment, "ERC1155AutoGraphMinter: msg.value must match total payment");
        require(totalPayment > 0, "ERC1155AutoGraphMinter: paymentAmount must be greater than 0");

        (bool sent, ) = payable(paymentRecipient).call{value: totalPayment}("");
        require(sent, "ERC1155AutoGraphMinter: Failed to send Ether");

        ERC1155MaxSupplyMintable(nftContract).mintBatch(recipient, tokenIds, units);
        emit ERC1155BatchMinted(nftContract, recipient, tokenIds, units);
    }
}
