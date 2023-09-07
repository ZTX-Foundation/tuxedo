// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {IActualERC721Staking} from "@protocol/nfts/staking/IActualERC721Staking.sol";

/// @title ERC721Staking
/// @notice contract to allow users to stake ERC721 tokens and earn rewards
/// Rewards are points that are non-transferrable.
/// Each epoch rewards will be distributed to stakers based on their share of the pool.
/// if a user doesn't claim their rewards before the next epoch, they will still be able to claim them.
/// The ADMIN role can update the reward rate and create new epochs.
/// Reward algorithm: user time staked during an epoch * amount staked / 1 hour
/// User Amount Staked = total amount of ERC721 tokens staked per user
contract ActualERC721Staking is ERC721Holder, CoreRef, IActualERC721Staking {
    using SafeCast for uint256;

    /// @notice the ERC721 Token to stake
    IERC721 public immutable stakingToken;

    /// @notice length of time to stake per point distributed
    uint256 public constant REWARD_TIME = 1 hours;

    /// ----------- EPOCH VARIABLES ------------

    /// @notice all of the epochs
    Epoch[] public epochs;

    /// ----------- USER VARIABLES ------------

    /// @notice reward points accrued per epoch
    /// @dev epoch is zero indexed
    mapping(address user => mapping(uint256 epoch => uint256 points)) public rewardPoints;

    /// @notice total amount of ERC721 tokens staked per user
    mapping(address user => StakerInfo) public stakedUserInfo;

    /// @notice recording of ownership of ERC721 tokens staked
    mapping(uint256 tokenId => address owner) public stakedAssets;

    /// @param _core the address of Core
    /// @param _stakingToken the address of the ERC721 Contract
    constructor(address _core, address _stakingToken) CoreRef(_core) {
        stakingToken = IERC721(_stakingToken);
    }

    /// ----------- PUBLIC VIEW ONLY API ------------

    /// @notice get the total amount of epochs
    function epoch() external view returns (uint256) {
        return epochs.length;
    }

    /// @notice get the end time of the current epoch for rewards purposes
    function getCurrentTimestampOrEpochEnd() external view returns (uint256) {
        Epoch memory currentEpoch = epochs[getCurrentEpoch() - 1]; /// if no active epoch, will revert
        return
            block.timestamp > currentEpoch.epochStart + currentEpoch.epochDuration
                ? currentEpoch.epochStart + currentEpoch.epochDuration
                : block.timestamp;
    }

    /// @notice get the total rewards for a user across all epochs
    /// @param user the address of the user to get rewards for
    function getClaimedRewardsAcrossAllEpochs(address user) public view returns (uint256 rewards) {
        for (uint256 i = 0; i < epochs.length; i++) {
            /// epochs starts at 1
            rewards += rewardPoints[user][i];
        }
    }

    /// @notice get the total amount of NFT's a user has staked
    /// @param user the address of the user to get the amount staked
    function getUserAmountStaked(address user) public view returns (uint256) {
        return stakedUserInfo[user].amountStaked;
    }

    /// @notice get info on the user's staked assets and time staked
    /// @param user the address of the user to get info for
    function getStakedUserInfo(address user) public view returns (uint40 amountStaked, uint216 lastStakedTime) {
        amountStaked = stakedUserInfo[user].amountStaked;
        lastStakedTime = stakedUserInfo[user].lastStakedTime;
    }

    /// @notice get info on a given epoch
    /// @param epochNumber the epoch number to get info for
    function getEpochInfo(uint256 epochNumber) public view returns (uint200 epochStart, uint56 epochDuration) {
        epochStart = epochs[epochNumber].epochStart;
        epochDuration = epochs[epochNumber].epochDuration;
    }

    /// @notice get the total rewards for a user across all epoch
    /// @param user the address of the user to get rewards for
    /// @return totalRewards the total rewards for a user across epochs, both claimed and unclaimed
    function getTotalRewards(address user) public view returns (uint256 totalRewards) {
        /// claimed rewards
        for (uint256 i = 0; i < epochs.length; i++) {
            totalRewards += rewardPoints[user][i];
        }

        /// second is previous epoch unclaimed rewards
        totalRewards += _getAllUnclaimedRewardsPreviousEpochs(user);

        /// third is rewards from current epochs
        totalRewards += getUnclaimedRewardsCurrentEpoch(user);
    }

    /// @notice get the elapsed time for a user during this epoch
    /// @param user the address of the user to get the elapsed time for
    function getElapsedTime(address user) public view returns (uint256) {
        uint256 currentEpochIndex = getCurrentEpoch();
        if (currentEpochIndex == 0) {
            return 0;
        }

        Epoch memory currentEpoch = epochs[currentEpochIndex - 1];
        uint256 lastStakedTime = stakedUserInfo[user].lastStakedTime < currentEpoch.epochStart
            ? currentEpoch.epochStart
            : stakedUserInfo[user].lastStakedTime;
        uint256 timeElapsed = block.timestamp - lastStakedTime;

        return timeElapsed;
    }

    /// @notice get the unclaimed rewards for the current epoch
    /// @dev returns 0 if no active epoch
    /// @param user the address of the user to get the unclaimed rewards for
    function getUnclaimedRewardsCurrentEpoch(address user) public view returns (uint256) {
        uint256 timeElapsed = getElapsedTime(user);
        uint256 unclaimedPeriodRewards = _calculateRewards(timeElapsed, uint256(stakedUserInfo[user].amountStaked));

        return unclaimedPeriodRewards;
    }

    /// @notice get total unclaimed rewards for a user
    /// @param user the address of the user to get the unclaimed rewards for
    function getTotalUnclaimedRewards(address user) public view returns (uint256) {
        return _getAllUnclaimedRewardsPreviousEpochs(user);
    }

    /// @notice get the current epoch
    /// if no active epoch exists, returns 0
    function getCurrentEpoch() public view returns (uint256) {
        uint256 currentTimeStamp = block.timestamp;
        for (uint256 i = 0; i < epochs.length; i++) {
            if (
                currentTimeStamp >= epochs[i].epochStart &&
                currentTimeStamp <= epochs[i].epochStart + epochs[i].epochDuration
            ) {
                return i + 1;
            }
        }

        return 0; /// no currently active epoch
    }

    /// @notice returns true if the epoch is active
    /// @param _epoch the epoch to check
    function isActiveEpoch(uint256 _epoch) public view returns (bool) {
        if (_epoch >= epochs.length) {
            return false;
        }

        Epoch memory currentEpoch = epochs[_epoch];

        return
            block.timestamp >= currentEpoch.epochStart &&
            block.timestamp <= currentEpoch.epochStart + currentEpoch.epochDuration;
    }

    /// ----------- HELPER FUNCTIONS ------------

    /// @notice calculate the rewards for a given epoch
    /// @param timeStaked the length of the epoch
    /// @param amountStaked the amount of NFT's staked
    function _calculateRewards(uint256 timeStaked, uint256 amountStaked) private pure returns (uint256 rewards) {
        //slither-disable-next-line divide-before-multiply
        rewards = (timeStaked / REWARD_TIME) * amountStaked;
    }

    /// @notice function to catch up on the previous epochs
    /// @param user the address of the user to update
    function _getAllUnclaimedRewardsPreviousEpochs(address user) private view returns (uint256 totalRewards) {
        StakerInfo memory userInfo = stakedUserInfo[user];
        uint256 lastStakedTime = userInfo.lastStakedTime;

        for (uint256 i = 0; i < epochs.length; i++) {
            Epoch memory currentEpoch = epochs[i];

            if (!isActiveEpoch(i) && currentEpoch.epochStart <= block.timestamp) {
                /// started staking before the current epoch
                if (lastStakedTime <= currentEpoch.epochStart) {
                    totalRewards += _calculateRewards(
                        uint256(currentEpoch.epochDuration),
                        uint256(userInfo.amountStaked)
                    );
                } else if (
                    /// started staking during the epoch
                    lastStakedTime >= currentEpoch.epochStart &&
                    lastStakedTime <= currentEpoch.epochStart + currentEpoch.epochDuration
                ) {
                    /// get rewards for time staked during this epoch
                    uint256 timeAccrued = currentEpoch.epochDuration - (lastStakedTime - currentEpoch.epochStart);
                    totalRewards += _calculateRewards(timeAccrued, uint256(userInfo.amountStaked));
                }
                /// if staked after the epoch, do nothing
            }
        }
    }

    /// @notice function to catch up on the previous epochs
    /// @param user the address of the user to update
    /// @return rewardsClaimed the total amount of rewards claimed from previous epochs
    function _updatePreviousEpochs(address user) private returns (uint256 rewardsClaimed) {
        StakerInfo storage userInfo = stakedUserInfo[user];
        uint256 lastStakedTime = userInfo.lastStakedTime;
        uint256 rewardAmount;

        for (uint256 i = 0; i < epochs.length; i++) {
            /// epoch - 1 is upper bound of array
            Epoch memory currentEpoch = epochs[i];
            bool isActive = isActiveEpoch(i);
            /// epoch start check to ensure rewards payouts do not happen for future epochs
            if (!isActive && currentEpoch.epochStart <= block.timestamp) {
                /// add 1 to prevent out of bounds error
                /// before the epoch
                rewardAmount = 0;
                if (lastStakedTime <= currentEpoch.epochStart) {
                    /// user gets rewards for the entire epoch
                    rewardAmount = _calculateRewards(
                        uint256(currentEpoch.epochDuration),
                        uint256(userInfo.amountStaked)
                    );
                    rewardPoints[user][i] += rewardAmount;
                } else if (
                    /// during the epoch
                    lastStakedTime >= currentEpoch.epochStart &&
                    lastStakedTime <= currentEpoch.epochStart + currentEpoch.epochDuration
                ) {
                    /// user gets rewards for time staked during this epoch
                    uint256 timeAccrued = currentEpoch.epochDuration - (lastStakedTime - currentEpoch.epochStart);
                    rewardAmount = _calculateRewards(timeAccrued, uint256(userInfo.amountStaked));
                    rewardPoints[user][i] += rewardAmount;
                }
                rewardsClaimed += rewardAmount;

                /// all epochs being calculated are in the past, so move the pointer to epoch end time up as we go
                userInfo.lastStakedTime = currentEpoch.epochStart + currentEpoch.epochDuration;
            } else if (isActive) {
                /// break as user is now fully caught up with past epoch reward distributions
                break;
            }
        }
    }

    /// ----------- PUBLIC STATE CHANGING API ------------

    /// @notice get point rewards for staking
    /// @param user the address of the user to claim rewards for
    function updateUserReward(address user) public {
        StakerInfo storage userInfo = stakedUserInfo[user];
        uint256 currentEpochIndex = getCurrentEpoch();

        /// save gas if user has never staked
        /// or if no epoch has been set
        if (userInfo.lastStakedTime == 0 || epochs.length == 0) {
            return;
        }

        uint256 rewardsClaimed = _updatePreviousEpochs(user);

        if (currentEpochIndex == 0) {
            if (rewardsClaimed != 0) {
                emit RewardsClaimed(user, rewardsClaimed);
            }

            return; /// no active epoch
        }

        uint256 timeElapsed = getElapsedTime(user);

        uint256 unclaimedPeriodRewards = getUnclaimedRewardsCurrentEpoch(user);
        if (unclaimedPeriodRewards == 0) {
            return;
        }

        /// malicious user cannot rug rewards by claiming rewards because last staked time is properly updated
        /// so even if they call this function 1 second before the users period ends, the user just has to wait 1
        /// second like they normally would to claim their unclaimed rewards

        rewardPoints[user][currentEpochIndex - 1] += unclaimedPeriodRewards;
        userInfo.lastStakedTime = (block.timestamp - (timeElapsed % REWARD_TIME)).toUint216();

        emit RewardsClaimed(user, unclaimedPeriodRewards + rewardsClaimed);
    }

    /// @notice Stakes user's NFTs
    /// @param tokenIds The tokenIds of the NFTs which will be staked
    function stake(uint256[] memory tokenIds) external globalLock(1) whenNotPaused {
        require(tokenIds.length != 0, "Staking: No tokenIds provided");

        updateUserReward(msg.sender);

        uint256 amount = tokenIds.length;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            /// Transfer user's NFTs to the staking contract
            stakingToken.safeTransferFrom(msg.sender, address(this), tokenIds[i]);

            /// Save who is the staker of each given ERC721 token
            stakedAssets[tokenIds[i]] = msg.sender;
        }

        /// if the user doesn't call this function exactly on the hour they staked, they will lose out on rewards, this is expected behavior
        stakedUserInfo[msg.sender].lastStakedTime = block.timestamp.toUint216(); /// override setting lastStakedTime check in updateUserReward
        stakedUserInfo[msg.sender].amountStaked += amount.toUint32();

        emit Staked(msg.sender, amount, tokenIds);
    }

    /// @notice Withdraws staked user's NFTs
    /// @param tokenIds The tokenIds of the NFTs which will be withdrawn
    function unstake(uint256[] memory tokenIds) external globalLock(1) whenNotPaused {
        require(tokenIds.length != 0, "Staking: No tokenIds provided");

        updateUserReward(msg.sender);

        uint256 amount = tokenIds.length;
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            /// Check if the user who withdraws is the owner
            require(stakedAssets[tokenIds[i]] == msg.sender, "Staking: Not the staker of the token");

            /// Transfer NFTs back to the owner
            stakingToken.safeTransferFrom(address(this), msg.sender, tokenIds[i]);

            /// Cleanup stakedAssets for the current tokenId
            stakedAssets[tokenIds[i]] = address(0);
        }

        /// if the user doesn't call this function exactly on the hour they staked, they will lose out on rewards, this is expected behavior
        stakedUserInfo[msg.sender].lastStakedTime = block.timestamp.toUint216(); /// override setting lastStakedTime check in updateUserReward
        stakedUserInfo[msg.sender].amountStaked -= amount.toUint32();

        emit Withdrawn(msg.sender, amount, tokenIds);
    }

    /// ----------- ADMIN ONLY API ------------

    /// @notice create a new epoch, callable only by admin
    /// @param epochStart the start time of the epoch
    /// @param epochDuration the length of the epoch
    function createNewEpoch(uint200 epochStart, uint40 epochDuration) external onlyRole(Roles.ADMIN) {
        if (epochs.length != 0) {
            Epoch memory newestEpoch = epochs[epochs.length - 1];
            require(
                newestEpoch.epochStart + newestEpoch.epochDuration < epochStart,
                "Staking: new epoch can't start in previous epoch"
            );
        }

        epochs.push(Epoch({epochStart: epochStart, epochDuration: epochDuration}));

        emit EpochCreated(epochs.length, epochStart, epochDuration);
    }
}
