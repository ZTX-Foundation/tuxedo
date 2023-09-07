# ActualERC721Staking Contract Documentation

The `ActualERC721Staking` contract facilitates staking of ERC721 tokens, enabling users to earn non-transferable reward points based on their stake's duration within an active epoch. These reward points are disbursed per epoch and users can claim their rewards at any point, even if a new epoch has commenced. The admin can create new epochs.

Rewards are calculated using the formula: `user_time_staked * amount_staked / 1_hour` where `user_time_staked` signifies the time a user has staked within an epoch.

## Public State Variables

- `stakingToken`: Represents the ERC721 token eligible for staking.
- `epochs`: Contains all the epochs in the form of an `Epoch` struct array.
- `rewardPoints`: Indicates the reward points earned per epoch, which is zero-indexed.
- `stakedUserInfo`: Stores the total amount of ERC721 tokens staked per user, as well as the last staked time, mapped from user address to `StakerInfo` struct.
- `stakedAssets`: Maintains a record of ownership of staked ERC721 tokens, mapped from tokenId to owner's address.

## Structs

- `Epoch`: Holds information about the epoch's start time and duration.
- `StakerInfo`: Contains details about the user's staked assets and the last instance when the user staked.

## Functions

**Public View Functions**

- `epoch()`: Returns total epochs.
- `getCurrentTimestampOrEpochEnd()`: Returns the current epoch's end time.
- `getClaimedRewardsAcrossAllEpochs(user)`: Returns the total rewards claimed by a user across all epochs.
- `getUserAmountStaked(user)`: Returns the total amount of NFTs staked by a user.
- `getStakedUserInfo(user)`: Returns details about the user's staked assets and the last staking instance.
- `getEpochInfo(epochNumber)`: Returns information about a specific epoch.
- `getTotalRewards(user)`: Returns the total rewards earned by a user across all epochs, both claimed and unclaimed.
- `getElapsedTime(user)`: Returns the elapsed time for a user in the current epoch.
- `getUnclaimedRewardsCurrentEpoch(user)`: Returns the unclaimed rewards of a user in the current epoch.
- `getTotalUnclaimedRewards(user)`: Returns the total unclaimed rewards of a user across all epochs.
- `getCurrentEpoch()`: Returns the current epoch number. Returns 0 if no active epoch exists.
- `isActiveEpoch(epoch)`: Returns `true` if the provided epoch is active.

**Public State Changing Functions**

- `updateUserReward(user)`: Updates the user's reward points.
- `stake(tokenIds)`: Allows a user to stake NFTs.
- `unstake(tokenIds)`: Permits a user to withdraw staked NFTs.

## Events

- `Staked`: Emitted when a user stakes NFTs.
- `Unstaked`: Emitted when a user unstakes NFTs.
- `RewardsClaimed`: Emitted when a user claims rewards.
- `EpochCreated`: Emitted when a new epoch is created.

## Assumptions & Edge Cases

1. The contract assumes that the number of staked tokens by a user does not exceed the maximum limit of a `uint32`.
2. If a user stakes for less than an hour, they receive no rewards.
3. The `unstake()` function will revert if any token id provided by the user is not currently staked by them.
4. The `updateUserReward(address user)` function has no effect, yet consumes gas, if a user has not staked any NFTs.
5. The `stake()` and `unstake()` transactions will revert if the contract is paused.
6. The admin emergency pause on the global lock can prevent staking and unstaking during emergencies. This can potentially lock users ERC721's up.
7. If a user stakes at time `t` and then unstakes at time `t + 1 hour and 59mins and 59 seconds`, then they will lose out on rewards from the second hour and only receive 1 point per NFT staked in the first hour. This is expected behvaior.
8. If a user stakes at time `t` and then stakes additional ERC721 tokens at time `t + 1 hour and 59mins and 59 seconds`, then they will lose out on rewards from the second hour and only receive 1 point per NFT staked in the first hour. This is expected behvaior.

## Security Considerations

1. The contract should be secure from reentrancy attacks and audited thoroughly, given it deals with valuable NFT transfers and rewards.
2. It is crucial that the contract's owner or any centralised authority cannot manipulate the users' funds, stakes, or rewards.
3. Only the admin role should be able to invoke the contract's sensitive functions, such as `createEpoch()`.
4. Changes in the contract's logic due to upgrades or optimisations should not impact the epochs and rewards, and should be communicated transparently to users.
5. The contract should have mechanisms to address potential bugs or vulnerabilities, such as a pausing mechanism or upgradability feature. In dire situations, the admin can use the emergencyAction function to move ERC721s.
