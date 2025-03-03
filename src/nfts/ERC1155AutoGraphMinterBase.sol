// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {WhitelistedAddresses} from "@protocol/utils/extensions/WhitelistedAddresses.sol";
import {RateLimited} from "@protocol/utils/extensions/RateLimited.sol";
import {Roles} from "@protocol/core/Roles.sol";

/**
 * @title ERC1155AutoGraphMinterBase
 * @notice Abstract base contract with shared state variables and common functionality
 */
abstract contract ERC1155AutoGraphMinterBase is WhitelistedAddresses, CoreRef, RateLimited {
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

    /// @dev helper function to check if a uint8 is within a range
    function _isValidRange(uint8 input, uint8 minRange, uint8 maxRange) internal pure returns (bool) {
        return input >= minRange && input <= maxRange;
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
