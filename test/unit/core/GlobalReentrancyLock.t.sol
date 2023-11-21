// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Core} from "@protocol/core/Core.sol";
import {getCore} from "@test/fixtures/Fixtures.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {MockReentrancyLock} from "@test/mock/MockReentrancyLock.sol";
import {MockReentrancyLockFailure} from "@test/mock/MockReentrancyLockFailure.sol";
import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";
import {IGlobalReentrancyLock, GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";

import "@forge-std/Test.sol";

contract UnitTestGlobalReentrancyLock is Test {
    /// @notice emitted when governor does an emergency lock
    event EmergencyLock(address indexed sender, uint256 timestamp);

    Core private core;
    address public constant locker = address(10);

    MockReentrancyLock private testLock;
    GlobalReentrancyLock lock;

    function setUp() public {
        // Deploy Core from token Governor address
        vm.startPrank(addresses.tokenGovernorAddress);
        core = new Core();
        testLock = new MockReentrancyLock(address(core));
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, address(testLock));
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, locker);
        lock = new GlobalReentrancyLock(address(core));
        core.setGlobalLock(address(lock));

        vm.stopPrank();
    }

    function testSetup() public {
        assertTrue(core.hasRole(Roles.ADMIN, addresses.tokenGovernorAddress)); /// msg.sender of contract is admin

        assertTrue(lock.isUnlocked()); /// core starts out unlocked
        assertTrue(!lock.isLocked()); /// core starts out not locked
        assertEq(lock.lastSender(), address(0));
        assertEq(lock.lastBlockEntered(), 0);

        assertTrue(core.hasRole(Roles.LOCKER_PROTOCOL_ROLE, address(testLock)));
    }

    function testLockFailsWithoutRole() public {
        vm.prank(addresses.tokenGovernorAddress);
        core.revokeRole(Roles.LOCKER_PROTOCOL_ROLE, address(testLock));
        assertTrue(!core.hasRole(Roles.LOCKER_PROTOCOL_ROLE, address(testLock)));

        vm.expectRevert("CoreRef: no role on core");

        testLock.testGlobalLock();

        assertTrue(lock.isUnlocked());
        assertTrue(!lock.isLocked());
    }

    function testLockFailsWithoutRoleRevokeGlobalLocker() public {
        vm.prank(addresses.tokenGovernorAddress);
        core.revokeRole(Roles.LOCKER_PROTOCOL_ROLE, address(testLock));
        assertTrue(!core.hasRole(Roles.LOCKER_PROTOCOL_ROLE, address(testLock)));

        vm.expectRevert("CoreRef: no role on core");

        testLock.testGlobalLock();

        assertTrue(lock.isUnlocked());
        assertTrue(!lock.isLocked());
    }

    function testLockSucceedsWithRoleL1(uint8 numRuns) public {
        for (uint256 i = 0; i < numRuns; i++) {
            assertTrue(lock.isUnlocked());
            assertTrue(!lock.isLocked());
            assertEq(testLock.lastBlockNumber(), lock.lastBlockEntered());

            testLock.testGlobalLock();

            assertTrue(lock.isUnlocked());
            assertTrue(!lock.isLocked());
            assertEq(lock.lockLevel(), 0);
            assertEq(testLock.lastBlockNumber(), lock.lastBlockEntered());
            assertEq(lock.lastSender(), address(testLock));
        }
    }

    function testLockSucceedsWithRole(uint8 numRuns) public {
        for (uint256 i = 0; i < numRuns; i++) {
            assertTrue(lock.isUnlocked());
            assertTrue(!lock.isLocked());

            address toPrank = address(uint160(i > 7 ? 7 : i));
            if (!core.hasRole(Roles.LOCKER_PROTOCOL_ROLE, toPrank)) {
                vm.prank(addresses.tokenGovernorAddress);
                core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, toPrank);
            }

            vm.prank(toPrank);
            lock.lock(1);

            assertTrue(lock.isLocked());
            assertTrue(!lock.isUnlocked());
            assertEq(lock.lockLevel(), 1);
            assertEq(lock.lastBlockEntered(), block.number);
            assertEq(toPrank, lock.lastSender());

            vm.prank(toPrank);
            lock.unlock(0);

            assertEq(lock.lockLevel(), 0);
            assertTrue(lock.isUnlocked());
            assertTrue(!lock.isLocked());
            assertEq(toPrank, lock.lastSender());

            vm.roll(block.number + 1);
        }
    }

    function testLockLevel2SucceedsWithRole(uint8 numRuns) public {
        for (uint256 i = 0; i < numRuns; i++) {
            assertTrue(lock.isUnlocked());
            assertTrue(!lock.isLocked());

            address toPrank = address(uint160(i > 7 ? 7 : i));
            if (!core.hasRole(Roles.LOCKER_PROTOCOL_ROLE, toPrank)) {
                vm.prank(addresses.tokenGovernorAddress);
                core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, toPrank);
            }

            vm.prank(toPrank);
            lock.lock(1);

            vm.prank(locker);
            lock.lock(2);

            assertEq(lock.lockLevel(), 2);
            assertEq(lock.lastBlockEntered(), block.number);
            assertEq(toPrank, lock.lastSender());

            vm.prank(locker);
            lock.unlock(1);

            vm.prank(toPrank);
            lock.unlock(0);

            assertEq(lock.lockLevel(), 0);
            assertTrue(lock.isUnlocked());
            assertTrue(!lock.isLocked());
            assertEq(toPrank, lock.lastSender());
            vm.roll(block.number + 1);
        }
    }

    function testLockLevel1And2SucceedsWithRole(uint8 numRuns) public {
        /// level
        for (uint256 i = 0; i < numRuns; i++) {
            assertTrue(lock.isUnlocked());
            assertTrue(!lock.isLocked());
            assertEq(lock.lockLevel(), 0);

            address toPrank = address(uint160(i > 7 ? 7 : i));
            if (!core.hasRole(Roles.LOCKER_PROTOCOL_ROLE, toPrank)) {
                vm.prank(addresses.tokenGovernorAddress);
                core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, toPrank);
            }

            vm.prank(toPrank);
            lock.lock(1);

            assertEq(lock.lockLevel(), 1);
            assertEq(lock.lastBlockEntered(), block.number);
            assertEq(toPrank, lock.lastSender());

            vm.prank(locker);
            lock.lock(2);

            assertTrue(lock.isLocked());
            assertEq(lock.lockLevel(), 2);

            assertEq(lock.lastBlockEntered(), block.number);
            assertEq(toPrank, lock.lastSender());

            vm.prank(locker);
            lock.unlock(1);

            assertEq(lock.lockLevel(), 1);
            assertTrue(!lock.isUnlocked());
            assertTrue(lock.isLocked());
            assertEq(toPrank, lock.lastSender());

            assertEq(toPrank, lock.lastSender());
            vm.prank(toPrank);
            lock.unlock(0);

            assertTrue(!lock.isLocked());
            assertEq(lock.lockLevel(), 0);
            assertTrue(lock.isUnlocked()); /// core is fully unlocked
            assertEq(toPrank, lock.lastSender());

            vm.roll(block.number + 1);
        }
    }

    /// create a separate contract,
    /// call globalReentrancyFails on that contract,
    /// which calls globalLock on the MockReentrancyLock contract,
    /// MockReentrancyLock fails because the system has already been entered globally
    function testLockStopsReentrancy() public {
        MockReentrancyLockFailure lock2 = new MockReentrancyLockFailure(address(core), address(testLock));
        vm.prank(addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, address(lock2));

        /// CoreRef modifier globalLock enforces level
        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        lock2.globalReentrancyFails();

        assertTrue(lock.isUnlocked());
        assertTrue(!lock.isLocked());
        assertEq(testLock.lastBlockNumber(), lock.lastBlockEntered());
    }

    function testGovernorSystemRecoveryFailsNotEntered() public {
        vm.prank(addresses.tokenGovernorAddress);
        vm.expectRevert("GlobalReentrancyLock: governor recovery, system not entered");
        lock.adminEmergencyRecover();
    }

    function testGovernorEmergencyPauseSucceeds() public {
        vm.expectEmit(true, false, false, true, address(lock));
        emit EmergencyLock(addresses.tokenGovernorAddress, block.timestamp);

        vm.prank(addresses.tokenGovernorAddress);
        lock.adminEmergencyPause();

        assertTrue(lock.isLocked());
        assertEq(lock.lockLevel(), 2);
    }

    function testGovernorEmergencyRecoversFromEmergencyPause() public {
        testGovernorEmergencyPauseSucceeds();

        vm.prank(addresses.tokenGovernorAddress);
        lock.adminEmergencyRecover();

        assertTrue(!lock.isLocked());
        assertEq(lock.lockLevel(), 0);
    }

    function testGovernorSystemRecovery() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress);

        lock.lock(1);

        assertTrue(lock.isLocked());
        assertTrue(!lock.isUnlocked());
        assertEq(lock.lockLevel(), 1);
        assertEq(lock.lastBlockEntered(), block.number);

        vm.expectRevert("GlobalReentrancyLock: cannot unlock in same block as lock");
        lock.adminEmergencyRecover();

        vm.roll(block.number + 1);
        lock.adminEmergencyRecover();

        assertTrue(!lock.isLocked());
        assertTrue(lock.isUnlocked());
        assertTrue(lock.lastBlockEntered() != block.number);
        assertEq(lock.lockLevel(), 0);

        vm.stopPrank();
    }

    function testGovernorSystemRecoveryLevelTwoLocked() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress);
        lock.lock(1);
        vm.stopPrank();

        vm.prank(locker);
        lock.lock(2);

        assertEq(lock.lockLevel(), 2);
        assertTrue(lock.isLocked());
        assertTrue(!lock.isUnlocked());
        assertEq(lock.lastBlockEntered(), block.number);

        vm.startPrank(addresses.tokenGovernorAddress);
        vm.expectRevert("GlobalReentrancyLock: cannot unlock in same block as lock");
        lock.adminEmergencyRecover();

        vm.roll(block.number + 1);
        lock.adminEmergencyRecover();

        vm.stopPrank();

        assertTrue(!lock.isLocked());
        assertTrue(lock.isUnlocked());
        assertEq(lock.lockLevel(), 0);
        assertTrue(lock.lastBlockEntered() != block.number);
    }

    function testGovernorSystemRecoveryLevelTwoAndLevelOneLocked() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress);
        lock.lock(1);
        vm.stopPrank();

        vm.prank(locker);
        lock.lock(2);

        assertTrue(lock.isLocked());
        assertTrue(!lock.isUnlocked());

        assertEq(lock.lockLevel(), 2);
        assertEq(lock.lastBlockEntered(), block.number);

        vm.startPrank(addresses.tokenGovernorAddress);

        vm.expectRevert("GlobalReentrancyLock: cannot unlock in same block as lock");
        lock.adminEmergencyRecover();
        vm.roll(block.number + 1);
        lock.adminEmergencyRecover();

        vm.stopPrank();

        assertTrue(!lock.isLocked());
        assertTrue(lock.isUnlocked());
        assertEq(lock.lockLevel(), 0);
        assertTrue(lock.lastBlockEntered() != block.number);
    }

    function testOnlySameLockerCanUnlock() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress);

        lock.lock(1);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, address(this));

        vm.stopPrank();

        assertTrue(core.hasRole(Roles.LOCKER_PROTOCOL_ROLE, address(this)));
        assertTrue(lock.isLocked());
        assertTrue(!lock.isUnlocked());
        assertEq(lock.lastBlockEntered(), block.number);
        assertEq(lock.lastSender(), addresses.tokenGovernorAddress);

        vm.expectRevert("GlobalReentrancyLock: caller is not locker");
        lock.unlock(0);

        vm.prank(addresses.tokenGovernorAddress);
        lock.unlock(0);

        assertTrue(!lock.isLocked());
        assertTrue(lock.isUnlocked());
        assertTrue(lock.lastBlockEntered() == block.number);
        assertEq(lock.lastSender(), addresses.tokenGovernorAddress);
    }

    function testOnlySameLockerCanUnlockLevelTwo() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress);
        lock.lock(1);
        vm.stopPrank();

        vm.prank(locker);
        lock.lock(2);

        assertTrue(core.hasRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress));

        assertEq(lock.lockLevel(), 2);

        assertTrue(lock.isLocked());
        assertTrue(!lock.isUnlocked());

        assertEq(lock.lastBlockEntered(), block.number);
        assertEq(lock.lastSender(), addresses.tokenGovernorAddress);

        vm.expectRevert("CoreRef: no role on core");
        lock.unlock(0);
    }

    function testInvalidStateReverts() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, address(this));
        lock.lock(1);
        vm.stopPrank();

        lock.lock(2);

        assertTrue(core.hasRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress));
        assertTrue(core.hasRole(Roles.LOCKER_PROTOCOL_ROLE, address(this)));

        assertEq(lock.lockLevel(), 2);

        assertTrue(lock.isLocked());
        assertTrue(!lock.isUnlocked());

        assertEq(lock.lastBlockEntered(), block.number);
        assertEq(lock.lastSender(), addresses.tokenGovernorAddress);

        vm.expectRevert("GlobalReentrancyLock: unlock level must be 1 lower");
        lock.unlock(0);
    }

    function testLockingLevelTwoWhileLevelOneLockedDoesntSetSender() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, address(this));

        lock.lock(1);
        assertEq(lock.lockLevel(), 1);
        vm.stopPrank();

        lock.lock(2);

        assertEq(lock.lockLevel(), 2);

        assertTrue(lock.isLocked());
        assertTrue(!lock.isUnlocked());

        assertEq(lock.lastBlockEntered(), block.number);
        assertEq(lock.lastSender(), addresses.tokenGovernorAddress);
    }

    function testUnlockingLevelOneWhileLevelTwoLockedFails() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, address(this));
        vm.stopPrank();

        lock.lock(1);
        assertEq(lock.lockLevel(), 1);

        vm.prank(locker);
        lock.lock(2);
        assertEq(lock.lockLevel(), 2);

        vm.expectRevert("GlobalReentrancyLock: unlock level must be 1 lower");
        lock.unlock(0);

        assertEq(lock.lockLevel(), 2);
        assertTrue(lock.isLocked());
        assertTrue(!lock.isUnlocked());
        assertEq(lock.lastBlockEntered(), block.number);
        assertEq(lock.lastSender(), address(this));
    }

    function testCannotLockLevel2WhileLevelNotLocked() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress);

        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        lock.lock(2);

        vm.stopPrank();

        assertTrue(!lock.isLocked());
        assertTrue(lock.isUnlocked());
    }

    function testCannotLockLevel2WhileLevel1LockedPreviousBlock() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress);

        lock.lock(1);
        vm.roll(block.number + 1);
        vm.expectRevert("GlobalReentrancyLock: system not entered this block");
        lock.lock(2);

        assertTrue(lock.isLocked());
        assertTrue(!lock.isUnlocked());
        assertTrue(lock.lastBlockEntered() == block.number - 1);
        assertEq(lock.lastSender(), addresses.tokenGovernorAddress);

        vm.stopPrank();
    }

    function testCannotLockLevel2WhileLevel2Locked() public {
        vm.prank(addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress);

        vm.prank(addresses.tokenGovernorAddress);
        lock.lock(1);

        vm.prank(locker);
        lock.lock(2);

        vm.prank(locker);
        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        lock.lock(2);

        assertEq(lock.lockLevel(), 2);
        assertTrue(lock.isLocked());
        assertTrue(!lock.isUnlocked());
        assertTrue(lock.lastBlockEntered() == block.number);
        assertEq(lock.lastSender(), addresses.tokenGovernorAddress);
    }

    function testCannotLockLevel3() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress);

        lock.lock(1);
        vm.stopPrank();

        vm.startPrank(locker);
        lock.lock(2);

        vm.expectRevert("GlobalReentrancyLock: exceeds lock state");
        lock.lock(3);
        vm.stopPrank();

        assertEq(lock.lockLevel(), 2);
        assertTrue(lock.isLocked());
        assertTrue(!lock.isUnlocked());
        assertEq(lock.lastSender(), addresses.tokenGovernorAddress);
    }

    function testUnlockFailsSystemNotEntered() public {
        vm.startPrank(addresses.tokenGovernorAddress);

        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress);
        lock.lock(1);
        lock.unlock(0);
        vm.expectRevert("GlobalReentrancyLock: system not entered");
        lock.unlock(1);
        vm.roll(block.number + 1);
        vm.expectRevert("GlobalReentrancyLock: not entered this block");
        lock.unlock(0);

        vm.stopPrank();
    }

    function testUnlockFailsSystemNotEnteredBlockAdvanced() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress);
        lock.lock(1);
        lock.unlock(0);
        vm.roll(block.number + 1);
        vm.expectRevert("GlobalReentrancyLock: not entered this block");
        lock.unlock(0);
    }

    function testUnlockLevelTwoFailsSystemEnteredLevelOne() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress);
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress);
        lock.lock(1);
        vm.expectRevert("GlobalReentrancyLock: unlock level must be 1 lower");
        lock.unlock(2);
        vm.expectRevert("GlobalReentrancyLock: unlock level must be 1 lower");
        lock.unlock(1);
        vm.stopPrank();
    }

    function testUnlockLevel2FailsSystemNotEnteredBlockAdvanced() public {
        vm.startPrank(addresses.tokenGovernorAddress);

        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, addresses.tokenGovernorAddress);
        lock.lock(1);
        vm.stopPrank();

        vm.prank(locker);
        lock.lock(2);

        assertEq(lock.lockLevel(), 2);
        assertTrue(lock.isLocked());
        assertTrue(!lock.isUnlocked());
        assertEq(lock.lastSender(), addresses.tokenGovernorAddress);

        vm.prank(locker);
        lock.unlock(1);

        vm.prank(addresses.tokenGovernorAddress);
        lock.unlock(0);

        assertEq(lock.lockLevel(), 0);
        assertTrue(!lock.isLocked());
        assertTrue(lock.isUnlocked());
        assertEq(lock.lastSender(), addresses.tokenGovernorAddress);

        vm.roll(block.number + 1);
        vm.prank(addresses.tokenGovernorAddress);
        vm.expectRevert("GlobalReentrancyLock: not entered this block");
        lock.unlock(2);
    }

    function testLockLevel2SameLevel1SenderFails() public {
        vm.startPrank(locker);
        lock.lock(1);
        vm.expectRevert("GlobalReentrancyLock: reentrant");
        lock.lock(2);
        vm.stopPrank();
    }

    function testUnlockLevel2SameLevel1SenderFails() public {
        vm.prank(locker);
        lock.lock(1);
        
        vm.prank(address(testLock));
        lock.lock(2);
        
        vm.expectRevert("GlobalReentrancyLock: reentrant");
        vm.prank(locker);
        lock.unlock(1);
    }

    /// ---------- ACL Tests ----------

    function testUnlockFailsNonStateRole() public {
        vm.expectRevert("CoreRef: no role on core");
        lock.unlock(1);
    }

    function testLockFailsNonStateRole() public {
        vm.expectRevert("CoreRef: no role on core");
        lock.lock(1);
    }

    function testGovernorSystemRecoveryFailsNotGovernor() public {
        vm.expectRevert("CoreRef: no role on core");
        lock.adminEmergencyRecover();
    }

    function testGovernorEmergencyPauseFailsNotGovernor() public {
        vm.expectRevert("CoreRef: no role on core");
        lock.adminEmergencyPause();
    }
}
