pragma solidity 0.8.18;

import "@forge-std/Test.sol";
import {ERC1155AutoGraphMinter} from "@protocol/nfts/ERC1155AutoGraphMinter.sol";
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

    function getHash(ERC1155AutoGraphMinter.HashInputsParams memory input) public pure returns (bytes32) {
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

        ERC1155AutoGraphMinter.HashInputsParams memory inputs = ERC1155AutoGraphMinter.HashInputsParams(
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

        // hash message
        bytes32 hash = getHash(inputs);

        // sign hash
        (uint8 v, bytes32 r, bytes32 s) = txx.vm.sign(txx.privateKey, hash);

        // encode signature
        bytes memory signature = abi.encodePacked(r, s, v);

        parts.recipient = recipient;
        parts.jobId = txx.jobId;
        parts.tokenId = txx.tokenId;
        parts.units = txx.units;
        parts.salt = salt;
        parts.hash = hash;
        parts.signature = signature;
        parts.paymentAmount = txx.paymentAmount;
        parts.expiryToken = txx.expiryToken;

        return parts;
    }

    function setupTxs(
        Vm vm,
        uint256 privateKey,
        ERC1155MaxSupplyMintable nftContract,
        address adminAddress
    ) public returns (ERC1155AutoGraphMinter.MintBatchParams[] memory) {
        return setupTxs(vm, privateKey, nftContract, 0, adminAddress, 10, address(0), 0, block.timestamp);
    }

    function setupTxs(
        Vm vm,
        uint256 privateKey,
        ERC1155MaxSupplyMintable nft,
        uint256 offset,
        address adminAddress,
        uint256 testItems,
        address paymentToken,
        uint256 paymentAmount,
        uint256 expiryToken
    ) public returns (ERC1155AutoGraphMinter.MintBatchParams[] memory) {
        ERC1155AutoGraphMinter.MintBatchParams[] memory params = new ERC1155AutoGraphMinter.MintBatchParams[](
            testItems
        );

        for (uint256 i = 0; i < params.length; i++) {
            vm.prank(adminAddress);
            nft.setSupplyCap(i, type(uint256).max);

            SetupTxParams memory txx = SetupTxParams(
                vm,
                privateKey,
                address(nft),
                i + offset,
                i,
                testItems,
                paymentToken,
                paymentAmount,
                expiryToken
            );

            TxParts memory parts = setupTx(txx);
            params[i] = ERC1155AutoGraphMinter.MintBatchParams(
                parts.jobId,
                parts.tokenId,
                parts.units,
                parts.hash,
                parts.salt,
                parts.signature,
                parts.paymentAmount,
                expiryToken
            );
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
