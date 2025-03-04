// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Core} from "@protocol/core/Core.sol";
import {GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {HashVerifier} from "./HashVerifier.sol";
import {RateLimiter} from "./RateLimiter.sol";
import {BatchMinting} from "./BatchMinting.sol";

/**
 * @title ERC1155AutoGraphMinterImpl
 * @notice Slimmed down implementation that delegates most logic to libraries
 */
contract ERC1155AutoGraphMinterImpl {
    using SafeERC20 for IERC20;
    using HashVerifier for HashVerifier.HashInputsParams;
    using RateLimiter for RateLimiter.RateLimitState;

    // Core references
    Core public core;
    GlobalReentrancyLock public globalReentrancyLock;

    // State variables
    bool public paused;
    mapping(address => bool) public whitelistedAddresses;
    address public paymentRecipient;
    mapping(bytes32 => bool) public expiredHashes;
    mapping(uint256 => bool) public completedJobs;
    uint8 public expiryTokenHoursValid;

    /// @dev Rate limiting (now using structured storage)
    RateLimiter.RateLimitState private _rateLimit;

    /// @notice Emitted when a new NFT contract is added to whitelist
    event WhitelistedContractAdded(address indexed nftContract);
    /// @notice Emitted when an NFT contract is removed from whitelist
    event WhitelistedContractRemoved(address indexed nftContract);
    /// @notice Emitted when a new ERC1155 token is minted
    event ERC1155Minted(address indexed nftContract, address indexed recipient, uint256 indexed jobId, uint256 tokenId);
    /// @notice Emitted when a batch of ERC1155 tokens is minted
    event ERC1155BatchMinted(
        address indexed nftContract,
        address indexed recipient,
        uint256[] tokenIds,
        uint256[] units
    );
    /// @notice Emitted when payment recipient is updated
    event PaymentRecipientUpdated(address indexed paymentRecipient);
    /// @notice Emitted when rate limit buffer is used
    event BufferUsed(uint256 amountUsed, uint128 bufferRemaining);
    /// @notice Emitted when contract is paused
    event Paused(address account);
    /// @notice Emitted when contract is unpaused
    event Unpaused(address account);

    /// @notice Constructor for the implementation
    /// @param _core Address of the Core contract
    /// @param _globalReentrancyLock Address of the global reentrancy lock
    constructor(address _core, address _globalReentrancyLock) {
        core = Core(_core);
        globalReentrancyLock = GlobalReentrancyLock(_globalReentrancyLock);
    }

    /// @notice Initializes the contract with required parameters
    /// @param _core Address of the Core contract
    /// @param _globalReentrancyLock Address of the global reentrancy lock
    /// @param _nftContracts Array of NFT contract addresses to whitelist
    /// @param _replenishRatePerSecond Rate at which buffer replenishes per second
    /// @param _bufferCap Maximum size of the rate limit buffer
    /// @param _paymentRecipient Address that receives payment for minting
    /// @param _expiryTokenHoursValid Number of hours a token expiry is valid
    function initialize(
        address _core,
        address _globalReentrancyLock,
        address[] memory _nftContracts,
        uint128 _replenishRatePerSecond,
        uint128 _bufferCap,
        address _paymentRecipient,
        uint8 _expiryTokenHoursValid
    ) external {
        // Basic validation
        require(_core != address(0), "Core cannot be 0");
        require(_globalReentrancyLock != address(0), "Global lock cannot be 0");
        require(_paymentRecipient != address(0), "Payment recipient cannot be 0");
        require(HashVerifier.isValidRange(_expiryTokenHoursValid, 1, 24), "Hours must be between 1 and 24");

        // Initialize core references
        core = Core(_core);
        globalReentrancyLock = GlobalReentrancyLock(_globalReentrancyLock);

        // Initialize whitelist
        for (uint i = 0; i < _nftContracts.length; i++) {
            whitelistedAddresses[_nftContracts[i]] = true;
        }

        // Initialize rate limiting
        RateLimiter.initializeRateLimit(_rateLimit, _replenishRatePerSecond, _bufferCap, uint32(block.timestamp));

        // Set state
        paymentRecipient = _paymentRecipient;
        expiryTokenHoursValid = _expiryTokenHoursValid;
    }

    /// @dev Ensures the contract is not paused
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    /// @dev Ensures the NFT contract is whitelisted
    modifier onlyWhitelist(address nftContract) {
        require(whitelistedAddresses[nftContract], "NFT contract not whitelisted");
        _;
    }

    /// @dev Ensures caller has the specified role
    modifier hasRole(bytes32 role) {
        require(core.hasRole(role, msg.sender), "Access control: sender does not have role");
        _;
    }

    /// @dev Ensures caller has at least one of two roles
    modifier hasAnyOfTwoRoles(bytes32 role1, bytes32 role2) {
        require(
            core.hasRole(role1, msg.sender) || core.hasRole(role2, msg.sender),
            "Access control: sender does not have either role"
        );
        _;
    }

    /// @dev Applies the global reentrancy lock
    modifier globalLock(uint8 lockId) {
        globalReentrancyLock.lock(lockId);
        _;
        globalReentrancyLock.unlock(lockId);
    }

    /// @dev Depletes the rate limiting buffer
    /// @param amount Amount to deplete from buffer
    /// @return Remaining buffer after depletion
    function _depleteBuffer(uint256 amount) internal returns (uint128) {
        uint128 bufferRemaining = RateLimiter.depleteBuffer(_rateLimit, amount, block.timestamp);
        emit BufferUsed(amount, bufferRemaining);
        return bufferRemaining;
    }

    /// @notice Pauses the contract
    function pause() external hasRole(Roles.GUARDIAN) {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses the contract
    function unpause() external hasRole(Roles.GUARDIAN) {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Mints a batch of tokens for free
    /// @param nftContract Address of the NFT contract
    /// @param recipient Address that will receive the tokens
    /// @param params Array of mint parameters
    function mintBatchForFree(
        address nftContract,
        address recipient,
        BatchMinting.MintBatchParams[] memory params
    ) external globalLock(1) whenNotPaused onlyWhitelist(nftContract) {
        // Create context in memory instead of storage
        BatchMinting.BatchContext memory batchContext = BatchMinting.BatchContext({
            core: core,
            expiryTokenHoursValid: expiryTokenHoursValid
        });

        // Process batch using library
        BatchMinting.BatchProcessingResult memory result = BatchMinting.processBatch(
            batchContext,
            expiredHashes,
            completedJobs,
            nftContract,
            recipient,
            address(0),
            params,
            _depleteBuffer
        );

        // Mint tokens
        ERC1155MaxSupplyMintable(nftContract).mintBatch(recipient, result.tokenIds, result.units);
        emit ERC1155BatchMinted(nftContract, recipient, result.tokenIds, result.units);
    }

    // Add other batch functions (similar pattern)

    /// @notice Checks if an address is whitelisted
    /// @param nftContract Address to check
    /// @return True if address is whitelisted
    function isWhitelistedAddress(address nftContract) external view returns (bool) {
        return whitelistedAddresses[nftContract];
    }

    /// @notice Gets current buffer amount
    /// @return Current buffer size
    function buffer() external view returns (uint256) {
        return _rateLimit.bufferRemaining;
    }

    /// @notice Gets replenish rate per second
    /// @return Current replenish rate
    function replenishRatePerSecond() external view returns (uint128) {
        return _rateLimit.replenishRatePerSecond;
    }

    /// @notice Gets buffer capacity
    /// @return Maximum buffer size
    function bufferCap() external view returns (uint128) {
        return _rateLimit.bufferCap;
    }

    /// @notice Updates the payment recipient address
    /// @param _paymentRecipient New payment recipient address
    function updatePaymentRecipient(address _paymentRecipient) external hasRole(Roles.ADMIN) {
        require(_paymentRecipient != address(0), "Payment recipient cannot be address(0)");
        paymentRecipient = _paymentRecipient;
        emit PaymentRecipientUpdated(_paymentRecipient);
    }

    /// @notice Updates the expiry token hours valid
    /// @param _expiryTokenHoursValid New hours valid value
    function updateExpiryTokenHoursValid(uint8 _expiryTokenHoursValid) external hasRole(Roles.ADMIN) {
        require(HashVerifier.isValidRange(_expiryTokenHoursValid, 1, 24), "Hours must be between 1 and 24");
        expiryTokenHoursValid = _expiryTokenHoursValid;
    }
}
