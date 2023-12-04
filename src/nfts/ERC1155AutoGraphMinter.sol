// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {WhitelistedAddresses} from "@protocol/utils/extensions/WhitelistedAddresses.sol";
import {RateLimited} from "@protocol/utils/extensions/RateLimited.sol";

contract ERC1155AutoGraphMinter is WhitelistedAddresses, CoreRef, RateLimited {
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

    /// @notice - expiryToken value for x amount hours
    uint8 public expiryTokenHoursValid; // 1 - 24 hours

    /// --------- Structs ---------- ///

    /// @dev - MintBatchParams is a struct that contains the params for minting a batch of NFTs
    /// @param jobId - ID of the job
    /// @param tokenId - ID of the NFT
    /// @param units - Amount of NFTs to mint
    /// @param hash - Hash of the message to be signed
    /// @param salt - Salt of the message to be signed
    /// @param signature - Signature of the message to be signed
    /// @param paymentAmount - Amount of the token to be used for payment
    /// @param expiryToken - Expiry token timestamp. ie create a timestamp.now on creation of the hash
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

    /// @dev - HashInputsParams is a struct that contains the params for generating a hash
    /// @param recipient - Address of the receiver of the NFT
    /// @param jobId - ID of the job
    /// @param tokenId - ID of the NFT
    /// @param units - Amount of NFTs to mint
    /// @param salt - Salt of the message to be signed
    /// @param nftContract - Address of the NFT contract to Mint from
    /// @param paymentToken - Address of the token to be used for payment
    /// @param paymentAmount - Amount of the token to be used for payment
    /// @param expiryToken - Expiry token timestamp. ie create a timestamp.now on creation of the hash
    struct HashInputsParams {
        address recipient;
        uint256 jobId;
        uint256 tokenId; // nft token id to be minted
        uint256 units; // units to be minted
        uint256 salt;
        address nftContract; // nft contract address
        address paymentToken; // token to be used for payment if payment is required
        uint256 paymentAmount; // amount of token to be used for payment if payment is required
        uint256 expiryToken;
    }

    /// @dev helper function to verify and process mint inputs
    /// @param inputHash - Hash of the message send from the users tx
    /// @param jobId - ID of the job
    /// @param generatedHash - Hash of the message generated by the contract to compare against the inputHash
    /// @param signature - Signature of the message to be signed
    /// @param units - Amount of NFTs to mint
    /// @param nftContract - Address of the NFT contract to Mint from
    struct VerifyInputParams {
        bytes32 inputHash;
        uint256 jobId;
        bytes32 generatedHash;
        bytes signature;
        uint256 units;
        address nftContract;
        uint256 expiryToken;
    }

    /// @param recipient - Address of the receiver of the NFT
    /// @param tokenId - ID of the NFT
    /// @param jobId - ID of the job
    /// @param units - Amount of NFTs to mint
    /// @param hash - Hash of the message to be signed
    /// @param salt - Salt of the message to be signed
    /// @param signature - Signature of the message to be signed
    /// @param nftContract - Address of the NFT contract to Mint from
    /// @param paymentToken - Address of the token to be used for payment. Cant be address(0)
    /// @param paymentAmount - Amount of the token to be used for payment. Cant be 0
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

    /// @param recipient - Address of the receiver of the NFT
    /// @param jobId - ID of the job
    /// @param tokenId - ID of the NFT
    /// @param units - Amount of NFTs to mint
    /// @param hash - Hash of the message to be signed
    /// @param salt - Salt of the message to be signed
    /// @param signature - Signature of the message to be signed
    /// @param nftContract - Address of the NFT contract to Mint from
    /// @param paymentAmount - Amount of the token to be used for payment
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

    constructor(
        address _core,
        address[] memory _nftContracts,
        uint128 _replenishRatePerSecond,
        uint128 _bufferCap,
        address _paymentRecipient,
        uint8 _expiryTokenHoursValid
    ) CoreRef(_core) WhitelistedAddresses(_nftContracts) RateLimited(_replenishRatePerSecond, _bufferCap) {
        require(_paymentRecipient != address(0), "ERC1155AutoGraphMinter: paymentRecipient must not be address(0)");
        require(_isValidRange(_expiryTokenHoursValid, 1, 24), "ERC1155AutoGraphMinter: Hours must be between 1 and 24");

        // save to storage
        paymentRecipient = _paymentRecipient;
        expiryTokenHoursValid = _expiryTokenHoursValid;
    }

    /// ----------- Helpers ----------- ///

    /// @dev - Verifies the inputs and processes the mint
    /// ie checks and efforts
    /// @param params - VerifyInputParams struct
    function _verifyHashAndSignerRoleExpireHashAndDepleteBuffer(VerifyInputParams memory params) internal {
        require(_isExpiryTokenValid(params.expiryToken), "ERC1155AutoGraphMinter: Expiry token is expired");
        require(params.inputHash == params.generatedHash, "ERC1155AutoGraphMinter: Hash mismatch");
        require(!expiredHashes[params.inputHash], "ERC1155AutoGraphMinter: Hash expired");
        require(!completedJobs[params.jobId], "ERC1155AutoGraphMinter: Job already completed");
        require(
            core.hasRole(Roles.MINTER_NOTARY_PROTOCOL_ROLE, recoverSigner(params.inputHash, params.signature)),
            "ERC1155AutoGraphMinter: Missing MINTER_NOTARY Role"
        );

        // expire that hash baby
        expiredHashes[params.inputHash] = true;

        /// @dev expire the job
        completedJobs[params.jobId] = true;

        // _deplete the rate limit buffer
        _depleteBuffer(params.units);
    }

    function _isExpiryTokenValid(uint256 expiryToken) internal view returns (bool) {
        require(expiryToken <= block.timestamp, "ERC1155AutoGraphMinter: Expiry token must be in the past");

        // Convert hours to seconds
        uint256 hoursInSeconds = uint256(expiryTokenHoursValid) * 1 hours;

        // get time diff
        uint256 diff = block.timestamp - expiryToken;

        if (diff < hoursInSeconds) {
            return true;
        } else {
            return false;
        }
    }

    /// @dev checks to make sure the payment token is set to a non address(0) address and the payment amount greater than 0
    function _mintChecksForPaymentTokenFee(address paymentToken, uint256 paymentAmount) internal pure {
        require(paymentToken != address(0), "ERC1155AutoGraphMinter: paymentToken must not be address(0)");
        require(paymentAmount > 0, "ERC1155AutoGraphMinter: paymentAmount must be greater than 0");
    }

    /// @dev checks to make sure the payment token is address(0) and the payment amount greater than 0
    function _mintChecksForEthFee(uint256 paymentAmount) internal view {
        require(paymentAmount > 0, "ERC1155AutoGraphMinter: paymentAmount must be greater than 0");
        require(msg.value == paymentAmount, "ERC1155AutoGraphMinter: Payment amount does not match msg.value");
    }

    /// @dev helper function to mint batch of NFTs
    function _mintBatch(
        address nftContract,
        address recipient,
        address paymentToken,
        MintBatchParams[] memory inputs
    ) internal returns (uint256[] memory, uint256[] memory, uint256) {
        uint256[] memory tokenIds = new uint256[](inputs.length);
        uint256[] memory units = new uint256[](inputs.length);
        uint256 totalPayment = 0;
        HashInputsParams memory input;
        VerifyInputParams memory params;

        unchecked {
            for (uint256 i = 0; i < inputs.length; i++) {
                tokenIds[i] = inputs[i].tokenId;
                units[i] = inputs[i].units;

                input = HashInputsParams(
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
                params = VerifyInputParams(
                    inputs[i].hash,
                    inputs[i].jobId,
                    getHash(input),
                    inputs[i].signature,
                    inputs[i].units,
                    nftContract,
                    inputs[i].expiryToken
                );
                _verifyHashAndSignerRoleExpireHashAndDepleteBuffer(params);
                /// No way the total payment will overflow
                totalPayment += inputs[i].paymentAmount;
            }
        }
        return (tokenIds, units, totalPayment);
    }

    /// @dev helper function to check if a uint8 is within a range
    function _isValidRange(uint8 input, uint8 minRange, uint8 maxRange) private pure returns (bool) {
        return input >= minRange && input <= maxRange;
    }

    // ----------------------- Mint functions ----------------------- //

    /// @notice - Mint NFTs to a given address with a given signature
    /// @dev when creating the hash set paymentToken to address(0) and paymentAmount to 0
    /// @param recipient - Address of the receiver of the NFT
    /// @param jobId - ID of the job
    /// @param tokenId - ID of the NFT
    /// @param units - Amount of NFTs to mint
    /// @param hash - Hash of the message to be signed
    /// @param salt - Salt of the message to be signed
    /// @param signature - Signature of the message to be signed
    /// @param nftContract - Address of the NFT contract to Mint from
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
        HashInputsParams memory input = HashInputsParams(
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
        VerifyInputParams memory params = VerifyInputParams(
            hash,
            jobId,
            getHash(input),
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
    /// @dev when creating the hash set paymentToken to address(0) and paymentAmount to 0
    function mintWithPaymentTokenAsFee(
        MintWithPaymentTokenAsFeeParams memory params
    ) external globalLock(1) whenNotPaused onlyWhitelist(params.nftContract) {
        HashInputsParams memory input = HashInputsParams(
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
        VerifyInputParams memory verifyInputParams = VerifyInputParams(
            params.hash,
            params.jobId,
            getHash(input),
            params.signature,
            params.units,
            params.nftContract,
            params.expiryToken
        );

        _mintChecksForPaymentTokenFee(params.paymentToken, params.paymentAmount);
        _verifyHashAndSignerRoleExpireHashAndDepleteBuffer(verifyInputParams);

        /// make transfer for fee payment
        IERC20(params.paymentToken).safeTransferFrom(msg.sender, paymentRecipient, params.paymentAmount);

        ERC1155MaxSupplyMintable(params.nftContract).mint(params.recipient, params.tokenId, params.units);
        emit ERC1155Minted(params.nftContract, params.recipient, params.jobId, params.tokenId);
    }

    /// @notice - Mint NFTs to a given address with a given signature with Eth as a fee used for Instant Craft ingame
    function mintWithEthAsFee(
        MintWithEthAsFeeParams memory params
    ) external payable globalLock(1) whenNotPaused onlyWhitelist(params.nftContract) {
        HashInputsParams memory input = HashInputsParams(
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
        VerifyInputParams memory verifyInputParams = VerifyInputParams(
            params.hash,
            params.jobId,
            getHash(input),
            params.signature,
            params.units,
            params.nftContract,
            params.expiryToken
        );

        _mintChecksForEthFee(params.paymentAmount);
        _verifyHashAndSignerRoleExpireHashAndDepleteBuffer(verifyInputParams);

        /// make transfer
        (bool sent, ) = payable(paymentRecipient).call{value: params.paymentAmount}("");
        require(sent, "ERC1155AutoGraphMinter: Failed to send Ether");

        ERC1155MaxSupplyMintable(params.nftContract).mint(params.recipient, params.tokenId, params.units);
        emit ERC1155Minted(params.nftContract, params.recipient, params.jobId, params.tokenId);
    }

    // ----------------------- Mint Batch functions ----------------------- //

    /// @dev - Mint Batch of NFTs
    /// @param nftContract - Address of the NFT contract to Mint from
    /// @param recipient - Address of the receiver of the NFT
    /// @param inputs - Array of MintBatchParams
    function mintBatchForFree(
        address nftContract,
        address recipient,
        MintBatchParams[] memory inputs
    ) external globalLock(1) whenNotPaused onlyWhitelist(nftContract) {
        (uint256[] memory tokenIds, uint256[] memory units, ) = _mintBatch(nftContract, recipient, address(0), inputs);

        ERC1155MaxSupplyMintable(nftContract).mintBatch(recipient, tokenIds, units);
        emit ERC1155BatchMinted(nftContract, recipient, tokenIds, units);
    }

    function mintBatchWithPaymentTokenAsFee(
        address nftContract,
        address recipient,
        address paymentToken,
        MintBatchParams[] memory inputs
    ) external globalLock(1) whenNotPaused onlyWhitelist(nftContract) {
        (uint256[] memory tokenIds, uint256[] memory units, uint256 totalPayment) = _mintBatch(
            nftContract,
            recipient,
            paymentToken,
            inputs
        );

        _mintChecksForPaymentTokenFee(paymentToken, totalPayment);

        /// make transfer for fee payment
        IERC20(paymentToken).safeTransferFrom(msg.sender, paymentRecipient, totalPayment);

        ERC1155MaxSupplyMintable(nftContract).mintBatch(recipient, tokenIds, units);
        emit ERC1155BatchMinted(nftContract, recipient, tokenIds, units);
    }

    // @dev - Mint Batch of NFTs with Eth as a fee used for Instant Craft ingame
    /// @param nftContract - Address of the NFT contract to Mint from
    /// @param recipient - Address of the receiver of the NFT
    /// @param inputs - Array of MintBatchParams
    function mintBatchWithEthAsFee(
        address nftContract,
        address recipient,
        MintBatchParams[] memory inputs
    ) external payable globalLock(1) whenNotPaused onlyWhitelist(nftContract) {
        (uint256[] memory tokenIds, uint256[] memory units, uint256 totalPayment) = _mintBatch(
            nftContract,
            recipient,
            address(0),
            inputs
        );

        _mintChecksForEthFee(totalPayment);
        (bool sent, ) = payable(paymentRecipient).call{value: totalPayment}("");
        require(sent, "ERC1155AutoGraphMinter: Failed to send Ether");

        ERC1155MaxSupplyMintable(nftContract).mintBatch(recipient, tokenIds, units);
        emit ERC1155BatchMinted(nftContract, recipient, tokenIds, units);
    }

    /// ------ Hashing functions ------ ///

    /// @dev - Returns the hash of the message
    /// @param input - hashInputs struct
    function getHash(HashInputsParams memory input) public pure returns (bytes32) {
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

    /// @dev - Returns the address that signed a given string message
    /// @param hash - Keccak-256 hash
    /// @param signature - Signature of the signed hash
    function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address) {
        return hash.recover(signature);
    }

    /// ------ WhiteListedAddresses functions ------ ///

    /// @notice admin or token governor-only method to whitelist a nft contract address
    /// @param nftContractAddress the address to whitelist
    function addWhitelistedContract(
        address nftContractAddress
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        _addWhitelistAddress(nftContractAddress);
        emit WhitelistedContractAdded(nftContractAddress);
    }

    /// @notice admin or token governor-only method to remove whitelist address
    /// @param nftContractAddress the address to whitelist
    function removeWhitelistedContract(
        address nftContractAddress
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        _removeWhitelistAddress(nftContractAddress);
        emit WhitelistedContractRemoved(nftContractAddress);
    }

    /// @notice batch version of addWhiteListaddress
    /// @param whitelistAddresses the addresses to whitelist, as calldata
    function addWhitelistedContracts(
        address[] calldata whitelistAddresses
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        _addWhitelistAddresses(whitelistAddresses);
    }

    /// @notice batch version of removeWhiteListaddress
    /// @param whitelistAddresses the addresses remove from whitelist, as calldata
    function removeWhitelistedContracts(
        address[] calldata whitelistAddresses
    ) external hasAnyOfTwoRoles(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN) {
        _removeWhitelistAddresses(whitelistAddresses);
    }

    /// ------ Update Payment Recipient functions ------ ///

    /// @notice - Updates the payment recipient
    /// @param _paymentRecipient - Address of the new payment recipient
    function updatePaymentRecipient(address _paymentRecipient) external hasRole(Roles.ADMIN) {
        require(_paymentRecipient != address(0), "ERC1155AutoGraphMinter: paymentRecipient must not be address(0)");
        paymentRecipient = _paymentRecipient;
        emit PaymentRecipientUpdated(_paymentRecipient);
    }

    function updateExpiryTokenHoursValid(uint8 _expiryTokenHoursValid) external hasRole(Roles.ADMIN) {
        require(_isValidRange(_expiryTokenHoursValid, 1, 24), "ERC1155AutoGraphMinter: Hours must be between 1 and 24");
        expiryTokenHoursValid = _expiryTokenHoursValid;
    }
}
