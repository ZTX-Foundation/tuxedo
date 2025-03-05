// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;
/// @custom:via-ir

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Core} from "@protocol/core/Core.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {WhitelistedAddresses} from "@protocol/utils/extensions/WhitelistedAddresses.sol";
import {RateLimited} from "@protocol/utils/extensions/RateLimited.sol";

import {HashValidator} from "./HashValidator.sol";
import {BatchProcessor} from "./BatchProcessor.sol";
import {RateManager} from "./RateManager.sol";
import {WhitelistManager} from "./WhitelistManager.sol";
import {PaymentProcessor} from "./PaymentProcessor.sol";
import {MintProcessor} from "./MintProcessor.sol";

contract ERC1155AutoGraphMinter is CoreRef, RateLimited {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    /// --------- Events ---------- ///

    /// @notice - Event emitted when a contract is added to the whitelist
    event WhitelistedContractAdded(address indexed nftContract);
    /// @notice - Event emitted when a contract is removed from the whitelist
    event WhitelistedContractRemoved(address indexed nftContract);
    /// @notice - Event emitted when the mint is successful
    event ERC1155Minted(address indexed nftContract, address indexed recipient, uint256 indexed jobId, uint256 tokenId);

    /// @notice - Event emitted when the batch mint is successful
    event ERC1155BatchMinted(
        address indexed nftContract,
        address indexed recipient,
        uint256[] tokenIds,
        uint256[] units
    );
    /// @notice - Event emitted when the payment recipient is updated
    event PaymentRecipientUpdated(address indexed paymentRecipient);

    /// --------- Storage ---------- ///
    address public paymentRecipient;

    /// @notice hashes that have expired
    mapping(bytes32 hash => bool expired) public expiredHashes;

    /// @notice jobs that have completed
    mapping(uint256 jobId => bool completed) public completedJobs;
    
    /// @notice Whitelisted NFT contracts
    mapping(address => bool) public whitelistedContracts;

    /// @notice - expiryToken value for x amount hours
    uint8 public expiryTokenHoursValid; // 1 - 24 hours
    
    /// @notice Rate manager state
    RateManager.RateState private _rateState;

    /// --------- Structs ---------- ///

    /// @dev - MintWithEthAsFeeParams is a struct that contains the params for minting with ETH as a fee
    /// @param recipient - Address of the recipient
    /// @param jobId - ID of the job
    /// @param tokenId - ID of the NFT
    /// @param units - Amount of NFTs to mint
    /// @param hash - Hash of the message to be signed
    /// @param salt - Salt of the message to be signed
    /// @param signature - Signature of the message to be signed
    /// @param nftContract - Address of the NFT contract
    /// @param paymentAmount - Amount of ETH to be used for payment
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

    /// @dev - MintWithPaymentTokenAsFeeParams is a struct that contains the params for minting with a payment token as a fee
    /// @param recipient - Address of the recipient
    /// @param jobId - ID of the job
    /// @param tokenId - ID of the NFT
    /// @param units - Amount of NFTs to mint
    /// @param hash - Hash of the message to be signed
    /// @param salt - Salt of the message to be signed
    /// @param signature - Signature of the message to be signed
    /// @param nftContract - Address of the NFT contract
    /// @param paymentToken - Address of the payment token
    /// @param paymentAmount - Amount of the payment token to be used for payment
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

    /// @dev - HashInputsParams is a struct that contains the params for generating a hash
    /// @param recipient - Address of the recipient
    /// @param jobId - ID of the job
    /// @param tokenId - ID of the NFT
    /// @param units - Amount of NFTs to mint
    /// @param salt - Salt of the message to be signed
    /// @param nftContract - Address of the NFT contract
    /// @param paymentToken - Address of the payment token
    /// @param paymentAmount - Amount of the payment token to be used for payment
    /// @param expiryToken - Expiry token timestamp. ie create a timestamp.now on creation of the hash
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

    /// @notice - Check if a contract is whitelisted (new implementation)
    /// @param nftContract - Address of the contract to check
    function isWhitelistedContract(address nftContract) public view returns (bool) {
        return whitelistedContracts[nftContract];
    }
    
    /// @notice - Check if a contract is whitelisted (legacy method for backward compatibility)
    /// @param nftContract - Address of the contract to check 
    function isWhitelistedAddress(address nftContract) public view returns (bool) {
        return isWhitelistedContract(nftContract);
    }
    
    /// @notice Whitelist modifier to check if a contract is whitelisted
    modifier onlyWhitelist(address nftContract) {
        require(isWhitelistedContract(nftContract), "ERC1155AutoGraphMinter: Contract not whitelisted");
        _;
    }

    /// --------- Constructor ---------- ///

    constructor(
        address _core,
        address[] memory _whitelistedAddresses,
        uint128 _replenishRatePerSecond,
        uint128 _bufferCap,
        address _paymentRecipient,
        uint8 _expiryTokenHoursValid
    ) CoreRef(_core) RateLimited(_replenishRatePerSecond, _bufferCap) {
        require(
            _expiryTokenHoursValid > 0 && _expiryTokenHoursValid <= 24,
            "ERC1155AutoGraphMinter: Invalid expiry hours"
        );
        require(_paymentRecipient != address(0), "ERC1155AutoGraphMinter: Invalid payment recipient");

        paymentRecipient = _paymentRecipient;
        expiryTokenHoursValid = _expiryTokenHoursValid;
        
        // Initialize whitelist
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            require(_whitelistedAddresses[i] != address(0), "ERC1155AutoGraphMinter: Cannot whitelist zero address");
            whitelistedContracts[_whitelistedAddresses[i]] = true;
        }
        
        // Initialize rate state
        RateManager.initialize(_rateState, _bufferCap);
    }

    /// @notice - Mint tokens for free (backward compatibility function)
    /// @param recipient - Address of the recipient
    /// @param jobId - ID of the job
    /// @param tokenId - ID of the token
    /// @param units - Number of tokens to mint
    /// @param hash - Hash of the message
    /// @param salt - Salt used for the hash
    /// @param signature - Signature of the message
    /// @param nftContract - Address of the NFT contract
    /// @param expiryToken - Expiry token timestamp
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
        // Create the packed params struct to reduce stack usage
        MintProcessor.FreeMintParams memory freeParams = MintProcessor.FreeMintParams({
            recipient: recipient,
            jobId: jobId,
            tokenId: tokenId,
            units: units,
            hash: hash,
            salt: salt,
            signature: signature,
            nftContract: nftContract,
            expiryToken: expiryToken
        });
        
        // Process free mint
        uint128 bufferRemaining = MintProcessor.processFreeMintWithParams(
            core,
            expiryTokenHoursValid,
            expiredHashes,
            completedJobs,
            _rateState,
            replenishRatePerSecond,
            bufferCap,
            freeParams
        );

        emit BufferUsed(units, bufferRemaining);
        emit ERC1155Minted(nftContract, recipient, jobId, tokenId);
    }

    /// @notice - Mint tokens with ETH as a fee
    /// @param params - Mint parameters
    function mintWithEthAsFee(MintWithEthAsFeeParams memory params) external payable globalLock(1) whenNotPaused onlyWhitelist(params.nftContract) {
        // Validate payment
        require(params.paymentAmount > 0, "ERC1155AutoGraphMinter: paymentAmount must be greater than 0");
        require(msg.value == params.paymentAmount, "ERC1155AutoGraphMinter: Payment amount does not match msg.value");
        
        // Process payment
        PaymentProcessor.processEthPayment(params.paymentAmount, paymentRecipient);
        
        // Create the packed params struct to reduce stack usage
        MintProcessor.EthMintParams memory ethParams = MintProcessor.EthMintParams({
            recipient: params.recipient,
            jobId: params.jobId,
            tokenId: params.tokenId,
            units: params.units,
            hash: params.hash,
            salt: params.salt,
            signature: params.signature,
            nftContract: params.nftContract,
            paymentAmount: params.paymentAmount,
            expiryToken: params.expiryToken
        });
        
        // Process verification and minting
        uint128 bufferRemaining = MintProcessor.processEthMintWithParams(
            core,
            expiryTokenHoursValid,
            expiredHashes,
            completedJobs,
            _rateState,
            replenishRatePerSecond,
            bufferCap,
            ethParams
        );
        
        emit BufferUsed(params.units, bufferRemaining);
        emit ERC1155Minted(params.nftContract, params.recipient, params.jobId, params.tokenId);
    }

    /// @notice - Mint tokens with payment token as a fee
    /// @param params - Mint parameters
    function mintWithPaymentTokenAsFee(MintWithPaymentTokenAsFeeParams memory params) external globalLock(1) whenNotPaused onlyWhitelist(params.nftContract) {
        // Validate payment token
        require(params.paymentToken != address(0), "ERC1155AutoGraphMinter: Payment token cannot be zero address");
        require(params.paymentAmount > 0, "ERC1155AutoGraphMinter: Payment amount must be greater than 0");
        
        // Process payment
        PaymentProcessor.processTokenPayment(
            params.paymentToken,
            params.paymentAmount,
            msg.sender,
            paymentRecipient
        );
        
        // Process token mint
        uint128 bufferRemaining = MintProcessor.processTokenMint(
            core,
            expiryTokenHoursValid,
            expiredHashes,
            completedJobs,
            _rateState,
            replenishRatePerSecond,
            bufferCap,
            MintProcessor.TokenMintParams({
                recipient: params.recipient,
                jobId: params.jobId,
                tokenId: params.tokenId,
                units: params.units,
                hash: params.hash,
                salt: params.salt,
                signature: params.signature,
                nftContract: params.nftContract,
                paymentToken: params.paymentToken,
                paymentAmount: params.paymentAmount,
                expiryToken: params.expiryToken
            })
        );

        emit BufferUsed(params.units, bufferRemaining);
        emit ERC1155Minted(params.nftContract, params.recipient, params.jobId, params.tokenId);
    }

    /// @notice - Mint a batch of tokens for free
    /// @param nftContract - Address of the NFT contract
    /// @param recipient - Address of the recipient
    /// @param params - Array of batch parameters
    function mintBatchForFree(
        address nftContract,
        address recipient,
        BatchProcessor.MintBatchParams[] memory params
    ) external globalLock(1) whenNotPaused onlyWhitelist(nftContract) {
        // Process batch with combined function that handles verification and minting
        (BatchProcessor.BatchResults memory results, uint128 bufferRemaining) = BatchProcessor
            .processCompleteBatchForFree(
                core,
                expiryTokenHoursValid,
                expiredHashes,
                completedJobs,
                nftContract,
                recipient,
                _rateState,
                replenishRatePerSecond,
                bufferCap,
                params
            );

        emit BufferUsed(results.totalUnits, bufferRemaining);
        emit ERC1155BatchMinted(nftContract, recipient, results.tokenIds, results.units);
    }

    /// @notice - Mint a batch of tokens with ETH as a fee
    /// @param nftContract - Address of the NFT contract
    /// @param recipient - Address of the recipient
    /// @param params - Array of batch parameters
    function mintBatchWithEthAsFee(
        address nftContract,
        address recipient,
        BatchProcessor.MintBatchParams[] memory params
    ) external payable globalLock(1) whenNotPaused onlyWhitelist(nftContract) {
        // Use a modified batch processor function to reduce stack usage
        (BatchProcessor.BatchResults memory results, uint128 bufferRemaining) = 
            BatchProcessor.processCompleteBatchWithEth(
                core,
                expiryTokenHoursValid,
                expiredHashes,
                completedJobs,
                nftContract,
                recipient,
                _rateState,
                replenishRatePerSecond,
                bufferCap,
                params
            );

        // Process payment directly
        PaymentProcessor.processEthPayment(results.totalPayment, paymentRecipient);

        // Emit events
        emit BufferUsed(results.totalUnits, bufferRemaining);
        emit ERC1155BatchMinted(nftContract, recipient, results.tokenIds, results.units);
    }

    /// @notice - Mint a batch of tokens with payment token as a fee
    /// @param nftContract - Address of the NFT contract
    /// @param recipient - Address of the recipient
    /// @param paymentToken - Address of the payment token
    /// @param params - Array of batch parameters
    function mintBatchWithPaymentTokenAsFee(
        address nftContract,
        address recipient,
        address paymentToken,
        BatchProcessor.MintBatchParams[] memory params
    ) external globalLock(1) whenNotPaused onlyWhitelist(nftContract) {
        // Process verification and get results
        (uint256[] memory tokenIds, uint256[] memory amounts, uint256 totalUnits) = 
            verifyBatchWithToken(nftContract, recipient, paymentToken, params);
        
        // Apply rate limiting
        uint128 bufferRemaining = RateManager.deplete(
            _rateState, 
            totalUnits, 
            replenishRatePerSecond, 
            bufferCap
        );
        
        // Mint tokens
        ERC1155MaxSupplyMintable(nftContract).mintBatch(recipient, tokenIds, amounts);
        
        // Calculate and process total payment 
        uint256 totalPayment = calculateTotalPayment(params);
        if (totalPayment > 0) {
            PaymentProcessor.processTokenPayment(
                paymentToken,
                totalPayment,
                msg.sender,
                paymentRecipient
            );
        }
        
        // Emit events
        emit BufferUsed(totalUnits, bufferRemaining);
        emit ERC1155BatchMinted(nftContract, recipient, tokenIds, amounts);
    }

    // Breaking down verification to even smaller functions

    // Struct for verification inputs to reduce function parameters
    struct VerifyParams {
        Core core;
        address nftContract;
        address recipient;
        address paymentToken;
        BatchProcessor.MintBatchParams[] params;
    }

    // Helper function to do batch verification - simplified to reduce stack usage
    function verifyBatchWithToken(
        address _nftContract,
        address _recipient,
        address _paymentToken,
        BatchProcessor.MintBatchParams[] memory _params
    ) private returns (uint256[] memory tokenIds, uint256[] memory amounts, uint256 totalUnits) {
        require(_params.length > 0, "ERC1155AutoGraphMinter: Empty batch");
        
        tokenIds = new uint256[](_params.length);
        amounts = new uint256[](_params.length);
        totalUnits = 0;
        
        for (uint256 i = 0; i < _params.length; i++) {
            // Process each parameter with minimal stack usage
            BatchProcessor.MintBatchParams memory param = _params[i];
            
            // Check expiry state first (minimal stack usage)
            require(!expiredHashes[param.hash], "ERC1155AutoGraphMinter: Hash expired");
            require(!completedJobs[param.jobId], "ERC1155AutoGraphMinter: Job already completed");
            
            // Verify expiry token
            validateExpiryToken(param.expiryToken);
            
            // Verify hash one at a time with minimal params
            verifyIndividualHash(
                _recipient,
                _nftContract,
                _paymentToken,
                param
            );
            
            // Mark as processed - do this early to free up stack
            expiredHashes[param.hash] = true;
            completedJobs[param.jobId] = true;
            
            // Add to arrays
            tokenIds[i] = param.tokenId;
            amounts[i] = param.units;
            totalUnits += param.units;
        }
        
        return (tokenIds, amounts, totalUnits);
    }

    // Helper function to validate expiry token
    function validateExpiryToken(uint256 expiryToken) private view {
        require(
            HashValidator.isExpiryValid(expiryToken, expiryTokenHoursValid, block.timestamp),
            "ERC1155AutoGraphMinter: Expiry token is expired"
        );
    }

    // Helper function to verify a single hash
    function verifyIndividualHash(
        address recipient,
        address nftContract, 
        address paymentToken,
        BatchProcessor.MintBatchParams memory param
    ) private view {
        // Generate expected hash
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
        
        // Verify hash matches
        require(expectedHash == param.hash, "ERC1155AutoGraphMinter: Hash mismatch");
        
        // Verify signature 
        address signer = HashValidator.recoverSigner(param.hash, param.signature);
        require(HashValidator.verifySigner(core, signer), "ERC1155AutoGraphMinter: Missing MINTER_NOTARY Role");
    }

    // Helper function to calculate total payment
    function calculateTotalPayment(BatchProcessor.MintBatchParams[] memory params) private pure returns (uint256) {
        uint256 totalPayment = 0;
        for (uint256 i = 0; i < params.length; i++) {
            totalPayment += params[i].paymentAmount;
        }
        return totalPayment;
    }

    /// @notice - Add a contract to the whitelist
    /// @param nftContract - Address of the NFT contract to add
    function addWhitelistedContract(
        address nftContract
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        WhitelistManager.addWhitelisted(whitelistedContracts, nftContract);
        emit WhitelistedContractAdded(nftContract);
    }

    /// @notice - Add multiple contracts to the whitelist (legacy method for backward compatibility)
    /// @param nftContracts - Array of NFT contract addresses to add
    function addWhitelistedContracts(
        address[] memory nftContracts
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        for (uint256 i = 0; i < nftContracts.length; i++) {
            WhitelistManager.addWhitelisted(whitelistedContracts, nftContracts[i]);
            emit WhitelistedContractAdded(nftContracts[i]);
        }
    }

    /// @notice - Remove a contract from the whitelist
    /// @param nftContract - Address of the NFT contract to remove
    function removeWhitelistedContract(
        address nftContract
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        WhitelistManager.removeWhitelisted(whitelistedContracts, nftContract);
        emit WhitelistedContractRemoved(nftContract);
    }

    /// @notice - Remove multiple contracts from the whitelist (legacy method for backward compatibility)
    /// @param nftContracts - Array of NFT contract addresses to remove
    function removeWhitelistedContracts(
        address[] memory nftContracts
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        for (uint256 i = 0; i < nftContracts.length; i++) {
            WhitelistManager.removeWhitelisted(whitelistedContracts, nftContracts[i]);
            emit WhitelistedContractRemoved(nftContracts[i]);
        }
    }

    /// @notice - Set the payment recipient
    /// @param _paymentRecipient - Address of the new payment recipient
    function setPaymentRecipient(
        address _paymentRecipient
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        require(_paymentRecipient != address(0), "ERC1155AutoGraphMinter: Invalid payment recipient");
        paymentRecipient = _paymentRecipient;
        emit PaymentRecipientUpdated(_paymentRecipient);
    }

    /// @notice - Legacy function for backward compatibility
    /// @param _paymentRecipient - Address of the new payment recipient
    function updatePaymentRecipient(
        address _paymentRecipient
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        require(_paymentRecipient != address(0), "ERC1155AutoGraphMinter: Invalid payment recipient");
        paymentRecipient = _paymentRecipient;
        emit PaymentRecipientUpdated(_paymentRecipient);
    }

    /// @notice - Set the expiry token hours valid
    /// @param _expiryTokenHoursValid - New expiry token hours valid value
    function setExpiryTokenHoursValid(
        uint8 _expiryTokenHoursValid
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        require(
            _expiryTokenHoursValid > 0 && _expiryTokenHoursValid <= 24,
            "ERC1155AutoGraphMinter: Invalid expiry hours"
        );
        expiryTokenHoursValid = _expiryTokenHoursValid;
    }

    /// @notice - Legacy function for backward compatibility
    /// @param _expiryTokenHoursValid - New expiry token hours valid value
    function updateExpiryTokenHoursValid(
        uint8 _expiryTokenHoursValid
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        require(
            _expiryTokenHoursValid > 0 && _expiryTokenHoursValid <= 24,
            "ERC1155AutoGraphMinter: Invalid expiry hours"
        );
        expiryTokenHoursValid = _expiryTokenHoursValid;
    }

    /// @notice - Recover the signer of a hash
    /// @param hash - Hash of the message
    /// @param signature - Signature of the message
    /// @return signer - Address of the signer
    function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address signer) {
        return HashValidator.recoverSigner(hash, signature);
    }
}
