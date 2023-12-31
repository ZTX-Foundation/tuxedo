pragma solidity 0.8.18;

import {Core} from "@protocol/core/Core.sol";
import {getCore, getRevertMessage} from "@test/fixtures/Fixtures.sol";
import {TestAddresses} from "@test/fixtures/TestAddresses.sol";
import {Roles} from "@protocol/core/Roles.sol";
import "@forge-std/Test.sol";

contract UnitTestCore is Test {
    Core public core;

    function setUp() public {
        core = getCore(vm);
    }

    function testRoleCount() public {
        assertEq(core.getRoleMemberCount(Roles.ADMIN), 1);
        assertEq(core.getRoleMemberCount(Roles.GOVERNOR_DAO_PROTOCOL_ROLE), 1);
        assertEq(core.getRoleMemberCount(Roles.GUARDIAN), 1);
        assertEq(core.getRoleMemberCount(Roles.MINTER_PROTOCOL_ROLE), 1);
        assertEq(core.getRoleMemberCount(Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE), 1);
        assertEq(core.getRoleMemberCount(Roles.LOCKER_PROTOCOL_ROLE), 1);
    }

    function testRoleMembers() public {
        assertEq(core.getRoleMember(Roles.ADMIN, 0), TestAddresses.adminAddress);
        assertEq(core.getRoleMember(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, 0), TestAddresses.tokenGovernorAddress);
        assertEq(core.getRoleMember(Roles.GUARDIAN, 0), TestAddresses.guardianAddress);
        assertEq(core.getRoleMember(Roles.MINTER_PROTOCOL_ROLE, 0), TestAddresses.minterAddress);
        assertEq(
            core.getRoleMember(Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE, 0),
            TestAddresses.financialControllerAddress
        );
        assertEq(core.getRoleMember(Roles.LOCKER_PROTOCOL_ROLE, 0), TestAddresses.lockerAddress);

        assertTrue(core.hasRole(Roles.ADMIN, TestAddresses.adminAddress));
        assertTrue(core.hasRole(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, TestAddresses.tokenGovernorAddress));
        assertTrue(core.hasRole(Roles.GUARDIAN, TestAddresses.guardianAddress));
        assertTrue(core.hasRole(Roles.MINTER_PROTOCOL_ROLE, TestAddresses.minterAddress));
        assertTrue(core.hasRole(Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE, TestAddresses.financialControllerAddress));
        assertTrue(core.hasRole(Roles.LOCKER_PROTOCOL_ROLE, TestAddresses.lockerAddress));
    }

    function testEmergencyRevoke() public {
        vm.prank(TestAddresses.guardianAddress);
        core.emergencyRevoke(Roles.MINTER_PROTOCOL_ROLE, TestAddresses.minterAddress);
        assertEq(core.getRoleMemberCount(Roles.MINTER_PROTOCOL_ROLE), 0);
    }

    function testEmergencyRevokeAdminFails() public {
        vm.prank(TestAddresses.guardianAddress);
        vm.expectRevert("Core: guardian cannot revoke admin");
        core.emergencyRevoke(Roles.ADMIN, TestAddresses.adminAddress);
        assertEq(core.getRoleMemberCount(Roles.ADMIN), 1);
    }

    function testAdminCreatesSecondAdmin() public {
        vm.prank(TestAddresses.adminAddress);
        core.createRole(Roles.ADMIN, Roles.ADMIN); /// hacky way to allow admin to create another admin

        vm.prank(TestAddresses.adminAddress);
        core.grantRole(Roles.ADMIN, TestAddresses.userAddress);

        assertEq(core.getRoleMemberCount(Roles.ADMIN), 2);
        assertTrue(core.hasRole(Roles.ADMIN, TestAddresses.userAddress));
    }

    function testAdminRevokesOtherAdmin() public {
        testAdminCreatesSecondAdmin();

        vm.prank(TestAddresses.adminAddress);
        core.revokeRole(Roles.ADMIN, TestAddresses.userAddress);

        assertEq(core.getRoleMemberCount(Roles.ADMIN), 1);
        assertTrue(core.hasRole(Roles.ADMIN, TestAddresses.adminAddress));
    }

    function testEmergencyRevokeFail() public {
        string memory errorMessage = getRevertMessage(Roles.GUARDIAN, TestAddresses.adminAddress);

        vm.prank(TestAddresses.adminAddress);
        vm.expectRevert(bytes(errorMessage));
        core.emergencyRevoke(Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE, TestAddresses.financialControllerAddress);
        assertEq(core.getRoleMemberCount(Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE), 1);
    }

    function testCreateRoleRevokeFail() public {
        bytes32 newRole = keccak256("NEW_ROLE");
        string memory errorMessage = getRevertMessage(Roles.ADMIN, TestAddresses.financialControllerAddress);

        vm.prank(TestAddresses.financialControllerAddress);
        vm.expectRevert(bytes(errorMessage));
        core.createRole(newRole, Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE);

        assertEq(core.getRoleMemberCount(newRole), 0);
    }

    function testCreateNewRoleAsAdmin() public {
        bytes32 newRole = keccak256("NEW_ROLE");

        vm.startPrank(TestAddresses.adminAddress);

        core.createRole(newRole, Roles.ADMIN);
        core.grantRole(newRole, TestAddresses.userAddress);

        vm.stopPrank();

        assertEq(core.getRoleAdmin(newRole), Roles.ADMIN);
        assertEq(core.getRoleMemberCount(newRole), 1);
        assertEq(core.hasRole(newRole, TestAddresses.userAddress), true);
    }

    function testCreateNewRoleAsAdmin(bytes32 newRole, address account) public {
        vm.assume(
            newRole != bytes32(0) &&
                newRole != Roles.ADMIN &&
                newRole != Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE &&
                newRole != Roles.GUARDIAN &&
                newRole != Roles.LOCKER_PROTOCOL_ROLE &&
                newRole != Roles.MINTER_PROTOCOL_ROLE &&
                newRole != Roles.GOVERNOR_DAO_PROTOCOL_ROLE &&
                newRole != Roles.MINTER_NOTARY_PROTOCOL_ROLE &&
                newRole != Roles.REGISTRY_OPERATOR_PROTOCOL_ROLE &&
                newRole != Roles.GAME_CONSUMER_NOTARY_PROTOCOL_ROLE
        );

        vm.startPrank(TestAddresses.adminAddress);

        core.createRole(newRole, Roles.ADMIN);
        core.grantRole(newRole, account);

        vm.stopPrank();

        assertEq(core.getRoleMemberCount(newRole), 1);
        assertTrue(core.hasRole(newRole, account));
    }

    function testSetGlobalLockAdmin(address lock) public {
        vm.startPrank(TestAddresses.adminAddress);

        core.setGlobalLock(lock);

        vm.stopPrank();

        assertEq(address(core.lock()), lock);
    }

    function testSetGlobalLockTokenGov(address lock) public {
        vm.startPrank(TestAddresses.tokenGovernorAddress);

        core.setGlobalLock(lock);

        vm.stopPrank();

        assertEq(address(core.lock()), lock);
    }

    function testSetGlobalLockFail() public {
        address lock = address(10_000);
        vm.prank(TestAddresses.financialControllerAddress);
        vm.expectRevert("Core: must be admin or token governor");
        core.setGlobalLock(lock);
    }

    function testGrantAdminFailsNonAdmin() public {
        string memory errorMessage = getRevertMessage(Roles.ADMIN, address(this));

        vm.expectRevert(bytes(errorMessage));
        core.grantRole(Roles.ADMIN, TestAddresses.userAddress);
    }

    function testGrantGovernorFailsNonAdmin() public {
        string memory errorMessage = getRevertMessage(Roles.ADMIN, address(this));

        vm.expectRevert(bytes(errorMessage));
        core.grantRole(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, TestAddresses.userAddress);
    }
}
