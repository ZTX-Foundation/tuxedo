// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Roles} from "@protocol/core/Roles.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

contract JobRegistry is CoreRef {
    /// @notice pending job event
    event PendingJob(address indexed  contractAddress, uint256 indexed tokenId, uint256 indexed jobId);

    /// @notice completed job event
    event CompletedJob(address indexed contractAddress, uint256 indexed tokenId, uint256 indexed jobId);

    /// @notice pending jobs
    /// @dev only pending jobs may be removed
    mapping(address contractAddress => mapping(uint256 tokenId => uint256[] jobId)) public pendingJobs;

    /// @notice completed jobs
    mapping(address contractAddress => mapping(uint256 tokenId => uint256[] jobId)) public completedJobs;

    constructor(address _core) CoreRef(_core) {}

    /// @notice register a job
    /// @param contractAddress the address of the NFT contract
    /// @param tokenId the token Id
    /// @param jobId the job Id to register
    function registerJob(address contractAddress, uint256 tokenId, uint256 jobId)
        external
        whenNotPaused
        hasAnyOfTwoRoles(Roles.ADMIN, Roles.REGISTRY_OPERATOR_PROTOCOL_ROLE)
    {
        require(!_isPending(contractAddress, tokenId, jobId), "JobRegistry: job is already pending");
        require(_remainingSupplyOf(contractAddress, tokenId) > 0, "JobRegistry: supply exhausted");
        require(!_isCompleted(contractAddress, tokenId, jobId), "JobRegistry: job is already completed");

        /// @notice set the job as pending
        pendingJobs[contractAddress][tokenId].push(jobId);

        emit PendingJob(contractAddress, tokenId, jobId);
    }

    /// @notice mark a job as complete
    /// @param contractAddress the address of the NFT contract
    /// @param tokenId the token Id
    /// @param jobId the job Id to set as completed
    function completeJob(address contractAddress, uint256 tokenId, uint256 jobId)
        external
        whenNotPaused
        hasAnyOfTwoRoles(Roles.ADMIN, Roles.REGISTRY_OPERATOR_PROTOCOL_ROLE)
    {
        require(!_isCompleted(contractAddress, tokenId, jobId), "JobRegistry: job is already completed");

        /// @notice remove from the pending queue
        _removePendingJob(contractAddress, tokenId, jobId);
        completedJobs[contractAddress][tokenId].push(jobId);

        emit CompletedJob(contractAddress, tokenId, jobId);
    }

    /// @notice is job pending
    /// @param contractAddress the address of the NFT contract
    /// @param tokenId the tokenId
    /// @return bool
    function isPending(address contractAddress, uint256 tokenId, uint256 jobId) external view returns (bool) {
        return _isPending(contractAddress, tokenId, jobId);
    }

    /// @notice is job completed
    /// @param contractAddress the address of the NFT contract
    /// @param tokenId the tokenId
    /// @return bool
    function isCompleted(address contractAddress, uint256 tokenId, uint256 jobId) external view returns (bool) {
        return _isCompleted(contractAddress, tokenId, jobId);
    }

    /// @notice get the remaining supply
    /// @param contractAddress the address of the NFT contract
    /// @param tokenId the tokenId
    /// @return the remaining supply
    function remainingSupplyOf(address contractAddress, uint256 tokenId) external view returns (uint256) {
        uint256 remainingSupply = _remainingSupplyOf(contractAddress, tokenId);
        return remainingSupply;
    }

    /// @notice is the job pending
    /// @param contractAddress the address of the NFT contract
    /// @param tokenId the tokenId
    /// @param jobId the job Id to search for
    function _isPending(address contractAddress, uint256 tokenId, uint256 jobId) private view returns (bool) {
        uint256[] memory _pendingJobs = pendingJobs[contractAddress][tokenId];
        return _searchForJob(jobId, _pendingJobs);
    }

    /// @notice is the job completed
    /// @param contractAddress the address of the NFT contract
    /// @param tokenId the tokenId
    /// @param jobId the job Id to search for
    function _isCompleted(address contractAddress, uint256 tokenId, uint256 jobId) private view returns (bool) {
        uint256[] memory _completedJobs = completedJobs[contractAddress][tokenId];
        return _searchForJob(jobId, _completedJobs);
    }

    /// @notice search for a given job
    /// @param jobId the job Id to search for
    /// @param jobList the list of jobs to search
    function _searchForJob(uint256 jobId, uint256[] memory jobList) private view returns (bool) {
        for (uint256 i = 0; i < jobList.length; ) {
            if (jobList[i] == jobId) {
                return true;
            }

            unchecked {
                i++;
            }
        }

        return false;
    }

    /// @notice remove pending job
    /// @param contractAddress the address of the NFT contract
    /// @param tokenId the tokenId
    /// @param jobId the job Id to remove
    function _removePendingJob(address contractAddress, uint256 tokenId, uint256 jobId) private {
        uint256 _index = _indexOfJob(jobId, pendingJobs[contractAddress][tokenId]);
        uint256[] storage _pendingJobs = _removeJob(_index, pendingJobs[contractAddress][tokenId]);
        pendingJobs[contractAddress][tokenId] = _pendingJobs;
    }

    /// @notice get index of a job Id
    /// @param jobId job Id to get the index of
    /// @param jobList the list of jobs to remove from
    function _indexOfJob(uint256 jobId, uint256[] memory jobList) private view returns (uint256 _index) {
        for (uint256 i = 0; i < jobList.length; ) {
            if (jobList[i] == jobId) {
                return i;                
            }

            unchecked {
                i++;
            }
        }
    }

    /// @notice remove item from array and shift everything to the right
    /// @param index index to remove
    /// @param jobList the list of jobs to remove from
    function _removeJob(uint256 index, uint256[] storage jobList) private returns (uint256[] storage) {
        require(index < jobList.length, "JobRegistry: index out of bound");

        for (uint i = index; i < jobList.length - 1; ) {
            jobList[i] = jobList[i + 1];

            unchecked {
                i++;
            }
        }
        jobList.pop();

        return jobList;
    }

    /// @notice remaining supply
    /// @param contractAddress the address of the NFT contract
    /// @param tokenId the tokenId
    /// @return the remaining supply
    function _remainingSupplyOf(address contractAddress, uint256 tokenId) private view returns (uint256) {
        ERC1155MaxSupplyMintable nftContract = ERC1155MaxSupplyMintable(contractAddress);

        uint256 pendingJobCount = pendingJobs[contractAddress][tokenId].length;
        uint256 completedJobCount = completedJobs[contractAddress][tokenId].length;
        uint256 currentSupply = nftContract.totalSupply(tokenId);
        uint256 maxTokenSupply = nftContract.maxTokenSupply(tokenId);

        require(pendingJobCount + completedJobCount + currentSupply <= maxTokenSupply);

        return (maxTokenSupply - (pendingJobCount + completedJobCount + currentSupply));
    }
}
