pragma solidity 0.8.18;

import {Core} from "@protocol/core/Core.sol";
import {getCore, getRevertMessage} from "@test/fixtures/Fixtures.sol";
import {MockCoreRef} from "@test/mock/MockCoreRef.sol";
import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";
import {Roles} from "@protocol/core/Roles.sol";

import "@forge-std/Test.sol";

contract CoreRefTest is Test {
    Core private core;
    MockCoreRef private coreRef;

    event CoreUpdate(address indexed oldCore, address indexed newCore);

    function setUp() public {
        core = getCore(vm);

        coreRef = new MockCoreRef(address(core));

        vm.label(address(core), "Core");
        vm.label(address(coreRef), "CoreRef");
    }

    function testSetup() public {
        assertEq(address(coreRef.core()), address(core));
    }

    function testMinter(address caller) public {
        vm.assume(caller != address(0));

        vm.startPrank(caller);

        if (!core.hasRole(Roles.MINTER, caller)) {
            vm.expectRevert("CoreRef: no role on core");
        }
        coreRef.testMinter();
        vm.stopPrank();
    }

    function testAdmin(address caller) public {
        vm.assume(caller != address(0));

        vm.startPrank(caller);

        if (!core.hasRole(Roles.ADMIN, caller)) {
            vm.expectRevert("CoreRef: no role on core");
        }
        coreRef.testAdmin();
        vm.stopPrank();
    }

    function testSetCoreGovSucceeds() public {
        Core core2 = getCore(vm);
        vm.prank(addresses.adminAddress);

        vm.expectEmit(true, true, false, true, address(coreRef));
        emit CoreUpdate(address(core), address(core2));

        coreRef.setCore(address(core2));

        assertEq(address(coreRef.core()), address(core2));
    }

    function testSetCoreAddressZeroGovSucceedsBricksContract() public {
        vm.prank(addresses.adminAddress);
        vm.expectEmit(true, true, false, true, address(coreRef));
        emit CoreUpdate(address(core), address(0));

        coreRef.setCore(address(0));

        assertEq(address(coreRef.core()), address(0));

        /// all calls made to Core fail because it is calling address 0
        vm.expectRevert();
        coreRef.testMinter();

        vm.expectRevert();
        coreRef.testTokenGovernor();

        vm.expectRevert();
        coreRef.testGuardian();
    }

    function testSetCoreToAddress0GovSucceeds() public {
        vm.prank(addresses.adminAddress);

        vm.expectEmit(true, true, false, true, address(coreRef));
        emit CoreUpdate(address(core), address(0));

        coreRef.setCore(address(0));

        assertEq(address(coreRef.core()), address(0));

        vm.prank(addresses.tokenGovernorAddress);
        vm.expectRevert();
        coreRef.setCore(address(core));
    }

    function testSetCoreNonGovFails() public {
        vm.expectRevert("CoreRef: no role on core");
        coreRef.setCore(address(0));

        assertEq(address(coreRef.core()), address(core));
    }

    function testMinterAsMinter() public {
        vm.prank(addresses.minterAddress);
        coreRef.testMinter();
    }

    function testFinancialControllerAsFinancialController() public {
        vm.prank(addresses.financialControllerAddress);
        coreRef.testFinancialController();
    }

    function testFinancialController(address caller) public {
        if (!core.hasRole(Roles.FINANCIAL_CONTROLLER, caller)) {
            vm.expectRevert("CoreRef: no role on core");
        }
        vm.prank(caller);
        coreRef.testFinancialController();
    }

    function testFinancialGuardian(address caller) public {
        if (!core.hasRole(Roles.FINANCIAL_GUARDIAN, caller)) {
            vm.expectRevert("CoreRef: no role on core");
        }
        vm.prank(caller);
        coreRef.testFinancialGuardian();
    }

    function testGuardianAsGuardian() public {
        vm.prank(addresses.guardianAddress);
        coreRef.testGuardian();
    }

    function testLocker() public {
        vm.expectRevert("CoreRef: no role on core");
        coreRef.testLocker();
    }

    function testLockerAsLocker() public {
        vm.prank(addresses.lockerAddress);
        coreRef.testLocker();
    }

    function testTokenGovernor(address caller) public {
        if (!core.hasRole(Roles.TOKEN_GOVERNOR, caller)) {
            vm.expectRevert("CoreRef: no role on core");
        }
        vm.prank(caller);
        coreRef.testTokenGovernor();
    }

    function testGuardian(address caller) public {
        if (!core.hasRole(Roles.GUARDIAN, caller)) {
            vm.expectRevert("CoreRef: no role on core");
        }

        vm.prank(caller);
        coreRef.testGuardian();
    }

    /// ---------- ACL ----------

    function testPauseSucceedsGovernor() public {
        assertTrue(!coreRef.paused());
        vm.prank(addresses.tokenGovernorAddress);
        coreRef.pause();
        assertTrue(coreRef.paused());
    }

    function testPauseFailsNonGovernor() public {
        vm.expectRevert("CoreRef: no role on core");
        coreRef.pause();
    }

    function testEmergencyActionSucceedsAdminSendEth(uint128 sendAmount) public {
        uint256 startingEthBalance = address(this).balance;

        MockCoreRef.Call[] memory calls = new MockCoreRef.Call[](1);
        calls[0].target = address(this);
        calls[0].value = sendAmount;
        vm.deal(address(coreRef), sendAmount);

        vm.prank(addresses.adminAddress);
        coreRef.emergencyAction(calls);

        uint256 endingEthBalance = address(this).balance;

        assertEq(endingEthBalance - startingEthBalance, sendAmount);
        assertEq(address(coreRef).balance, 0);
    }

    function testEmergencyActionFailsNonAdmin() public {
        MockCoreRef.Call[] memory calls = new MockCoreRef.Call[](1);
        calls[0].target = address(this);
        calls[0].value = 0;

        vm.expectRevert("CoreRef: no role on core");
        coreRef.emergencyAction(calls);
    }

    receive() external payable {}
}
