// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import "@forge-std/Test.sol";
import {ERC1155AutoGraphMinter} from "@protocol/nfts/ERC1155AutoGraphMinter.sol";
import {BatchProcessor} from "@protocol/nfts/BatchProcessor.sol";
import {HashValidator} from "@protocol/nfts/HashValidator.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library ERC1155AutoGraphMinterHelperLib {
    using ECDSA for bytes32;

    struct TxParts {
        address recipient;
        uint256 jobId;
        uint256 tokenId;
        uint256 units;
        uint256 salt;
        bytes32 hash;
        bytes signature;
        uint256 paymentAmount;
        uint256 expiryToken;
    }

    struct SetupTxParams {
        Vm vm;
        uint256 privateKey;
        address nftContract;
        uint256 jobId;
        uint256 tokenId;
        uint256 units;
        address paymentToken;
        uint256 paymentAmount;
        uint256 expiryToken;
    }

    /// @dev Generate hash using the HashValidator library
    function getHash(
        address recipient,
        uint256 jobId,
        uint256 tokenId,
        uint256 units,
        uint256 salt,
        address nftContract,
        address paymentToken,
        uint256 paymentAmount,
        uint256 expiryToken
    ) public pure returns (bytes32) {
        return HashValidator.generateHash(
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
    }

    function setupTx(Vm vm, uint256 privateKey, address nftContract) public view returns (TxParts memory parts) {
        SetupTxParams memory txx = SetupTxParams(vm, privateKey, nftContract, 99, 0, 1, address(0), 0, block.timestamp);
        return setupTx(txx);
    }

    function setupTx(
        Vm vm,
        uint256 privateKey,
        address nftContract,
        uint tokenId,
        uint units
    ) public view returns (TxParts memory parts) {
        SetupTxParams memory txx = SetupTxParams(
            vm,
            privateKey,
            nftContract,
            99,
            tokenId,
            units,
            address(0),
            0,
            block.timestamp
        );
        return setupTx(txx);
    }

    function setupTx(
        Vm vm,
        uint256 privateKey,
        address nftContract,
        address paymentToken,
        uint256 paymentAmount,
        uint256 expiryToken
    ) public view returns (TxParts memory parts) {
        SetupTxParams memory txx = SetupTxParams(
            vm,
            privateKey,
            nftContract,
            99, // jobId
            0, // tokenId
            1, // units
            paymentToken,
            paymentAmount,
            expiryToken
        );
        return setupTx(txx);
    }

    // @dev setup a happy path txx
    function setupTx(SetupTxParams memory txx) public view returns (TxParts memory parts) {
        address recipient = address(this);
        uint256 salt = block.timestamp;

        parts.recipient = recipient;
        parts.jobId = txx.jobId;
        parts.tokenId = txx.tokenId;
        parts.units = txx.units;
        parts.salt = salt;
        parts.paymentAmount = txx.paymentAmount;
        parts.expiryToken = txx.expiryToken;

        // Generate hash
        bytes32 hash = getHash(
            recipient,
            txx.jobId,
            txx.tokenId,
            txx.units,
            salt,
            txx.nftContract,
            txx.paymentToken,
            txx.paymentAmount,
            txx.expiryToken
        );

        // Sign hash
        (uint8 v, bytes32 r, bytes32 s) = txx.vm.sign(txx.privateKey, hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        parts.hash = hash;
        parts.signature = signature;
    }

    function setupTxs(
        Vm vm,
        uint256 privateKey,
        ERC1155MaxSupplyMintable nft
    ) public view returns (BatchProcessor.MintBatchParams[] memory params) {
        return setupTxs(vm, privateKey, nft, 0, address(this), 10, address(0), 0, block.timestamp);
    }

    function setupTxs(
        Vm vm,
        uint256 privateKey,
        ERC1155MaxSupplyMintable nft,
        address recipient
    ) public view returns (BatchProcessor.MintBatchParams[] memory params) {
        return setupTxs(vm, privateKey, nft, 0, recipient, 10, address(0), 0, block.timestamp);
    }

    function setupTxs(
        Vm vm,
        uint256 privateKey,
        ERC1155MaxSupplyMintable nft,
        uint256 tokenId,
        address recipient,
        uint256 items,
        address paymentToken,
        uint256 paymentAmount,
        uint256 expiryToken
    ) public view returns (BatchProcessor.MintBatchParams[] memory params) {
        params = new BatchProcessor.MintBatchParams[](items);

        for (uint256 i = 0; i < items; i++) {
            TxParts memory parts = setupTx(
                vm,
                privateKey,
                address(nft),
                paymentToken,
                paymentAmount,
                expiryToken
            );

            params[i].jobId = parts.jobId + i;
            params[i].tokenId = tokenId + i;
            params[i].units = parts.units;
            params[i].hash = parts.hash;
            params[i].salt = parts.salt;
            params[i].signature = parts.signature;
            params[i].paymentAmount = parts.paymentAmount;
            params[i].expiryToken = parts.expiryToken;
        }

        return params;
    }

    /// @dev helper to mint a tokens via the autoGraphMinter in an intrgration test
    function mintForFree(
        Vm _vm,
        uint256 _privateKey,
        address _autoGraphMinterContract,
        address _nftContract,
        uint tokenId,
        uint units
    ) public {
        TxParts memory parts = setupTx(_vm, _privateKey, _nftContract, tokenId, units);

        ERC1155AutoGraphMinter(_autoGraphMinterContract).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            _nftContract,
            parts.expiryToken
        );
    }
}
