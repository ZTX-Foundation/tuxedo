// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {getCore} from "@test/fixtures/Fixtures.sol";
import {BaseTest} from "@test/BaseTest.sol";
import {MockERC20} from "@test/mock/MockERC20.sol";
import {MockDeposit} from "@test/mock/MockDeposit.sol";
import {FinanceGuardian} from "@protocol/finance/FinanceGuardian.sol";
import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";
import {IGlobalReentrancyLock, GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";

contract UnitTestFinanceGuardian is BaseTest {
    event SafeAddressUpdated(address indexed oldSafeAddress, address indexed newSafeAddress);

    MockDeposit public deposit;

    address[] public whitelistAddresses;

    uint256 public mintAmount = 10_000_000;

    function setUp() public override {
        super.setUp();

        deposit = new MockDeposit(address(core), address(token), 0);

        vm.startPrank(addresses.adminAddress);
        core.grantRole(Roles.LOCKER, address(deposit));
        guardian.addWhitelistAddress(address(deposit));
        token.mint(address(deposit), mintAmount);
        vm.stopPrank();

        whitelistAddresses.push(address(deposit));
    }

    function testConstructNewFinanceGuardianWithWhitelistOnConstruction() public {
        FinanceGuardian newGuardian = new FinanceGuardian(address(core), addresses.safeAddress, whitelistAddresses);

        assertEq(address(newGuardian.safeAddress()), addresses.safeAddress);
        assertEq(newGuardian.getWhitelistedAddresses().length, 1);
        assertEq(newGuardian.getWhitelistedAddresses()[0], address(deposit));
        assertTrue(newGuardian.isWhitelistedAddress(address(deposit)));
    }

    function testGetWhitelistAddresses() public {
        address[] memory guardianWhitelistAddresses = guardian.getWhitelistedAddresses();
        assertEq(1, guardianWhitelistAddresses.length);
        assertEq(whitelistAddresses[0], guardianWhitelistAddresses[0]);
    }

    function testGuardianRoles() public {
        assertTrue(core.hasRole(Roles.LOCKER, address(deposit)));
        assertTrue(core.hasRole(Roles.LOCKER, address(guardian)));
        assertTrue(core.hasRole(Roles.GUARDIAN, address(guardian)));
        assertTrue(core.hasRole(Roles.FINANCIAL_CONTROLLER, address(guardian)));
    }

    function testPausedAfterWithdrawToSafeAddress() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        deposit.pause();
        assertEq(token.balanceOf(address(this)), 0);

        guardian.withdrawToSafeAddress(address(deposit), mintAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(addresses.safeAddress), mintAmount);
        assertTrue(deposit.paused());
    }

    function testWithdrawToSafeAddress() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        assertEq(token.balanceOf(address(this)), 0);

        guardian.withdrawToSafeAddress(address(deposit), mintAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(addresses.safeAddress), mintAmount);
    }

    function testGuardianWithdrawToSafeAddress() public {
        vm.startPrank(addresses.guardianAddress);
        assertEq(token.balanceOf(address(this)), 0);

        guardian.withdrawToSafeAddress(address(deposit), mintAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(addresses.safeAddress), mintAmount);
    }

    function testGuardWithdrawToSafeAddress() public {
        vm.startPrank(addresses.guardianAddress);
        assertEq(token.balanceOf(address(this)), 0);

        guardian.withdrawToSafeAddress(address(deposit), mintAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(addresses.safeAddress), mintAmount);
    }

    function testFinancialGuardianWithdrawToSafeAddress() public {
        vm.startPrank(addresses.financialGuardianAddress);
        assertEq(token.balanceOf(address(this)), 0);

        guardian.withdrawToSafeAddress(address(deposit), mintAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(addresses.safeAddress), mintAmount);
    }

    function testFinancialGuardWithdrawToSafeAddress() public {
        assertEq(token.balanceOf(address(this)), 0);

        vm.prank(addresses.financialGuardianAddress);
        guardian.withdrawToSafeAddress(address(deposit), mintAmount);

        assertEq(token.balanceOf(addresses.safeAddress), mintAmount);
    }

    function testWithdrawToSafeAddressFailWhenNoRole() public {
        vm.expectRevert("CoreRef: no role on core");
        guardian.withdrawToSafeAddress(address(deposit), mintAmount);
    }

    function testWithdrawToSafeAddressFailWhenGuardRevokedGovernor() public {
        vm.prank(addresses.adminAddress);
        core.revokeRole(Roles.FINANCIAL_GUARDIAN, addresses.financialGuardianAddress);

        vm.prank(addresses.financialGuardianAddress);
        vm.expectRevert("CoreRef: no role on core");

        guardian.withdrawToSafeAddress(address(deposit), mintAmount);
    }

    function testWithdrawToSafeAddressFailWhenGuardRevokedGuardian() public {
        vm.prank(addresses.adminAddress);
        core.revokeRole(Roles.FINANCIAL_GUARDIAN, addresses.financialGuardianAddress);

        vm.prank(addresses.financialGuardianAddress);
        vm.expectRevert("CoreRef: no role on core");

        guardian.withdrawToSafeAddress(address(deposit), mintAmount);
    }

    function testWithdrawToSafeAddressFailWhenNotWhitelist() public {
        vm.prank(addresses.tokenGovernorAddress);
        vm.expectRevert("WhitelistedAddress: Provided address is not whitelisted");

        guardian.withdrawToSafeAddress(address(0x1), mintAmount);
    }

    function testPausedAfterWithdrawAllToSafeAddress() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        deposit.pause();
        assertEq(token.balanceOf(address(this)), 0);

        uint256 amountToWithdraw = deposit.balance();
        guardian.withdrawAllToSafeAddress(address(deposit));
        vm.stopPrank();

        assertEq(token.balanceOf(addresses.safeAddress), amountToWithdraw);
        assertTrue(deposit.paused());
    }

    function testWithdrawAllToSafeAddress() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        assertEq(token.balanceOf(address(this)), 0);

        uint256 amountToWithdraw = deposit.balance();
        guardian.withdrawAllToSafeAddress(address(deposit));
        vm.stopPrank();

        assertEq(token.balanceOf(addresses.safeAddress), amountToWithdraw);
    }

    function testGuardWithdrawAllToSafeAddress() public {
        vm.startPrank(addresses.guardianAddress);
        assertEq(token.balanceOf(address(this)), 0);

        uint256 amountToWithdraw = deposit.balance();
        guardian.withdrawAllToSafeAddress(address(deposit));
        vm.stopPrank();

        assertEq(token.balanceOf(addresses.safeAddress), amountToWithdraw);
    }

    function testGuardianWithdrawAllToSafeAddress() public {
        vm.startPrank(addresses.guardianAddress);
        assertEq(token.balanceOf(address(this)), 0);

        uint256 amountToWithdraw = deposit.balance();
        guardian.withdrawAllToSafeAddress(address(deposit));
        vm.stopPrank();

        assertEq(token.balanceOf(addresses.safeAddress), amountToWithdraw);
    }

    function testWithdrawAllToSafeAddressFailWhenNoRole() public {
        vm.expectRevert("CoreRef: no role on core");
        guardian.withdrawAllToSafeAddress(address(deposit));
    }

    function testWithdrawAllToSafeAddressFailWhenGuardRevokedGovernor() public {
        vm.prank(addresses.adminAddress);
        core.revokeRole(Roles.FINANCIAL_GUARDIAN, addresses.financialGuardianAddress);

        vm.prank(addresses.financialGuardianAddress);
        vm.expectRevert("CoreRef: no role on core");

        guardian.withdrawAllToSafeAddress(address(deposit));
    }

    function testWithdrawAllToSafeAddressFailWhenGuardRevokedGuardian() public {
        vm.prank(addresses.adminAddress);
        core.revokeRole(Roles.FINANCIAL_GUARDIAN, addresses.financialGuardianAddress);

        vm.prank(addresses.financialGuardianAddress);
        vm.expectRevert("CoreRef: no role on core");

        guardian.withdrawAllToSafeAddress(address(deposit));
    }

    function testWithdrawAlloSafeAddressFailWhenNotWhitelist() public {
        vm.prank(addresses.tokenGovernorAddress);
        vm.expectRevert("WhitelistedAddress: Provided address is not whitelisted");

        guardian.withdrawAllToSafeAddress(address(0x1));
    }

    function testGovernorWithdrawERC20ToSafeAddress() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        assertEq(token.balanceOf(address(this)), 0);

        guardian.withdrawERC20ToSafeAddress(address(deposit), address(token), mintAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(addresses.safeAddress), mintAmount);
    }

    function testGuardianWithdrawERC20ToSafeAddress() public {
        vm.startPrank(addresses.guardianAddress);
        assertEq(token.balanceOf(address(this)), 0);

        guardian.withdrawERC20ToSafeAddress(address(deposit), address(token), mintAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(addresses.safeAddress), mintAmount);
    }

    function testGuardWithdrawERC20ToSafeAddress() public {
        vm.startPrank(addresses.financialGuardianAddress);
        assertEq(token.balanceOf(address(this)), 0);

        guardian.withdrawERC20ToSafeAddress(address(deposit), address(token), mintAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(addresses.safeAddress), mintAmount);
    }

    function testWithdrawERC20ToSafeAddressFailWhenNoRole() public {
        vm.expectRevert("CoreRef: no role on core");
        guardian.withdrawERC20ToSafeAddress(address(deposit), address(token), mintAmount);
    }

    function testWithdrawERC20ToSafeAddressFailWhenGuardRevokedGovernor() public {
        vm.prank(addresses.adminAddress);
        core.revokeRole(Roles.FINANCIAL_GUARDIAN, addresses.financialGuardianAddress);

        vm.prank(addresses.financialGuardianAddress);
        vm.expectRevert("CoreRef: no role on core");

        guardian.withdrawERC20ToSafeAddress(address(deposit), address(token), mintAmount);
    }

    function testWithdrawERC20ToSafeAddressFailWhenGuardRevokedGuardian() public {
        vm.prank(addresses.guardianAddress);
        core.emergencyRevoke(Roles.FINANCIAL_GUARDIAN, addresses.financialGuardianAddress);

        vm.prank(addresses.financialGuardianAddress);
        vm.expectRevert("CoreRef: no role on core");

        guardian.withdrawERC20ToSafeAddress(address(deposit), address(token), mintAmount);
    }

    function testWithdrawERC20oSafeAddressFailWhenNotWhitelist() public {
        vm.prank(addresses.tokenGovernorAddress);
        vm.expectRevert("WhitelistedAddress: Provided address is not whitelisted");

        guardian.withdrawERC20ToSafeAddress(address(0x1), address(token), mintAmount);
    }

    function testGovernorWithdrawAllERC20ToSafeAddress() public {
        vm.startPrank(addresses.tokenGovernorAddress);
        assertEq(token.balanceOf(address(this)), 0);

        guardian.withdrawAllERC20ToSafeAddress(address(deposit), address(token));
        vm.stopPrank();

        assertEq(token.balanceOf(addresses.safeAddress), mintAmount);
    }

    function testGuardianWithdrawAllERC20ToSafeAddress() public {
        assertEq(token.balanceOf(address(this)), 0);

        uint256 tokenAmount = token.balanceOf(address(deposit));

        vm.prank(addresses.guardianAddress);
        guardian.withdrawAllERC20ToSafeAddress(address(deposit), address(token));

        assertEq(token.balanceOf(addresses.safeAddress), tokenAmount);
    }

    function testGuardWithdrawAllERC20ToSafeAddress() public {
        assertEq(token.balanceOf(address(this)), 0);

        vm.prank(addresses.guardianAddress);
        guardian.withdrawAllERC20ToSafeAddress(address(deposit), address(token));

        assertEq(token.balanceOf(addresses.safeAddress), mintAmount);
    }

    function testWithdrawAllERC20ToSafeAddressFailWhenNoRole() public {
        vm.expectRevert("CoreRef: no role on core");
        guardian.withdrawAllERC20ToSafeAddress(address(deposit), address(token));
    }

    function testRemoveWhitelistAddressFailsNonGovernor() public {
        vm.expectRevert("CoreRef: no role on core");
        guardian.removeWhitelistAddress(addresses.tokenGovernorAddress);
    }

    function testRemoveWhitelistAddressesFailsNonGovernor() public {
        address[] memory addressesToRemove = new address[](1);
        addressesToRemove[0] = address(deposit);

        vm.expectRevert("CoreRef: no role on core");
        guardian.removeWhitelistAddresses(addressesToRemove);
    }

    function testWithdrawAllERC20ToSafeAddressFailWhenGuardRevokedGovernor() public {
        vm.prank(addresses.adminAddress);
        core.revokeRole(Roles.FINANCIAL_GUARDIAN, addresses.financialGuardianAddress);

        vm.prank(addresses.financialGuardianAddress);
        vm.expectRevert("CoreRef: no role on core");

        guardian.withdrawAllERC20ToSafeAddress(address(deposit), address(token));
    }

    function testWithdrawAllERC20ToSafeAddressFailWhenGuardRevokedGuardian() public {
        vm.prank(addresses.adminAddress);
        core.revokeRole(Roles.FINANCIAL_GUARDIAN, addresses.financialGuardianAddress);

        vm.prank(addresses.financialGuardianAddress);
        vm.expectRevert("CoreRef: no role on core");

        guardian.withdrawAllERC20ToSafeAddress(address(deposit), address(token));
    }

    function testWithdrawAllERC20ToSafeAddressFailWhenNotWhitelist() public {
        vm.prank(addresses.tokenGovernorAddress);
        vm.expectRevert("WhitelistedAddress: Provided address is not whitelisted");

        guardian.withdrawAllERC20ToSafeAddress(address(0x1), address(token));
    }

    function testAddWhiteListAddress() public {
        assertFalse(guardian.isWhitelistedAddress(address(0x123)));

        vm.prank(addresses.tokenGovernorAddress);
        guardian.addWhitelistAddress(address(0x123));
        assertTrue(guardian.isWhitelistedAddress(address(0x123)));
    }

    function testAddWhiteListAddressDupFails() public {
        testAddWhiteListAddress();

        vm.expectRevert("WhitelistedAddress: Failed to add address to whitelist");
        vm.prank(addresses.tokenGovernorAddress);
        guardian.addWhitelistAddress(address(0x123));
    }

    function testRemoveWhiteListAddressNonExistentFails() public {
        vm.expectRevert("WhitelistedAddress: Failed to remove address from whitelist");
        vm.prank(addresses.tokenGovernorAddress);
        guardian.removeWhitelistAddress(address(0x123));
    }

    function testRemoveWhiteListAddressesNonExistentFails() public {
        address[] memory toRemove = new address[](1);
        toRemove[0] = address(0x123);

        vm.expectRevert("WhitelistedAddress: Failed to remove address from whitelist");
        vm.prank(addresses.tokenGovernorAddress);
        guardian.removeWhitelistAddresses(toRemove);
    }

    function testAddWhiteListAddressNonGovernorFails() public {
        vm.expectRevert("CoreRef: no role on core");
        guardian.addWhitelistAddress(address(0x123));
    }

    function testAddWhiteListAddressesNonGovernorFails() public {
        address[] memory toWhitelist = new address[](1);
        vm.expectRevert("CoreRef: no role on core");
        guardian.addWhitelistAddresses(toWhitelist);
    }

    function testAddWhiteListAddressesGovernorSucceeds(address newDeposit) public {
        vm.assume(!guardian.isWhitelistedAddress(newDeposit));

        address[] memory toWhitelist = new address[](1);
        toWhitelist[0] = newDeposit;
        vm.prank(addresses.tokenGovernorAddress);
        guardian.addWhitelistAddresses(toWhitelist);
        assertTrue(guardian.isWhitelistedAddress(newDeposit));
    }

    function testRemoveWhiteListAddress() public {
        vm.prank(addresses.tokenGovernorAddress);

        guardian.removeWhitelistAddress(address(deposit));
        assertTrue(!guardian.isWhitelistedAddress(address(deposit)));
    }

    function testRemoveWhiteListAddresses() public {
        address[] memory toRemove = new address[](1);
        toRemove[0] = address(deposit);

        vm.prank(addresses.tokenGovernorAddress);

        guardian.removeWhitelistAddresses(toRemove);
        assertTrue(!guardian.isWhitelistedAddress(address(deposit)));
    }

    function testRemoveWhiteListAddressesFailsNoRole() public {
        address[] memory toRemove = new address[](1);
        toRemove[0] = address(deposit);

        vm.expectRevert("CoreRef: no role on core");
        guardian.removeWhitelistAddresses(toRemove);
    }

    function testSetSafeAddressNonGovernorFails() public {
        vm.expectRevert("CoreRef: no role on core");
        guardian.setSafeAddress(address(0));
    }

    function testSetSafeAddressGovernorSucceeds() public {
        vm.expectEmit(true, true, false, true, address(guardian));
        emit SafeAddressUpdated(addresses.safeAddress, address(0x1));
        vm.prank(addresses.adminAddress);
        guardian.setSafeAddress(address(0x1));
        assertEq(guardian.safeAddress(), address(0x1));
    }
}
