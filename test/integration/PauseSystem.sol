// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Test} from "@forge-std/Test.sol";

import {BasePauseSystem} from "@test/integration/BasePauseSystem.sol";

/// @title Integration tests for pausing and unpausing the system
contract IntegrationTestPauseSystem is BasePauseSystem {
    /// @notice Setup
    function setUp() public virtual override {
        super.setUp();
    }

    /// @notice Test pause
    function testPause() public {
        pause();
    }

    /// @notice Test unpause
    function testUnpause() public {
        pauseUnpause();
    }

    /// @notice Test pause with a purchase
    function testPausePurchase() public {
        pause();
        purchasePaused();
    }

    /// @notice Test pause with a bulk purchase
    function testPauseBulkPurchase() public {
        pause();
        bulkPurchasePaused();
    }

    /// @notice Test pause stake
    function testPauseStake() public {
        pause();
        _stakePaused();
    }

    /// @notice Test unpause with a purchase
    function testPauseUnpauseWithPurchase() public {
        pauseUnpause();
        vm.warp(block.timestamp + 1 days);
        purchase(1);
        purchaseWithEth(2);
    }

    /// @notice Test unpause with a bulk purchase
    function testPauseUnpauseBulkPurchase() public {
        pauseUnpause();
        vm.warp(block.timestamp + 1 days);
        bulkPurchase(1);
        bulkPurchaseWithEth(2);
    }

    /// @notice Test unpause with a purchase and a bulk purchase
    function testPauseUnpausePurchaseBulkPurchase() public {
        pauseUnpause();
        vm.warp(block.timestamp + 1 days);
        purchase(1);
        purchaseWithEth(2);
        bulkPurchase(1);
        bulkPurchaseWithEth(2);
    }

    /// @notice Test unpause with a purchase and a bulk purchase
    function testPauseUnpauseStake() public {
        pauseUnpause();
        vm.warp(block.timestamp + 1 days);
        _stake(address(1));
    }

    /// @notice Test unpause with a purchase and sweeping unclaimed fees
    function testPauseUnpausePurchaseSweepUnclaimed() public {
        pauseUnpause();
        vm.warp(block.timestamp + 1 days);
        purchase(1);
        purchaseWithEth(2);
        sweepUnclaimed(0.2e18, 0.4e18, 0.6e18);
    }

    /// @notice Test unpause with a bulk purchase and sweeping unclaimed fees
    function testPauseUnpauseBulkPurchaseSweepUnclaimed() public {
        pauseUnpause();
        vm.warp(block.timestamp + 1 days);
        bulkPurchase(1);
        bulkPurchaseWithEth(2);
        sweepUnclaimed(0.4e18, 0.8e18, 1.2e18);
    }

    /// @notice Test unpause with a purchase, then a bulk purchase and sweeping unclaimed fees
    function testPauseUnpausePurchaseBulkPurchaseSweepUnclaimed() public {
        pauseUnpause();
        vm.warp(block.timestamp + 1 days);
        purchase(1);
        purchaseWithEth(2);
        bulkPurchase(1);
        bulkPurchaseWithEth(2);
        sweepUnclaimed(0.6e18, 1.2e18, 1.8e18);
    }

    /// @notice Test unpause with a purchase, sweeping unclaimed fees, allocating fees and withdrawing fees
    function testPauseUnpausePurchaseSweepUnclaimedAllocateWithdrawFees() public {
        pauseUnpause();
        vm.warp(block.timestamp + 1 days);
        purchase(1);
        purchaseWithEth(2);
        sweepUnclaimed(0.2e18, 0.4e18, 0.6e18);
        pauseUnpause();
        allocateFees(6.0e15);
        withdrawFees(6.0e15);
    }

    /// @notice Test unpause with a bulk purchase, sweeping unclaimed fees, allocating fees and withdrawing fees
    function testPauseUnpauseBulkPurchaseSweepUnclaimedAllocateWithdrawFees() public {
        pauseUnpause();
        vm.warp(block.timestamp + 1 days);
        bulkPurchase(1);
        bulkPurchaseWithEth(2);
        sweepUnclaimed(0.4e18, 0.8e18, 1.2e18);
        pauseUnpause();
        allocateFees(1.2e16);
        withdrawFees(1.2e16);
    }

    /// @notice Test unpause with a purchase and then a bulk purchase, sweeping unclaimed fees, allocating fees
    /// and withdrawing fees
    function testPauseUnpausePurchaseBulkPurchaseSweepUnclaimedAllocateWithdrawFees() public {
        pauseUnpause();
        vm.warp(block.timestamp + 1 days);
        purchase(1);
        purchaseWithEth(2);
        bulkPurchase(1);
        bulkPurchaseWithEth(2);
        sweepUnclaimed(0.6e18, 1.2e18, 1.8e18);
        pauseUnpause();
        allocateFees(1.8e16);
        withdrawFees(1.8e16);
    }

    /// @notice Test emergency pause with a purchase
    function testEmergencyPausePurchase() public {
        emergencyPause();
        vm.roll(block.number + 1);
        purchaseInvalidLockLevel();
    }

    /// @notice Test emergency pause with a bulk purchase
    function testEmergencyPauseBulkPurchase() public {
        emergencyPause();
        vm.roll(block.number + 1);
        bulkPurchaseInvalidLockLevel();
    }

    /// @notice Test emergency pause with a purchase and then a bulk purchase
    function testEmergencyPausePurchaseBulkPurchase() public {
        emergencyPause();
        vm.roll(block.number + 1);
        purchaseInvalidLockLevel();
        bulkPurchaseInvalidLockLevel();
    }

    /// @notice Test emergency pause staking
    function testEmergencyPauseStake() public {
        emergencyPause();
        vm.roll(block.number + 1);
        _stakeInvalidLockLevel();
    }

    /// @notice Test emergency pause with a purchase
    function testEmergencyPauseRecover() public {
        emergencyPause();
        vm.roll(block.number + 1);
        purchaseInvalidLockLevel();
        emergencyRecover();
    }

    /// @notice Test emergency pause with a purchase
    function testEmergencyPauseRecoverPurchase() public {
        emergencyPause();
        vm.roll(block.number + 1);
        purchaseInvalidLockLevel();
        emergencyRecover();
        vm.warp(block.timestamp + 1 days);
        purchase(1);
        purchaseWithEth(2);
    }

    /// @notice Test emergency pause with a bulk purchase
    function testEmergencyPauseRecoverBulkPurchase() public {
        emergencyPause();
        vm.roll(block.number + 1);
        bulkPurchaseInvalidLockLevel();
        emergencyRecover();
        vm.warp(block.timestamp + 1 days);
        bulkPurchase(1);
        bulkPurchaseWithEth(2);
    }

    /// @notice Test emergency pause staking
    function testEmergencyPauseRecoverStake() public {
        emergencyPause();
        vm.roll(block.number + 1);
        _stakeInvalidLockLevel();
        emergencyRecover();
        vm.warp(block.timestamp + 1 days);
        _stake(address(1));
    }

    /// @notice Test emergency pause with a purchase and then a bulk purchase
    function testEmergencyPauseRecoverPurchaseBulkPurchase() public {
        emergencyPause();
        vm.roll(block.number + 1);
        purchaseInvalidLockLevel();
        bulkPurchaseInvalidLockLevel();
        emergencyRecover();
        vm.warp(block.timestamp + 1 days);
        purchase(1);
        purchaseWithEth(2);
        bulkPurchase(1);
        bulkPurchaseWithEth(2);
    }

    /// @notice Test emergency pause/recover with a purchase and sweeping unclaimed fees
    function testEmergencyPauseRecoverPurchaseSweepUnclaimed() public {
        emergencyPause();
        vm.roll(block.number + 1);
        purchaseInvalidLockLevel();
        emergencyRecover();
        vm.warp(block.timestamp + 1 days);
        purchase(1);
        purchaseWithEth(2);
        sweepUnclaimed(0.2e18, 0.4e18, 0.6e18);
    }

    /// @notice Test emergency pause/recover with a bulk purchase and sweeping unclaimed fees
    function testEmergencyPauseRecoverBulkPurchaseSweepUnclaimed() public {
        emergencyPause();
        vm.roll(block.number + 1);
        bulkPurchaseInvalidLockLevel();
        emergencyRecover();
        vm.warp(block.timestamp + 1 days);
        bulkPurchase(1);
        bulkPurchaseWithEth(2);
        sweepUnclaimed(0.4e18, 0.8e18, 1.2e18);
    }

    /// @notice Test emergency pause/recover with a purchase, then a bulk purchase and sweeping unclaimed fees
    function testEmergencyPauseRecoverPurchaseBulkPurchaseSweepUnclaimed() public {
        emergencyPause();
        vm.roll(block.number + 1);
        purchaseInvalidLockLevel();
        bulkPurchaseInvalidLockLevel();
        emergencyRecover();
        vm.warp(block.timestamp + 1 days);
        purchase(1);
        purchaseWithEth(2);
        bulkPurchase(1);
        bulkPurchaseWithEth(2);
        sweepUnclaimed(0.6e18, 1.2e18, 1.8e18);
    }

    /// @notice Test emergency pause/recover with a purchase, sweeping unclaimed fees, allocating fees
    /// and withdrawing fees
    function testEmergencyPauseRecoverPurchaseSweepUnclaimedAllocateWithdrawFees() public {
        emergencyPause();
        vm.roll(block.number + 1);
        purchaseInvalidLockLevel();
        emergencyRecover();
        vm.warp(block.timestamp + 1 days);
        purchase(1);
        purchaseWithEth(2);
        sweepUnclaimed(0.2e18, 0.4e18, 0.6e18);
        allocateFees(0.6e16);
        withdrawFees(0.6e16);
    }

    /// @notice Test emergency pause/recover with a purchase and then a bulk purchase, sweeping unclaimed fees,
    /// allocating fees and withdrawing fees
    function testEmergencyPauseRecoverPurchaseBulkPurchaseSweepUnclaimedAllocateWithdrawFees() public {
        emergencyPause();
        vm.roll(block.number + 1);
        purchaseInvalidLockLevel();
        bulkPurchaseInvalidLockLevel();
        emergencyRecover();
        vm.warp(block.timestamp + 1 days);
        purchase(1);
        purchaseWithEth(2);
        bulkPurchase(1);
        bulkPurchaseWithEth(2);
        sweepUnclaimed(0.6e18, 1.2e18, 1.8e18);
        allocateFees(1.8e16);
        withdrawFees(1.8e16);
    }
}
