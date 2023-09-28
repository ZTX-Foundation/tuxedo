// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";

/// @title ERC721Staking
/// @notice contract to allow users to stake ERC721 tokens and earn rewards
/// Rewards are points that are non-transferrable.
/// Each epoch rewards will be distributed to stakers based on their share of the pool.
/// if a user doesn't claim their rewards before the next epoch, they will still be able to claim them.
/// The ADMIN role can update the reward rate and create new epochs.
/// Reward algorithm: user time staked during an epoch * amount staked / 1 hour
/// User Amount Staked = total amount of ERC721 tokens staked per user
interface IActualERC721Staking {
    /// ----------- EVENTS ------------

    /// @notice event emitted when a user claims rewards
    event RewardsClaimed(address indexed user, uint256 rewardAmount);

    /// @notice event emitted when a user stakes NFTs
    event Staked(address indexed user, uint256 amount, uint256[] tokenIds);

    /// @notice event emitted when a user withdraws NFTs
    event Withdrawn(address indexed user, uint256 amount, uint256[] tokenIds);

    /// @notice emitted when a new epoch is created
    event EpochCreated(uint256 epoch, uint200 epochStart, uint40 epochDuration);

    /// @notice the ERC721 Token to stake
    function stakingToken() external view returns (IERC721);

    /// @notice length of time to stake per point distributed
    // solhint-disable-next-line
    function REWARD_TIME() external view returns (uint256);

    /// ----------- EPOCH VARIABLES ------------

    struct Epoch {
        /// start time of the epoch
        uint200 epochStart;
        /// length of the epoch
        uint56 epochDuration;
    }

    /// @notice the current epoch number
    function epoch() external view returns (uint256);

    /// ----------- USER VARIABLES ------------

    /// @notice container for each staker's info
    struct StakerInfo {
        /// amount of NFT's staked
        uint32 amountStaked;
        /// last time the user staked
        uint216 lastStakedTime;
    }

    function rewardPoints(address _user, uint256 _epoch) external view returns (uint256);

    /// @notice total amount of ERC721 tokens staked per user
    function stakedUserInfo(address user) external view returns (uint32 amountStaked, uint216 lastStakedTime);

    /// @notice recording of ownership of ERC721 tokens staked
    function stakedAssets(uint256 tokenId) external view returns (address);

    /// ----------- PUBLIC VIEW ONLY API ------------

    /// @notice get the end time of the current epoch for rewards purposes
    function getCurrentTimestampOrEpochEnd() external view returns (uint256);

    /// @notice get the total rewards for a user across all epochs
    /// @param user the address of the user to get rewards for
    function getClaimedRewardsAcrossAllEpochs(address user) external view returns (uint256 rewards);

    /// @notice get the total amount of NFT's a user has staked
    /// @param user the address of the user to get the amount staked
    function getUserAmountStaked(address user) external view returns (uint256);

    /// @notice get info on the user's staked assets and time staked
    /// @param user the address of the user to get info for
    function getStakedUserInfo(address user) external view returns (uint40 amountStaked, uint216 lastStakedTime);

    /// @notice get info on a given epoch
    /// @param epochNumber the epoch number to get info for
    function getEpochInfo(uint256 epochNumber) external view returns (uint200 epochStart, uint56 epochDuration);

    /// @notice get the total rewards for a user across all epoch
    /// @param user the address of the user to get rewards for
    /// @return totalRewards the total rewards for a user across epochs, both claimed and unclaimed
    function getTotalRewards(address user) external view returns (uint256 totalRewards);

    /// @notice returns true if the epoch is active
    function isActiveEpoch(uint256 _epoch) external view returns (bool);

    /// ----------- PUBLIC STATE CHANGING API ------------

    /// @notice get point rewards for staking
    /// @param user the address of the user to claim rewards for
    function updateUserReward(address user) external;

    /// @notice Stakes user's NFTs
    /// @param tokenIds The tokenIds of the NFTs which will be staked
    function stake(uint256[] memory tokenIds) external;

    /// @notice Withdraws staked user's NFTs
    /// @param tokenIds The tokenIds of the NFTs which will be withdrawn
    function unstake(uint256[] memory tokenIds) external;

    /// ----------- ADMIN ONLY API ------------

    /// @notice create a new epoch, callable only by admin
    /// @param epochStart the start time of the epoch
    /// @param epochDuration the length of the epoch
    function createNewEpoch(uint200 epochStart, uint40 epochDuration) external;
}
