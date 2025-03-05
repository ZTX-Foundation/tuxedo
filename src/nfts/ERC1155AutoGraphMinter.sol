// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {Core} from "@protocol/core/Core.sol";

import {HashValidator} from "./HashValidator.sol";
import {BatchProcessor} from "./BatchProcessor.sol";
import {RateManager} from "./RateManager.sol";
import {WhitelistManager} from "./WhitelistManager.sol";
import {PaymentProcessor} from "./PaymentProcessor.sol";
import {MintProcessor} from "./MintProcessor.sol";

/// @title ERC1155AutoGraphMinter
/// @notice Handles minting of ERC1155 tokens with various payment options
contract ERC1155AutoGraphMinter is CoreRef {
    using SafeERC20 for IERC20;

    /// @notice State variables
    mapping(address => bool) public whitelistedAddresses;
    address public paymentRecipient;
    mapping(bytes32 => bool) public expiredHashes;
    mapping(uint256 => bool) public completedJobs;
    uint8 public expiryTokenHoursValid;
    
    /// @notice Custom paused state
    bool private _minterPaused;
    
    /// @notice Rate limiting state
    RateManager.RateState private _rateState;

    /// @notice Events
    event WhitelistedContractAdded(address indexed nftContract);
    event WhitelistedContractRemoved(address indexed nftContract);
    event ERC1155Minted(address indexed nftContract, address indexed recipient, uint256 indexed jobId, uint256 tokenId);
    event ERC1155BatchMinted(address indexed nftContract, address indexed recipient, uint256[] tokenIds, uint256[] units);
    event PaymentRecipientUpdated(address indexed paymentRecipient);
    event BufferUsed(uint256 amountUsed, uint128 bufferRemaining);

    /// @notice Structs for function parameters
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

    // Helper struct to reduce stack depth
    struct MintParams {
        address recipient;
        uint256 jobId;
        uint256 tokenId;
        uint256 units;
        bytes32 hash;
        uint256 salt;
        address nftContract;
        address paymentToken;
        uint256 paymentAmount;
        uint256 expiryToken;
    }

    /// @notice Modifiers
    modifier onlyWhitelist(address nftContract) {
        require(whitelistedAddresses[nftContract], "NFT contract not whitelisted");
        _;
    }

    /// @notice Contract constructor
    /// @param _core Core contract address
    /// @param _whitelistedAddresses Initial whitelisted addresses
    /// @param _replenishRatePerSecond Rate at which buffer replenishes
    /// @param _bufferCap Maximum buffer size
    /// @param _paymentRecipient Address to receive payments
    /// @param _expiryTokenHoursValid Hours that expiry tokens are valid
    constructor(
        address _core,
        address[] memory _whitelistedAddresses,
        uint128 _replenishRatePerSecond,
        uint128 _bufferCap,
        address _paymentRecipient,
        uint8 _expiryTokenHoursValid
    ) CoreRef(_core) {
        require(_paymentRecipient != address(0), "Payment recipient cannot be zero address");
        require(HashValidator.isValidRange(_expiryTokenHoursValid, 1, 24), "Hours must be between 1 and 24");
        
        // Initialize state variables
        paymentRecipient = _paymentRecipient;
        expiryTokenHoursValid = _expiryTokenHoursValid;
        
        // Initialize rate limiting
        RateManager.initializeRate(_rateState, _replenishRatePerSecond, _bufferCap);
        
        // Initialize whitelist
        WhitelistManager.addAddresses(whitelistedAddresses, _whitelistedAddresses);
    }

    /// @notice Mint tokens for free
    /// @param recipient Address to receive tokens
    /// @param jobId Job identifier
    /// @param tokenId Token ID to mint
    /// @param units Number of tokens to mint
    /// @param hash Verification hash
    /// @param salt Random value for hash uniqueness
    /// @param signature Signature to verify
    /// @param nftContract NFT contract address
    /// @param expiryToken Expiration timestamp
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
        // Create packed params struct
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
        
        // Process the mint operation
        uint128 bufferRemaining = MintProcessor.processFreeMintWithParams(
            core,
            expiryTokenHoursValid,
            expiredHashes,
            completedJobs,
            _rateState,
            freeParams
        );
        
        emit BufferUsed(units, bufferRemaining);
        emit ERC1155Minted(nftContract, recipient, jobId, tokenId);
    }

    /// @notice Mint a batch of tokens for free
    /// @param nftContract NFT contract address
    /// @param recipient Address to receive tokens
    /// @param params Batch parameters
    function mintBatchForFree(
        address nftContract,
        address recipient,
        BatchProcessor.MintBatchParams[] memory params
    ) external globalLock(1) whenNotPaused onlyWhitelist(nftContract) {
        // Process batch with combined function that handles verification and minting
        (BatchProcessor.BatchResults memory results, uint128 bufferRemaining) = 
            BatchProcessor.processCompleteBatchForFree(
                core,
                expiryTokenHoursValid,
                expiredHashes,
                completedJobs,
                nftContract,
                recipient,
                _rateState,
                params
            );
        
        emit BufferUsed(results.totalUnits, bufferRemaining);
        emit ERC1155BatchMinted(nftContract, recipient, results.tokenIds, results.units);
    }

    /// @notice Mint a token with ETH payment
    /// @param params Mint parameters
    function mintWithEthAsFee(
        MintWithEthAsFeeParams memory params
    ) external payable globalLock(1) whenNotPaused onlyWhitelist(params.nftContract) {
        // Process ETH payment 
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
        
        // Process verification and minting but not payment
        uint128 bufferRemaining = MintProcessor.processEthMintWithParams(
            core,
            expiryTokenHoursValid,
            expiredHashes,
            completedJobs,
            _rateState,
            ethParams
        );
        
        emit BufferUsed(params.units, bufferRemaining);
        emit ERC1155Minted(params.nftContract, params.recipient, params.jobId, params.tokenId);
    }

    /// @notice Mint a batch of tokens with ETH payment
    /// @param nftContract NFT contract address
    /// @param recipient Address to receive tokens
    /// @param params Batch parameters
    function mintBatchWithEthAsFee(
        address nftContract,
        address recipient,
        BatchProcessor.MintBatchParams[] memory params
    ) external payable globalLock(1) whenNotPaused onlyWhitelist(nftContract) {
        // Process batch with combined function that handles verification and minting
        (BatchProcessor.BatchResults memory results, uint128 bufferRemaining) = 
            BatchProcessor.processCompleteBatchWithEth(
                core,
                expiryTokenHoursValid,
                expiredHashes,
                completedJobs,
                nftContract,
                recipient,
                _rateState,
                params
            );
        
        // Process payment separately (since it needs msg.value)
        PaymentProcessor.processEthPayment(results.totalPayment, paymentRecipient);
        
        emit BufferUsed(results.totalUnits, bufferRemaining);
        emit ERC1155BatchMinted(nftContract, recipient, results.tokenIds, results.units);
    }

    /// @notice Mint a batch of tokens with ERC20 token payment
    /// @param nftContract NFT contract address
    /// @param recipient Address to receive tokens
    /// @param paymentToken Payment token address
    /// @param params Batch parameters
    function mintBatchWithPaymentTokenAsFee(
        address nftContract,
        address recipient,
        address paymentToken,
        BatchProcessor.MintBatchParams[] memory params
    ) external globalLock(1) whenNotPaused onlyWhitelist(nftContract) {
        // Process batch with combined function that handles verification and minting
        (BatchProcessor.BatchResults memory results, uint128 bufferRemaining) = 
            BatchProcessor.processCompleteBatchWithToken(
                core,
                expiryTokenHoursValid,
                expiredHashes,
                completedJobs,
                nftContract,
                recipient,
                paymentToken,
                _rateState,
                params
            );
        
        // Process payment separately
        PaymentProcessor.processTokenPayment(
            paymentToken,
            results.totalPayment,
            msg.sender,
            paymentRecipient
        );
        
        emit BufferUsed(results.totalUnits, bufferRemaining);
        emit ERC1155BatchMinted(nftContract, recipient, results.tokenIds, results.units);
    }

    /// @notice Mint a token with ERC20 token payment
    /// @param params Mint parameters
    function mintWithPaymentTokenAsFee(
        MintWithPaymentTokenAsFeeParams memory params
    ) external globalLock(1) whenNotPaused onlyWhitelist(params.nftContract) {
        // Use the combined processor function
        uint128 bufferRemaining = MintProcessor.processTokenMintWithPayment(
            core,
            expiryTokenHoursValid,
            expiredHashes,
            completedJobs,
            _rateState,
            msg.sender,
            paymentRecipient,
            params.recipient,
            params.jobId,
            params.tokenId,
            params.units,
            params.hash,
            params.salt,
            params.signature,
            params.nftContract,
            params.paymentToken,
            params.paymentAmount,
            params.expiryToken
        );
        
        emit BufferUsed(params.units, bufferRemaining);
        emit ERC1155Minted(params.nftContract, params.recipient, params.jobId, params.tokenId);
    }

    /// @notice Add a contract to whitelist
    /// @param nftContractAddress NFT contract to whitelist
    function addWhitelistedContract(
        address nftContractAddress
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        WhitelistManager.addAddress(whitelistedAddresses, nftContractAddress);
        emit WhitelistedContractAdded(nftContractAddress);
    }

    /// @notice Remove a contract from whitelist
    /// @param nftContractAddress NFT contract to remove
    function removeWhitelistedContract(
        address nftContractAddress
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        WhitelistManager.removeAddress(whitelistedAddresses, nftContractAddress);
        emit WhitelistedContractRemoved(nftContractAddress);
    }

    /// @notice Add multiple contracts to whitelist
    /// @param whitelistAddresses NFT contracts to whitelist
    function addWhitelistedContracts(
        address[] calldata whitelistAddresses
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        WhitelistManager.addAddresses(whitelistedAddresses, whitelistAddresses);
    }

    /// @notice Remove multiple contracts from whitelist
    /// @param whitelistAddresses NFT contracts to remove
    function removeWhitelistedContracts(
        address[] calldata whitelistAddresses
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        WhitelistManager.removeAddresses(whitelistedAddresses, whitelistAddresses);
    }

    /// @notice Update payment recipient
    /// @param _paymentRecipient New payment recipient
    function updatePaymentRecipient(address _paymentRecipient) external hasRole(Roles.ADMIN) {
        require(_paymentRecipient != address(0), "Payment recipient cannot be zero address");
        paymentRecipient = _paymentRecipient;
        emit PaymentRecipientUpdated(_paymentRecipient);
    }

    /// @notice Update expiry token hours valid
    /// @param _expiryTokenHoursValid New hours value (1-24)
    function updateExpiryTokenHoursValid(uint8 _expiryTokenHoursValid) external hasRole(Roles.ADMIN) {
        require(HashValidator.isValidRange(_expiryTokenHoursValid, 1, 24), "Hours must be between 1 and 24");
        expiryTokenHoursValid = _expiryTokenHoursValid;
    }


    /// @notice Check if address is whitelisted
    /// @param nftContract Address to check
    /// @return True if whitelisted
    function isWhitelistedAddress(address nftContract) external view returns (bool) {
        return whitelistedAddresses[nftContract];
    }

    /// @notice Get current buffer amount
    /// @return Current buffer size
    function buffer() external view returns (uint256) {
        return _rateState.bufferRemaining;
    }

    /// @notice Get replenish rate per second
    /// @return Current replenish rate
    function replenishRatePerSecond() external view returns (uint128) {
        return _rateState.replenishRatePerSecond;
    }

    /// @notice Get buffer capacity
    /// @return Maximum buffer size
    function bufferCap() external view returns (uint128) {
        return _rateState.bufferCap;
    }

    /// @notice Recover signer from hash and signature
    /// @param hash The hash that was signed
    /// @param signature The signature
    /// @return The address that signed the hash
    function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address) {
        return HashValidator.recoverSigner(hash, signature);
    }
}
