// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Test} from "@forge-std/Test.sol";

import {MockERC721} from "@test/mock/MockERC721.sol";
import {BaseTest} from "@test/integration/BaseTest.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {ActualERC721Staking} from "@protocol/nfts/staking/ActualERC721Staking.sol";

/// @title Integration test for GovernorDAO
contract IntegrationTestActualERC721Staking is BaseTest {
    /// @dev Mock ERC721
    MockERC721 stakingToken;

    /// @dev ERC721 staking
    ActualERC721Staking staking;

    /// @dev Token IDs
    uint256[] tokenIds;

    /// @dev Epoc duration
    uint40 public epochDuration = 60 days;

    /// @notice Setup
    function setUp() public virtual override {
        super.setUp();

        stakingToken = new MockERC721();
        stakingToken.mint(address(1), 1);

        staking = new ActualERC721Staking(addresses.getAddress("CORE"), address(stakingToken));

        vm.startPrank(addresses.getAddress("ADMIN_MULTISIG"));
        Core(addresses.getAddress("CORE")).grantRole(Roles.LOCKER, address(staking));
        vm.stopPrank();
        vm.warp(block.timestamp + 1);

        /// @dev Create new epoch
        _createEpoch();

        tokenIds = new uint256[](1);
        tokenIds[0] = 1;
    }

    /// @notice Stake
    function _stake(address user) private {
        vm.startPrank(user);
        stakingToken.setApprovalForAll(address(staking), true);
        staking.stake(tokenIds);
        vm.stopPrank();
    }

    /// @notice Stake with no token ID
    function _stakeNoTokenId() private {
        vm.startPrank(address(1));
        stakingToken.setApprovalForAll(address(staking), true);
        vm.expectRevert("Staking: No tokenIds provided");
        staking.stake(new uint256[](0));
        vm.stopPrank();
    }

    /// @notice Unstake
    function _unstake(address user) private {
        vm.prank(user);
        staking.unstake(tokenIds);
    }

    /// @notice Unstake wrong owner
    function _unstakeWrongOwner(address user) private {
        vm.prank(user);
        vm.expectRevert("Staking: Not the staker of the token");
        staking.unstake(tokenIds);
    }

    /// @notice Unstake with no token ID
    function _unstakeNoTokenId(address user) private {
        vm.startPrank(user);
        vm.expectRevert("Staking: No tokenIds provided");
        staking.unstake(new uint256[](0));
        vm.stopPrank();
    }

    /// @notice Staked assets
    function _stakedAssets(uint256 tokenId, address user) private {
        assertEq(staking.stakedAssets(tokenId), user);
    }

    /// @notice User amount staked
    function _userAmountStaked(uint256 amount, address user) private {
        (, uint216 lastStakedTime) = staking.getStakedUserInfo(user);
        assertEq(lastStakedTime, block.timestamp);
        assertEq(staking.getUserAmountStaked(user), amount);
    }

    /// @notice Create epoch
    function _createEpoch() private {
        vm.warp(block.timestamp + 100);
        vm.prank(addresses.getAddress("ADMIN_MULTISIG"));
        staking.createNewEpoch(uint200(block.timestamp), epochDuration);

        (uint200 epochStart, uint56 _epochDuration) = staking.getEpochInfo(staking.epoch() - 1);

        assertEq(_epochDuration, epochDuration);
        assertEq(epochStart, uint200(block.timestamp));
    }

    /// @notice Rewards across multiple epochs
    function _rewardsMultipleEpochs(address user) private {
        vm.warp(block.timestamp + 1 hours);
        assertTrue(staking.isActiveEpoch(0));
        assertEq(staking.getClaimedRewardsAcrossAllEpochs(user), 0);

        staking.updateUserReward(user);
        assertEq(staking.getClaimedRewardsAcrossAllEpochs(user), 1);

        assertEq(staking.rewardPoints(user, 0), 1);
        assertEq(staking.getTotalRewards(user), 1);

        vm.warp(block.timestamp + epochDuration + 1 hours);
        _createEpoch();

        assertTrue(staking.isActiveEpoch(1));
        assertEq(staking.getClaimedRewardsAcrossAllEpochs(user), 1);

        /// @dev 1440 = epochDuration * 1 hour
        staking.updateUserReward(user);
        assertEq(staking.getClaimedRewardsAcrossAllEpochs(user), 1440);

        assertEq(staking.rewardPoints(user, 1), 0);
        assertEq(staking.getTotalRewards(user), 1440);
    }

    /// @notice Test stake
    function testStake() public {
        _stake(address(1));
        _stakedAssets(1, address(1));
        _userAmountStaked(1, address(1));
    }

    /// @notice Test staking with no Token Id
    function testStakeNoTokenId() public {
        _stakeNoTokenId();
    }

    /// @notice Test stake and then unstake
    function testStakeUnstake() public {
        _stake(address(1));
        _stakedAssets(1, address(1));
        _userAmountStaked(1, address(1));
        _unstake(address(1));
        /// @dev Because it'll return a zero address
        _stakedAssets(1, address(0));
        _userAmountStaked(0, address(1));
    }

    /// @notice Test staking with no Token Id
    function testUnstakeNoTokenId() public {
        _unstakeNoTokenId(address(1));
    }

    /// @notice Test stake and then unstake with wrong owner
    function testStakeUnstakeWrongOwner() public {
        _stake(address(1));
        _unstakeWrongOwner(address(2));
    }

    /// @notice Test stake rewards
    function testStakeRewards() public {
        _stake(address(1));
        vm.warp(block.timestamp + 1 hours);

        assertTrue(staking.isActiveEpoch(0));
        assertEq(staking.getClaimedRewardsAcrossAllEpochs(address(1)), 0);

        staking.updateUserReward(address(1));
        assertEq(staking.getClaimedRewardsAcrossAllEpochs(address(1)), 1);
        assertEq(staking.rewardPoints(address(1), 1), 0);
        assertEq(staking.getTotalRewards(address(1)), 1);
    }

    /// @notice Test stake and rewards across multiple epochs
    function testStakeRewardsMultipleEpochs() public {
        _stake(address(1));
        _rewardsMultipleEpochs(address(1));
    }

    /// @notice Test stake and rewards across multiple epochs
    function testStakeRewardsMultipleEpochsUnstake() public {
        _stake(address(1));
        _rewardsMultipleEpochs(address(1));
        _unstake(address(1));
        _userAmountStaked(0, address(1));
    }

    /// @notice Test stake and claiming rewards for the previous epoch
    function testStakeClaimRewardsPreviousEpoch() public {
        _stake(address(1));
        vm.warp(block.timestamp + epochDuration);
        _createEpoch();

        assertTrue(staking.isActiveEpoch(1));
        assertEq(staking.getTotalUnclaimedRewards(address(1)), 1440);
        staking.updateUserReward(address(1));
    }

    /// @notice Test stake and claiming rewards for the previous epoch, and unstaking
    function testStakeClaimRewardsPreviousEpochUnstake() public {
        _stake(address(1));
        vm.warp(block.timestamp + epochDuration);
        _createEpoch();

        assertTrue(staking.isActiveEpoch(1));
        assertEq(staking.getTotalUnclaimedRewards(address(1)), 1440);
        staking.updateUserReward(address(1));

        _unstake(address(1));
        _userAmountStaked(0, address(1));
    }
}
