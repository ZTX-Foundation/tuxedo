// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";
import {ActualERC721Staking} from "@protocol/nfts/staking/ActualERC721Staking.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {MockERC721} from "@test/mock/MockERC721.sol";
import {BaseTest} from "@test/BaseTest.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Roles} from "@protocol/core/Roles.sol";
import "@forge-std/Test.sol";

contract UnitTestActualERC721Staking is BaseTest, ERC721Holder {
    ActualERC721Staking public staking;
    MockERC721 public stakingToken;
    uint40 public epochDuration = 60 days;

    uint256[] tokenIds = [1, 2, 3, 4, 5];

    /// @notice event emitted when a user claims rewards
    event RewardsClaimed(address indexed user, uint256 rewardAmount);

    function setUp() public override {
        super.setUp();

        stakingToken = new MockERC721();
        staking = new ActualERC721Staking(address(core), address(stakingToken));
        vm.prank(addresses.adminAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, address(staking));
        vm.warp(block.timestamp + 1); /// core assumption of contract is block.timestamp != 0
    }

    function testSetup() public {
        assertEq(address(staking.stakingToken()), address(stakingToken));
        assertEq(staking.epoch(), 0);
        assertEq(staking.REWARD_TIME(), 60 * 60);
        assertFalse(staking.isActiveEpoch(0));
        assertFalse(staking.isActiveEpoch(1));
    }

    /// ACL Suite

    function testCreateEpoch() public {
        vm.warp(block.timestamp + 100);
        vm.prank(addresses.adminAddress);
        staking.createNewEpoch(uint200(block.timestamp), epochDuration);

        (uint200 epochStart, uint56 _epochDuration) = staking.getEpochInfo(staking.epoch() - 1);

        assertEq(_epochDuration, epochDuration);
        assertEq(epochStart, uint200(block.timestamp));
    }

    function testCreateEpochNonAdminFails() public {
        vm.expectRevert("CoreRef: no role on core");
        staking.createNewEpoch(uint200(block.timestamp), epochDuration);
    }

    /// Functional Test Suite

    function testCreateNewEpochStartTimePreviousEpochFails() public {
        vm.prank(addresses.adminAddress);
        staking.createNewEpoch(uint200(block.timestamp), epochDuration);

        vm.prank(addresses.adminAddress);
        vm.expectRevert("Staking: new epoch can't start in previous epoch");
        staking.createNewEpoch(uint200(block.timestamp + epochDuration - 1), epochDuration);
    }

    function testCreateNewEpochStartTimePreviousEpochEndTimeFails() public {
        vm.prank(addresses.adminAddress);
        staking.createNewEpoch(uint200(block.timestamp), epochDuration);

        vm.prank(addresses.adminAddress);
        vm.expectRevert("Staking: new epoch can't start in previous epoch");
        staking.createNewEpoch(uint200(block.timestamp + epochDuration), epochDuration);
    }

    function testStakingNoTokenIdsFails() public {
        vm.expectRevert("Staking: No tokenIds provided");
        staking.stake(new uint256[](0));
    }

    function testUnstakingNoTokenIdsFails() public {
        vm.expectRevert("Staking: No tokenIds provided");
        staking.unstake(new uint256[](0));
    }

    function testStaking() public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            stakingToken.mint(address(this), tokenIds[i]);
        }

        stakingToken.setApprovalForAll(address(staking), true);

        staking.stake(tokenIds);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(staking.stakedAssets(tokenIds[i]), address(this));
        }

        (, uint216 lastStakedTime) = staking.getStakedUserInfo(address(this));
        assertEq(staking.getUserAmountStaked(address(this)), tokenIds.length);
        assertEq(lastStakedTime, block.timestamp);
    }

    function testUnstakingUnownedTokensFails() public {
        testStaking();

        vm.prank(addresses.userAddress);
        vm.expectRevert("Staking: Not the staker of the token");
        staking.unstake(tokenIds);
    }

    function testUnstakingDuplicateTokensFails() public {
        testStaking();
        tokenIds.push(5); /// duplicate token id

        vm.expectRevert("Staking: Not the staker of the token");
        staking.unstake(tokenIds);
    }

    function _testUnstaking() private {
        staking.unstake(tokenIds);

        assertEq(staking.stakedAssets(1), address(0));
        assertEq(staking.stakedAssets(2), address(0));
        assertEq(staking.stakedAssets(3), address(0));
        assertEq(staking.stakedAssets(4), address(0));

        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(staking.stakedAssets(tokenIds[i]), address(0));
        }

        (, uint216 lastStakedTime) = staking.getStakedUserInfo(address(this));
        assertEq(staking.getUserAmountStaked(address(this)), 0);
        assertEq(staking.rewardPoints(address(this), 1), 0);
        assertEq(lastStakedTime, block.timestamp);
    }

    function testUnstakingOwnerSucceeds() public {
        testStaking();
        _testUnstaking();
    }

    function testRewards() public {
        testCreateEpoch();
        staking.getCurrentEpoch();

        testStaking();

        staking.getCurrentEpoch();
        staking.getCurrentTimestampOrEpochEnd();

        vm.warp(block.timestamp + 1 hours);
        staking.getCurrentEpoch();
        staking.getCurrentTimestampOrEpochEnd();

        assertTrue(staking.isActiveEpoch(0));
        assertEq(staking.getClaimedRewardsAcrossAllEpochs(address(this)), 0);

        staking.updateUserReward(address(this));

        assertEq(staking.getClaimedRewardsAcrossAllEpochs(address(this)), 5);
        assertEq(staking.rewardPoints(address(this), 0), 5);
        assertEq(staking.getTotalRewards(address(this)), 5);
    }

    function testRewardsAcrossMultipleEpochs(uint8 epochs) public {
        vm.assume(epochs != 0);
        testStaking();

        for (uint256 i = 0; i < epochs; i++) {
            testCreateEpoch();
            vm.warp(block.timestamp + epochDuration * 10 + 1 hours);
        }

        assertEq(staking.epoch(), epochs);

        /// 5 staked tokens
        uint256 expectedRewards = (5 * epochDuration * epochs) / 1 hours;

        staking.updateUserReward(address(this));

        {
            (, uint216 lastStakedTime) = staking.getStakedUserInfo(address(this));
            (uint200 epochStart, uint56 _epochDuration) = staking.getEpochInfo(epochs - 1);
            assertEq(lastStakedTime, epochStart + _epochDuration);
        }

        assertEq(staking.getTotalRewards(address(this)), expectedRewards);
        assertEq(staking.getClaimedRewardsAcrossAllEpochs(address(this)), expectedRewards);
    }

    function testRewardsAcrossMultipleEpochsStakeMidEpoch() public {
        uint8 epochs = 100;

        for (uint256 i = 0; i < epochs; i++) {
            testCreateEpoch();
            /// add some time between epochs
            vm.warp(block.timestamp + epochDuration * 10 + 1 hours);
        }

        {
            /// get first epoch info
            (uint200 epochStart, ) = staking.getEpochInfo(0);
            vm.warp(epochStart + 1 hours);
        }

        testStaking();

        {
            /// get last epoch info
            (uint200 epochStart, uint56 _epochDuration) = staking.getEpochInfo(staking.epoch() - 1);
            vm.warp(epochStart + _epochDuration);
        }

        /// 5 staked tokens
        uint256 elapsedTime = epochDuration * epochs - 1 hours;
        uint256 expectedRewards = (5 * elapsedTime) / 1 hours;

        {
            /// get first epoch info
            (uint200 epochStart, ) = staking.getEpochInfo(0);
            (, uint216 lastStakedTime) = staking.getStakedUserInfo(address(this));
            assertEq(lastStakedTime, epochStart + 1 hours);
        }

        assertEq(staking.getTotalRewards(address(this)), expectedRewards);
        staking.updateUserReward(address(this));
        assertEq(staking.getTotalRewards(address(this)), expectedRewards);
        assertEq(staking.getClaimedRewardsAcrossAllEpochs(address(this)), expectedRewards);
    }

    function testRewardsAcrossMultipleEpochsStakeMidEpochFuzzy(uint8 epochs, uint256 hoursToSkip) public {
        vm.assume(epochs != 0);
        vm.assume(hoursToSkip != 0);
        hoursToSkip = _bound(hoursToSkip, 1, 255);

        for (uint256 i = 0; i < epochs; i++) {
            testCreateEpoch();
            /// add some time between epochs
            vm.warp(block.timestamp + epochDuration * 10 + 1 hours);
        }

        {
            /// get first epoch info
            (uint200 epochStart, ) = staking.getEpochInfo(0);
            vm.warp(epochStart + hoursToSkip * 1 hours);
        }

        testStaking();

        {
            /// get last epoch info
            (uint200 epochStart, uint56 _epochDuration) = staking.getEpochInfo(staking.epoch() - 1);
            vm.warp(epochStart + _epochDuration);
        }

        /// 5 staked tokens
        uint256 elapsedTime = epochDuration * epochs - hoursToSkip * 1 hours;
        uint256 expectedRewards = (5 * elapsedTime) / 1 hours;

        assertEq(staking.getTotalRewards(address(this)), expectedRewards);
        staking.updateUserReward(address(this));

        (, uint216 lastStakedTime) = staking.getStakedUserInfo(address(this));
        assertEq(staking.getTotalRewards(address(this)), expectedRewards);
        assertEq(staking.getClaimedRewardsAcrossAllEpochs(address(this)), expectedRewards);
        {
            (uint200 epochStart, uint56 _epochDuration) = staking.getEpochInfo(staking.epoch() - 1);
            assertEq(lastStakedTime, epochStart + _epochDuration);
        }
    }

    function testStakingAfterHalfEpochs(uint256 epochs, uint256 epochsToSkip, uint256 hoursToSkip) public {
        epochs = _bound(epochs, 100, 200);
        hoursToSkip = _bound(hoursToSkip, 100, 1_439); /// 60 * 24 = 1440 hours in 60 days, allow skip forward through all but the final hour in the epoch
        epochsToSkip = _bound(epochsToSkip, 50, 90);

        for (uint256 i = 0; i < epochs; i++) {
            testCreateEpoch();
            /// add some time between epochs
            vm.warp(block.timestamp + epochDuration * 10 + 1 hours);
        }

        {
            /// get first epoch info
            (uint200 epochStart, ) = staking.getEpochInfo(epochsToSkip);
            vm.warp(epochStart + hoursToSkip * 1 hours);
        }

        testStaking();

        uint256 epochsToStake = epochs - epochsToSkip;
        uint256 elapsedTime = epochDuration * epochsToStake - hoursToSkip * 1 hours;
        uint256 expectedRewards = (5 * elapsedTime) / 1 hours;

        {
            /// get last epoch info
            (uint200 epochStart, uint56 _epochDuration) = staking.getEpochInfo(staking.epoch() - 1);
            vm.warp(epochStart + _epochDuration); /// warp to the end
        }

        assertEq(staking.getTotalRewards(address(this)), expectedRewards);

        _testUnstaking();

        for (uint256 i = 0; i < epochsToSkip; i++) {
            assertEq(staking.rewardPoints(address(this), i), 0);
        }

        for (uint256 i = epochsToSkip + 1; i < epochs; i++) {
            /// start 1 past epoch that user staked
            assertEq(staking.rewardPoints(address(this), i), (epochDuration * 5) / 1 hours);
        }

        assertEq(staking.getTotalRewards(address(this)), expectedRewards);

        (, uint216 lastStakedTime) = staking.getStakedUserInfo(address(this));
        assertEq(staking.getTotalRewards(address(this)), expectedRewards);
        assertEq(staking.getClaimedRewardsAcrossAllEpochs(address(this)), expectedRewards);
        {
            (uint200 epochStart, uint56 _epochDuration) = staking.getEpochInfo(staking.epoch() - 1);
            assertEq(lastStakedTime, epochStart + _epochDuration);
        }
    }

    function testStakingAfterHalfEpochsUnstakeTMinusEpochEnd(
        uint256 epochs,
        uint256 epochsToSkip,
        uint256 hoursToSkip
    ) public {
        epochs = _bound(epochs, 100, 200);
        hoursToSkip = _bound(hoursToSkip, 100, 1_438); /// 60 * 24 = 1440 hours in 60 days, allow skip forward through all but the final hour in the epoch
        epochsToSkip = _bound(epochsToSkip, 50, 90);

        for (uint256 i = 0; i < epochs; i++) {
            testCreateEpoch();
            /// add some time between epochs
            vm.warp(block.timestamp + epochDuration * 10 + 1 hours);
        }

        {
            /// get first epoch info
            (uint200 epochStart, ) = staking.getEpochInfo(epochsToSkip);
            vm.warp(epochStart + hoursToSkip * 1 hours);
        }

        testStaking();

        uint256 epochsToStake = epochs - epochsToSkip;
        uint256 elapsedTime = epochDuration * epochsToStake - ((hoursToSkip + 1) * 1 hours);
        uint256 expectedRewards = (5 * elapsedTime) / 1 hours;

        {
            /// get last epoch info
            (uint200 epochStart, uint56 _epochDuration) = staking.getEpochInfo(staking.epoch() - 1);
            vm.warp(epochStart + _epochDuration - 1 hours); /// warp to the end - 1 hour
        }

        assertEq(staking.getTotalRewards(address(this)), expectedRewards);

        _testUnstaking(); /// assert 0 staked

        for (uint256 i = 0; i < epochsToSkip; i++) {
            assertEq(staking.rewardPoints(address(this), i), 0);
        }

        for (uint256 i = epochsToSkip + 1; i + 1 < epochs; i++) {
            /// start 1 past epoch that user staked
            assertEq(staking.rewardPoints(address(this), i), (epochDuration * 5) / 1 hours);
        }

        assertEq(staking.rewardPoints(address(this), epochs - 1), ((epochDuration - 1 hours) * 5) / 1 hours);

        assertEq(staking.getTotalRewards(address(this)), expectedRewards);

        (, uint216 lastStakedTime) = staking.getStakedUserInfo(address(this));
        assertEq(staking.getTotalRewards(address(this)), expectedRewards);
        assertEq(staking.getClaimedRewardsAcrossAllEpochs(address(this)), expectedRewards);
        {
            (uint200 epochStart, uint56 _epochDuration) = staking.getEpochInfo(staking.epoch() - 1);
            assertEq(lastStakedTime, epochStart + _epochDuration - 1 hours);
        }
    }

    function testCannotRugUserRewards() public {
        testCreateEpoch();
        testStaking();

        (, uint216 lastStakedTime) = staking.getStakedUserInfo(address(this));
        vm.warp(lastStakedTime + staking.REWARD_TIME() - 1);

        staking.updateUserReward(address(this));
        (, uint216 _lastStakedTime) = staking.getStakedUserInfo(address(this));

        assertEq(_lastStakedTime, lastStakedTime);
    }

    function testCannotRugUserRewardsAfterAlmostTwoEpochs() public {
        testCreateEpoch();
        testStaking();

        (, uint216 lastStakedTime) = staking.getStakedUserInfo(address(this));
        vm.warp(lastStakedTime + (2 * staking.REWARD_TIME()) - 1);

        staking.updateUserReward(address(this));
        (, uint216 _lastStakedTime) = staking.getStakedUserInfo(address(this));

        assertEq(_lastStakedTime, lastStakedTime + 1 hours);
        assertEq(staking.getTotalRewards(address(this)), 5);
    }

    function testCannotRugUserRewardsAfterEpoch() public {
        testCannotRugUserRewardsAfterAlmostTwoEpochs();

        vm.warp(block.timestamp + 1);
        staking.updateUserReward(address(this));
        assertEq(staking.getTotalRewards(address(this)), 10);
    }

    function testRewardsClaimedPreviousEpochs() public {
        testStaking();
        testCreateEpoch();

        (uint200 epochStart, uint56 _epochDuration) = staking.getEpochInfo(staking.epoch() - 1);
        vm.warp(epochStart + _epochDuration + 1);
        uint256 expectedUnclaimedRewards = staking.getTotalUnclaimedRewards(address(this));

        vm.expectEmit(true, false, false, true, address(staking));
        emit RewardsClaimed(address(this), expectedUnclaimedRewards);
        staking.updateUserReward(address(this));
    }

    /// Pause Suite

    /// oz pause

    function testStakePausedFails() public {
        vm.prank(addresses.adminAddress);
        staking.pause();
        vm.expectRevert("Pausable: paused");
        staking.stake(tokenIds);
    }

    function testUnstakePausedFails() public {
        vm.prank(addresses.adminAddress);
        staking.pause();
        vm.expectRevert("Pausable: paused");
        staking.unstake(tokenIds);
    }

    /// global reentrancy lock admin pause

    function testStakeGlobalPausedFails() public {
        vm.prank(addresses.adminAddress);
        lock.adminEmergencyPause();
        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        staking.stake(tokenIds);
    }

    function testUnstakeGlobalPausedFails() public {
        vm.prank(addresses.adminAddress);
        lock.adminEmergencyPause();
        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        staking.unstake(tokenIds);
    }
}
