// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {ERC1155AutoGraphMinterLogic} from "./ERC1155AutoGraphMinterLogic.sol";
import {GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";

/**
 * @title ERC1155AutoGraphMinterImpl
 * @notice Implementation contract completely flattened to avoid inheritance issues
 */
contract ERC1155AutoGraphMinterImpl {
    using SafeERC20 for IERC20;
    
    // Core reference
    Core public core;
    
    // Pausable state
    bool public paused;
    
    // Whitelist mapping
    mapping(address => bool) public whitelistedAddresses;
    
    // Rate limiting state variables
    uint128 public replenishRatePerSecond;
    uint128 public bufferCap;
    uint128 public bufferRemaining;
    uint32 public lastReplenishTimestamp;
    
    // Storage state - minimized
    address public paymentRecipient;
    mapping(bytes32 => bool) public expiredHashes;
    mapping(uint256 => bool) public completedJobs;
    uint8 public expiryTokenHoursValid;
    
    // Events
    event ERC1155Minted(address indexed nftContract, address indexed recipient, uint256 indexed jobId, uint256 tokenId);
    event ERC1155BatchMinted(address indexed nftContract, address indexed recipient, uint256[] tokenIds, uint256[] units);
    event WhitelistedContractAdded(address indexed nftContract);
    event WhitelistedContractRemoved(address indexed nftContract);
    event PaymentRecipientUpdated(address indexed paymentRecipient);
    event BufferUsed(uint256 amountUsed, uint128 bufferRemaining);
    event Paused(address account);
    event Unpaused(address account);
    
    // Constructor now directly sets the core
    constructor(address _core) {
        require(_core != address(0), "ERC1155AutoGraphMinter: core cannot be 0");
        core = Core(_core);
    }
    
    // Custom modifiers implemented directly
    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }
    
    modifier onlyWhitelist(address _addr) {
        require(whitelistedAddresses[_addr], "WhitelistedAddresses: Address not whitelisted");
        _;
    }
    
    modifier hasRole(bytes32 role) {
        require(core.hasRole(role, msg.sender), "CoreRef: no role on core");
        _;
    }
    
    modifier hasAnyOfTwoRoles(bytes32 roleA, bytes32 roleB) {
        require(
            core.hasRole(roleA, msg.sender) || core.hasRole(roleB, msg.sender),
            "CoreRef: no role on core"
        );
        _;
    }
    
    modifier globalLock(uint8 level) {
        // Get the lock from core as address first
        address lockAddress = address(core.lock());
        // Then cast to the concrete implementation
        GlobalReentrancyLock lock = GlobalReentrancyLock(lockAddress);
        lock.lock(level);
        _;
        lock.unlock(level);
    }
    
    // Pausable functions
    function pause() external hasRole(Roles.ADMIN) {
        paused = true;
        emit Paused(msg.sender);
    }
    
    function unpause() external hasRole(Roles.ADMIN) {
        paused = false;
        emit Unpaused(msg.sender);
    }
    
    // Initialize function
    function initialize(
        address _core,
        address[] memory _nftContracts,
        uint128 _replenishRatePerSecond,
        uint128 _bufferCap,
        address _paymentRecipient,
        uint8 _expiryTokenHoursValid
    ) external {
        require(_core != address(0), "ERC1155AutoGraphMinter: core cannot be 0");
        require(_paymentRecipient != address(0), "ERC1155AutoGraphMinter: paymentRecipient must not be address(0)");
        require(ERC1155AutoGraphMinterLogic.isValidRange(_expiryTokenHoursValid, 1, 24), 
                "ERC1155AutoGraphMinter: Hours must be between 1 and 24");
                
        // Initialize core directly
        core = Core(_core);
        
        // Initialize whitelist
        for (uint256 i = 0; i < _nftContracts.length; i++) {
            whitelistedAddresses[_nftContracts[i]] = true;
        }
        
        // Initialize rate limiting
        replenishRatePerSecond = _replenishRatePerSecond;
        bufferCap = _bufferCap;
        bufferRemaining = _bufferCap;
        lastReplenishTimestamp = uint32(block.timestamp);
        
        // Set state
        paymentRecipient = _paymentRecipient;
        expiryTokenHoursValid = _expiryTokenHoursValid;
    }
    
    // First, let's create a struct to group the parameters
    struct MintParams {
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
    
    // Then refactor the mintForFree function to use it
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
        MintParams memory params = MintParams(
            recipient, jobId, tokenId, units, hash, salt, signature, nftContract, expiryToken
        );
        _processMintForFree(params);
    }

    // Move the actual implementation to a separate function
    function _processMintForFree(MintParams memory params) internal {
        ERC1155AutoGraphMinterLogic.HashInputsParams memory input = ERC1155AutoGraphMinterLogic.HashInputsParams(
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

        ERC1155AutoGraphMinterLogic.VerifyInputParams memory verifyParams = ERC1155AutoGraphMinterLogic.VerifyInputParams(
            params.hash,
            params.jobId,
            ERC1155AutoGraphMinterLogic.getHash(input),
            params.signature,
            params.units,
            params.nftContract,
            params.expiryToken
        );

        _verifyHashAndSignerRoleExpireHashAndDepleteBuffer(verifyParams);

        ERC1155MaxSupplyMintable(params.nftContract).mint(params.recipient, params.tokenId, params.units);
        emit ERC1155Minted(params.nftContract, params.recipient, params.jobId, params.tokenId);
    }

    function mintWithPaymentTokenAsFee(
        ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams memory params
    ) external globalLock(1) whenNotPaused onlyWhitelist(params.nftContract) {
        // First create a HashInputsParams from the payment params
        ERC1155AutoGraphMinterLogic.HashInputsParams memory input = ERC1155AutoGraphMinterLogic.HashInputsParams(
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

        // Then create a VerifyInputParams using the hash generated from the input
        ERC1155AutoGraphMinterLogic.VerifyInputParams memory verifyParams = ERC1155AutoGraphMinterLogic.VerifyInputParams(
            params.hash,
            params.jobId,
            ERC1155AutoGraphMinterLogic.getHash(input),
            params.signature,
            params.units,
            params.nftContract,
            params.expiryToken
        );

        ERC1155AutoGraphMinterLogic.validatePaymentTokenFee(params.paymentToken, params.paymentAmount);
        _verifyHashAndSignerRoleExpireHashAndDepleteBuffer(verifyParams);

        IERC20(params.paymentToken).safeTransferFrom(msg.sender, paymentRecipient, params.paymentAmount);
        ERC1155MaxSupplyMintable(params.nftContract).mint(params.recipient, params.tokenId, params.units);
        emit ERC1155Minted(params.nftContract, params.recipient, params.jobId, params.tokenId);
    }

    function mintWithEthAsFee(
        ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams memory params
    ) external payable globalLock(1) whenNotPaused onlyWhitelist(params.nftContract) {
        // First create a HashInputsParams from the payment params
        ERC1155AutoGraphMinterLogic.HashInputsParams memory input = ERC1155AutoGraphMinterLogic.HashInputsParams(
            params.recipient,
            params.jobId,
            params.tokenId,
            params.units,
            params.salt,
            params.nftContract,
            address(0), // No token for ETH payments
            params.paymentAmount,
            params.expiryToken
        );

        // Then create a VerifyInputParams using the hash generated from the input
        ERC1155AutoGraphMinterLogic.VerifyInputParams memory verifyParams = ERC1155AutoGraphMinterLogic.VerifyInputParams(
            params.hash,
            params.jobId,
            ERC1155AutoGraphMinterLogic.getHash(input),
            params.signature,
            params.units,
            params.nftContract,
            params.expiryToken
        );

        ERC1155AutoGraphMinterLogic.validateEthFee(params.paymentAmount);
        _verifyHashAndSignerRoleExpireHashAndDepleteBuffer(verifyParams);

        // Send the Eth to the payment recipient
        (bool success, ) = paymentRecipient.call{value: params.paymentAmount}("");
        require(success, "ERC1155AutoGraphMinter: Error sending ETH");

        ERC1155MaxSupplyMintable(params.nftContract).mint(params.recipient, params.tokenId, params.units);
        emit ERC1155Minted(params.nftContract, params.recipient, params.jobId, params.tokenId);
    }
    
    // Batch minting functions are similar to the original but use the library types
    
    function mintBatchForFree(
        address nftContract,
        address recipient,
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory inputs
    ) external globalLock(1) whenNotPaused onlyWhitelist(nftContract) {
        (uint256[] memory tokenIds, uint256[] memory units, ) = _mintBatch(nftContract, recipient, address(0), inputs);
        ERC1155MaxSupplyMintable(nftContract).mintBatch(recipient, tokenIds, units);
        emit ERC1155BatchMinted(nftContract, recipient, tokenIds, units);
    }

    function mintBatchWithPaymentTokenAsFee(
        address nftContract,
        address recipient,
        address paymentToken,
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory inputs
    ) external globalLock(1) whenNotPaused onlyWhitelist(nftContract) {
        (uint256[] memory tokenIds, uint256[] memory units, uint256 totalPayment) = _mintBatch(
            nftContract,
            recipient,
            paymentToken,
            inputs
        );

        ERC1155AutoGraphMinterLogic.validatePaymentTokenFee(paymentToken, totalPayment);
        IERC20(paymentToken).safeTransferFrom(msg.sender, paymentRecipient, totalPayment);
        ERC1155MaxSupplyMintable(nftContract).mintBatch(recipient, tokenIds, units);
        emit ERC1155BatchMinted(nftContract, recipient, tokenIds, units);
    }

    function mintBatchWithEthAsFee(
        address nftContract,
        address recipient,
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory inputs
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
    
    // Internal helper functions
    
    function _verifyHashAndSignerRoleExpireHashAndDepleteBuffer(
        ERC1155AutoGraphMinterLogic.VerifyInputParams memory params
    ) internal {
        require(
            ERC1155AutoGraphMinterLogic.isExpiryTokenValid(params.expiryToken, expiryTokenHoursValid),
            "ERC1155AutoGraphMinter: Expiry token is expired"
        );
        require(params.inputHash == params.generatedHash, "ERC1155AutoGraphMinter: Hash mismatch");
        require(!expiredHashes[params.inputHash], "ERC1155AutoGraphMinter: Hash expired");
        require(!completedJobs[params.jobId], "ERC1155AutoGraphMinter: Job already completed");
        require(
            core.hasRole(
                Roles.MINTER_NOTARY_PROTOCOL_ROLE,
                ERC1155AutoGraphMinterLogic.recoverSigner(params.inputHash, params.signature)
            ),
            "ERC1155AutoGraphMinter: Missing MINTER_NOTARY Role"
        );

        expiredHashes[params.inputHash] = true;
        completedJobs[params.jobId] = true;
        _depleteBuffer(params.units);
    }

    function _mintBatch(
        address nftContract,
        address recipient,
        address paymentToken,
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory inputs
    ) internal returns (uint256[] memory tokenIds, uint256[] memory units, uint256 totalPayment) {
        tokenIds = new uint256[](inputs.length);
        units = new uint256[](inputs.length);
        totalPayment = 0;

        for (uint256 i = 0; i < inputs.length; i++) {
            ERC1155AutoGraphMinterLogic.HashInputsParams memory hashInput = ERC1155AutoGraphMinterLogic.HashInputsParams(
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

            ERC1155AutoGraphMinterLogic.VerifyInputParams memory verifyInput = ERC1155AutoGraphMinterLogic.VerifyInputParams(
                inputs[i].hash,
                inputs[i].jobId,
                ERC1155AutoGraphMinterLogic.getHash(hashInput),
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

    // Admin functions
    
    function addWhitelistedContract(
        address nftContractAddress
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        whitelistedAddresses[nftContractAddress] = true;
        emit WhitelistedContractAdded(nftContractAddress);
    }

    function removeWhitelistedContract(
        address nftContractAddress
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        whitelistedAddresses[nftContractAddress] = false;
        emit WhitelistedContractRemoved(nftContractAddress);
    }

    function addWhitelistedContracts(
        address[] calldata whitelistAddresses
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        for (uint256 i = 0; i < whitelistAddresses.length; i++) {
            whitelistedAddresses[whitelistAddresses[i]] = true;
        }
    }

    function removeWhitelistedContracts(
        address[] calldata whitelistAddresses
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        for (uint256 i = 0; i < whitelistAddresses.length; i++) {
            whitelistedAddresses[whitelistAddresses[i]] = false;
        }
    }

    function updatePaymentRecipient(address _paymentRecipient) external hasRole(Roles.ADMIN) {
        require(_paymentRecipient != address(0), "ERC1155AutoGraphMinter: paymentRecipient must not be address(0)");
        paymentRecipient = _paymentRecipient;
        emit PaymentRecipientUpdated(_paymentRecipient);
    }

    function updateExpiryTokenHoursValid(uint8 _expiryTokenHoursValid) external hasRole(Roles.ADMIN) {
        require(ERC1155AutoGraphMinterLogic.isValidRange(_expiryTokenHoursValid, 1, 24), 
                "ERC1155AutoGraphMinter: Hours must be between 1 and 24");
        expiryTokenHoursValid = _expiryTokenHoursValid;
    }

    // Implement depleteBuffer directly instead of inheriting from RateLimited
    function _depleteBuffer(uint256 amount) internal {
        // Replenish buffer first
        _replenishBuffer();
        
        // Then deplete
        require(amount <= bufferRemaining, "RateLimited: buffer depleted");
        bufferRemaining = bufferRemaining - uint128(amount);
        emit BufferUsed(amount, bufferRemaining);
    }

    function _replenishBuffer() internal {
        uint256 timePassed = block.timestamp - lastReplenishTimestamp;
        uint256 toReplenish = uint256(replenishRatePerSecond) * timePassed;
        
        // Cap replenishment
        uint256 newBufferRemaining = bufferRemaining + toReplenish;
        if (newBufferRemaining > bufferCap) {
            newBufferRemaining = bufferCap;
        }
        
        // Update state
        bufferRemaining = uint128(newBufferRemaining);
        lastReplenishTimestamp = uint32(block.timestamp);
    }
} 