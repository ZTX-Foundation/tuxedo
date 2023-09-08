pragma solidity 0.8.18;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {IWETH} from "@protocol/interface/IWETH.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {ERC20HoldingDeposit} from "@protocol/finance/ERC20HoldingDeposit.sol";

/// Game payment contract for users to boost gampeplay
/// Inherits CoreRef for roles and access
contract GameConsumer is CoreRef, ERC20HoldingDeposit {
    using SafeERC20 for *;
    using ECDSA for bytes32;

    /// @custom:deprecated
    /// @notice event emitted when fast crafting happens
    event FastCraft(uint256 indexed tokenId, uint256 indexed jobId, uint256 amountPaid, uint256 amountToMint);

    /// @custom:deprecated
    /// @notice event emitted when in game boost happens
    event InGameBoost(uint256 indexed jobId, uint256 amount);

    /// @notice event emitted when in payment is taken
    event TakePayment(uint256 indexed jobId, uint256 amount);

    /// @notice event emitted when proceeds are withdrawn
    event WithdrawToCollector(address proceedsCollector, uint256 amount);

    /// @notice event emitted when crafting fee is updated
    event CraftingFeeUpdated(uint256 oldCraftingFee, uint256 newCraftingFee);

    /// @notice event emitted when proceeds collector is updated
    event ProceedsRecipientUpdated(address proceedsCollector);

    /// @notice event emitted when tokens are swept
    event TokensSwept(address indexed token, address proceedsCollector, uint256 amount);

    /// @notice proceeds recipient
    address public proceedsRecipient;

    /// @notice WETH token
    IWETH public immutable weth;

    /// @notice store used hashes
    mapping(bytes32 hash => bool isUsed) public usedHashes;

    /// @notice construct the ERC20HoldingDeposit and CoreRef contract
    /// @param _core address of the core contract
    /// @param _token address of the payment token
    /// @param _proceedsRecipient address to send all proceeds to
    /// @param _weth address of the weth token
    constructor(
        address _core,
        address _token,
        address _proceedsRecipient,
        address _weth
    ) ERC20HoldingDeposit(_core, _token) {
        require(_proceedsRecipient != address(0), "GameConsumer: proceeds recipient cannot be address(0)");
        weth = IWETH(_weth);
        proceedsRecipient = _proceedsRecipient;
    }

    /// @notice speed up crafting
    /// @dev pausing stops this function from being called by all external
    /// functions that emit crafting or speed up events
    /// @param quoteExpiry Expiry time of the quote
    /// @param craftedHash Hash of the message from calldata
    /// @param hash Hash of the message
    /// @param signature Signature of the message
    function _verifySignerAndHash(
        uint256 quoteExpiry,
        bytes32 craftedHash,
        bytes32 hash,
        bytes memory signature
    ) internal whenNotPaused {
        require(hash == craftedHash, "GameConsumer: hash mismatch");
        /// offchain will handle when the quote expires
        require(quoteExpiry >= block.timestamp, "GameConsumer: timestamp expired");
        require(!usedHashes[hash], "GameConsumer: hash already used");
        require(
            core.hasRole(Roles.GAME_CONSUMER_NOTARY, recoverSigner(hash, signature)),
            "GameConsumer: Missing GAME_CONSUMER_NOTARY Role"
        );

        usedHashes[hash] = true;
    }

    /// @custom:deprecated
    /// @notice speed up crafting
    /// @param tokenId token ID of the NFT for instant craft
    /// @param tokenAmount Amount of the ERC1155 token
    /// @param paymentToken Address of the token to pay in
    /// @param jobId ID of the offchain job
    /// @param jobFee Amount of the job fee
    /// @param quoteExpiry Expiry time of the quote
    /// @param hash Hash of the message
    /// @param salt A random number to prevent brute force ie a timestamp
    /// @param signature Signature of the message
    function fastCraft(
        uint256 tokenId,
        uint256 tokenAmount,
        address paymentToken,
        uint256 jobId,
        uint256 jobFee,
        uint256 quoteExpiry,
        bytes32 hash,
        uint256 salt,
        bytes memory signature
    ) external {
        /// checks and effects
        _verifySignerAndHash(
            quoteExpiry,
            getHashFastCraft(tokenId, paymentToken, tokenAmount, jobId, jobFee, quoteExpiry, salt),
            hash,
            signature
        );

        /// interactions
        IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), jobFee);

        emit FastCraft(tokenId, jobId, jobFee, tokenAmount);
    }

    /// @custom:deprecated
    /// @notice speed up crafting
    /// @param tokenId token ID of the NFT for instant craft
    /// @param tokenAmount Amount of the ERC1155 token
    /// @param jobId ID of the offchain job
    /// @param jobFee Amount of the job fee
    /// @param quoteExpiry Expiry time of the quote
    /// @param hash Hash of the message
    /// @param salt A random number to prevent brute force ie a timestamp
    /// @param signature Signature of the message
    function fastCraftWithEth(
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 jobId,
        uint256 jobFee,
        uint256 quoteExpiry,
        bytes32 hash,
        uint256 salt,
        bytes memory signature
    ) external payable {
        require(msg.value == jobFee, "GameConsumer: incorrect job fee");

        /// checks and effects
        _verifySignerAndHash(
            quoteExpiry,
            getHashFastCraft(tokenId, address(weth), tokenAmount, jobId, jobFee, quoteExpiry, salt),
            hash,
            signature
        );

        emit FastCraft(tokenId, jobId, jobFee, tokenAmount);
    }

    /// @custom:deprecated
    /// @notice boost in game with Eth
    /// @param jobId ID of the offchain job
    /// @param jobFee Amount of the job fee
    /// @param quoteExpiry A random number to prevent brute force ie a timestamp
    /// @param hash Hash of the message
    /// @param salt A random number to prevent collisions
    /// @param signature Signature of the message
    function inGameBoostWithEth(
        uint256 jobId,
        uint256 jobFee,
        uint256 quoteExpiry,
        bytes32 hash,
        uint256 salt,
        bytes memory signature
    ) external payable {
        require(msg.value == jobFee, "GameConsumer: incorrect job fee");

        /// checks and effects
        _verifySignerAndHash(
            quoteExpiry,
            getHashInGameBoost(jobId, address(weth), jobFee, quoteExpiry, salt),
            hash,
            signature
        );

        emit InGameBoost(jobId, jobFee);
    }

    /// @custom:deprecated
    /// @notice boost in game
    /// @param jobId ID of the offchain job
    /// @param jobFee Amount of the job fee
    /// @param paymentToken Address of the token to pay in
    /// @param quoteExpiry A random number to prevent brute force ie a timestamp
    /// @param hash Hash of the message
    /// @param salt A random number to prevent collisions
    /// @param signature Signature of the message
    function inGameBoost(
        uint256 jobId,
        uint256 jobFee,
        address paymentToken,
        uint256 quoteExpiry,
        bytes32 hash,
        uint256 salt,
        bytes memory signature
    ) external {
        /// checks and effects
        _verifySignerAndHash(
            quoteExpiry,
            getHashInGameBoost(jobId, paymentToken, jobFee, quoteExpiry, salt),
            hash,
            signature
        );

        IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), jobFee);

        emit InGameBoost(jobId, jobFee);
    }

    /// @notice generic take payment function
    /// @param jobId ID of the offchain job
    /// @param jobFee Amount of the job fee
    /// @param paymentToken Address of the token to pay in
    /// @param quoteExpiry A random number to prevent brute force ie a timestamp
    /// @param hash Hash of the message
    /// @param salt A random number to prevent collisions
    /// @param signature Signature of the message
    function takePayment(
        uint256 jobId,
        uint256 jobFee,
        address paymentToken,
        uint256 quoteExpiry,
        bytes32 hash,
        uint256 salt,
        bytes memory signature
    ) external {
        /// checks and effects
        _verifySignerAndHash(
            quoteExpiry,
            getHash(jobId, paymentToken, jobFee, quoteExpiry, salt),
            hash,
            signature
        );

        IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), jobFee);

        emit TakePayment(jobId, jobFee);
    }

    /// @notice generic take payment in ETH function
    /// @param jobId ID of the offchain job
    /// @param jobFee Amount of the job fee
    /// @param quoteExpiry A random number to prevent brute force ie a timestamp
    /// @param hash Hash of the message
    /// @param salt A random number to prevent collisions
    /// @param signature Signature of the message
    function takePaymentWithEth(
        uint256 jobId,
        uint256 jobFee,
        uint256 quoteExpiry,
        bytes32 hash,
        uint256 salt,
        bytes memory signature
    ) external payable {
        require(msg.value == jobFee, "GameConsumer: incorrect job fee");

        /// checks and effects
        _verifySignerAndHash(
            quoteExpiry,
            getHash(jobId, address(weth), jobFee, quoteExpiry, salt),
            hash,
            signature
        );

        emit TakePayment(jobId, jobFee);
    }

    /// @dev Returns the hash of the message
    /// @param tokenId ID of the NFT for fast craft
    /// @param paymentToken Address of the token to pay in
    /// @param tokenAmount Amount of ERC1155 tokens to purchase
    /// @param jobId ID of the offchain job
    /// @param jobFee Amount of the job fee
    /// @param expireTimestamp A time stamp of when the sig expires, prevents expired quotes usage
    /// @param salt A random number to prevent collisions
    function getHashFastCraft(
        uint256 tokenId,
        address paymentToken,
        uint256 tokenAmount,
        uint256 jobId,
        uint256 jobFee,
        uint256 expireTimestamp,
        uint256 salt
    ) public pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encode(tokenId, paymentToken, tokenAmount, jobId, jobFee, expireTimestamp, salt));

        return hash.toEthSignedMessageHash();
    }

    /// @dev Returns the hash of the message
    /// @param jobId ID of the offchain job
    /// @param paymentToken Address of the token to pay in
    /// @param jobFee Amount of the job fee
    /// @param hashTimestamp A time stamp to prevent expired quotes
    /// @param salt A random number to prevent collisions
    function getHashInGameBoost(
        uint256 jobId,
        address paymentToken,
        uint256 jobFee,
        uint256 hashTimestamp,
        uint256 salt
    ) public pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encode(jobId, paymentToken, jobFee, hashTimestamp, salt));

        return hash.toEthSignedMessageHash();
    }

    /// @dev Generic hashing method
    /// @param jobId ID of the offchain job
    /// @param paymentToken Address of the token to pay in
    /// @param jobFee Amount of the job fee
    /// @param hashTimestamp A time stamp to prevent expired quotes
    /// @param salt A random number to prevent collisions
    function getHash(
        uint256 jobId,
        address paymentToken,
        uint256 jobFee,
        uint256 hashTimestamp,
        uint256 salt
    ) public pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encode(jobId, paymentToken, jobFee, hashTimestamp, salt));

        return hash.toEthSignedMessageHash();
    }

    /// @dev Returns the address that signed a given string message
    /// @param hash Signed Keccak-256 hash
    function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address) {
        return hash.recover(signature);
    }

    /// @notice set the proceeds recipient
    /// @dev callable only by admin
    /// @param _proceedsRecipient the proceeds recipient
    function setProceedsCollector(address _proceedsRecipient) external onlyRole(Roles.ADMIN) {
        proceedsRecipient = _proceedsRecipient;

        emit ProceedsRecipientUpdated(_proceedsRecipient);
    }

    /// @notice turn raw eth into wrapped eth
    function wrapEth() external {
        weth.deposit{value: address(this).balance}();
    }

    /// @notice withdraw token proceeds to proceeds recipient
    function sweepUnclaimed() external {
        uint256 tokenBalance = token.balanceOf(address(this));
        token.safeTransfer(proceedsRecipient, tokenBalance);

        emit TokensSwept(address(token), proceedsRecipient, tokenBalance);
    }

    /// @notice withdraw WETH proceeds to proceeds recipient
    function sweepUnclaimedWeth() external {
        uint256 tokenBalance = weth.balanceOf(address(this));
        IERC20(address(weth)).safeTransfer(proceedsRecipient, tokenBalance);

        emit TokensSwept(address(weth), proceedsRecipient, tokenBalance);
    }
}
