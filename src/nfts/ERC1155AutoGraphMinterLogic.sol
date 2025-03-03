// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {Roles} from "@protocol/core/Roles.sol";

/**
 * @title ERC1155AutoGraphMinterLogic
 * @notice Core minting logic pulled into a library
 */
library ERC1155AutoGraphMinterLogic {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;
    
    // Structs moved from previous implementation
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
    
    struct VerifyInputParams {
        bytes32 inputHash;
        uint256 jobId;
        bytes32 generatedHash;
        bytes signature;
        uint256 units;
        address nftContract;
        uint256 expiryToken;
    }
    
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
    
    // Storage struct to avoid stack too deep errors
    struct MinterStorage {
        address paymentRecipient;
        mapping(bytes32 => bool) expiredHashes;
        mapping(uint256 => bool) completedJobs;
        uint8 expiryTokenHoursValid;
        address core;
        mapping(address => bool) whitelistedAddresses;
        bool paused;
        uint128 bufferRemaining;
        uint128 replenishRatePerSecond;
        uint128 bufferCap;
        uint32 lastReplenishTimestamp;
    }

    // Events
    event WhitelistedContractAdded(address indexed nftContract);
    event WhitelistedContractRemoved(address indexed nftContract);
    event ERC1155Minted(address indexed nftContract, address indexed recipient, uint256 indexed jobId, uint256 tokenId);
    event ERC1155BatchMinted(
        address indexed nftContract, 
        address indexed recipient, 
        uint256[] tokenIds, 
        uint256[] units
    );
    event PaymentRecipientUpdated(address indexed paymentRecipient);
    event BufferUsed(uint256 amountUsed, uint128 bufferRemaining);
    
    // Core functions
    
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

    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        return hash.recover(signature);
    }

    function isExpiryTokenValid(uint256 expiryToken, uint8 expiryHours) internal view returns (bool) {
        require(expiryToken <= block.timestamp, "ERC1155AutoGraphMinter: Expiry token must be in the past");
        uint256 hoursInSeconds = uint256(expiryHours) * 1 hours;
        uint256 diff = block.timestamp - expiryToken;
        return diff < hoursInSeconds;
    }

    function validatePaymentTokenFee(address paymentToken, uint256 paymentAmount) internal pure {
        require(paymentToken != address(0), "ERC1155AutoGraphMinter: paymentToken must not be address(0)");
        require(paymentAmount > 0, "ERC1155AutoGraphMinter: paymentAmount must be greater than 0");
    }

    function validateEthFee(uint256 paymentAmount) internal view {
        require(paymentAmount > 0, "ERC1155AutoGraphMinter: paymentAmount must be greater than 0");
        require(msg.value == paymentAmount, "ERC1155AutoGraphMinter: msg.value must match paymentAmount");
    }

    function isValidRange(uint8 input, uint8 minRange, uint8 maxRange) internal pure returns (bool) {
        return input >= minRange && input <= maxRange;
    }
} 