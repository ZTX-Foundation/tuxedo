pragma solidity 0.8.18;

import "@forge-std/Test.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {MockERC20} from "@test/mock/MockERC20.sol";
import {ERC20Splitter} from "@protocol/finance/ERC20Splitter.sol";
import {MockERC20, IERC20} from "@test/mock/MockERC20.sol";

import {getCore} from "@test/fixtures/Fixtures.sol";
import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";

contract UnitTestERC20HoldingsDeposit is Test {
    Core private core;

    ERC20Splitter private splitter;

    /// @notice token to deposit
    MockERC20 private token;

    address depositOne = address(10000);

    address depositTwo = address(20000);

    function setUp() public {
        core = getCore(vm);
        token = new MockERC20();

        ERC20Splitter.Allocation[] memory allocations = new ERC20Splitter.Allocation[](2);
        allocations[0].deposit = depositOne;
        allocations[0].ratio = 4_000;
        allocations[1].deposit = depositTwo;
        allocations[1].ratio = 6_000;

        splitter = new ERC20Splitter(
            address(core),
            address(token),
            allocations
        );
    }

    function testSetup() public {
        assertEq(address(splitter.token()), address(token));

        ERC20Splitter.Allocation memory firstAllocation = splitter.getAllocationAt(0);
        ERC20Splitter.Allocation memory secondAllocation = splitter.getAllocationAt(1);

        assertEq(firstAllocation.deposit, depositOne);
        assertEq(secondAllocation.deposit, depositTwo);

        assertEq(firstAllocation.ratio, 4_000);
        assertEq(secondAllocation.ratio, 6_000);

        assertEq(splitter.getNumberOfAllocations(), 2);
    }

    function testDirectArrayGetCall() public {
        {
            (address deposit, uint16 ratio) = splitter.allocations(0);
    
            assertEq(deposit, depositOne);
            assertEq(ratio, 4_000);
        }
        {
            (address deposit, uint16 ratio) = splitter.allocations(1);
    
            assertEq(deposit, depositTwo);
            assertEq(ratio, 6_000);
        }
    }

    function testAllocateFailsRatiosNotZero() public {
        ERC20Splitter.Allocation[] memory allocations = new ERC20Splitter.Allocation[](2);
        allocations[0].deposit = depositOne;
        allocations[0].ratio = 4_000;
        allocations[1].deposit = depositTwo;
        allocations[1].ratio = 5_000; // Not equal to 10_000 as a total

        vm.expectRevert("ERC20Splitter: ratios not 100%");
        splitter.checkAllocation(allocations);
    }

    function testCheckAllocationSucceeds() public view {
        ERC20Splitter.Allocation[] memory allocations = new ERC20Splitter.Allocation[](2);

        allocations[0].deposit = depositOne;
        allocations[0].ratio = 4_000;

        allocations[1].deposit = depositTwo;
        allocations[1].ratio = 6_000;

        splitter.checkAllocation(allocations);
    }

    function testGetAllocation() public {
        ERC20Splitter.Allocation[] memory allocations = splitter.getAllocations();
        assertEq(allocations[0].deposit, depositOne);
        assertEq(allocations[1].deposit, depositTwo);

        assertEq(allocations[0].ratio, 4_000);
        assertEq(allocations[1].ratio, 6_000);
    }

    function testAllocate() public {
        uint256 tokenAmount = 10_000_000e18;
        token.mint(address(splitter), tokenAmount);

        assertEq(token.balanceOf(address(splitter)), tokenAmount);
        assertEq(token.balanceOf(depositOne), 0);
        assertEq(token.balanceOf(depositTwo), 0);

        splitter.allocate();

        assertEq(token.balanceOf(address(splitter)), 0);
        assertEq(token.balanceOf(depositOne), tokenAmount * 4_000 / 10_000);
        assertEq(token.balanceOf(depositTwo), tokenAmount * 6_000 / 10_000);
    }

    function testSetAllocationAdminSucceeds() public {
        ERC20Splitter.Allocation[] memory allocations = new ERC20Splitter.Allocation[](2);

        allocations[0].deposit = depositOne;
        allocations[0].ratio = 5_000;

        allocations[1].deposit = depositTwo;
        allocations[1].ratio = 5_000;

        vm.prank(addresses.adminAddress);
        splitter.setAllocation(allocations);

        assertEq(splitter.getAllocationAt(0).deposit, depositOne);
        assertEq(splitter.getAllocationAt(1).deposit, depositTwo);
        assertEq(splitter.getAllocationAt(0).ratio, 5_000);
        assertEq(splitter.getAllocationAt(1).ratio, 5_000);

        assertEq(splitter.getNumberOfAllocations(), 2);
    }

    function testSetAllocationNonAdminFails() public {
        ERC20Splitter.Allocation[] memory allocations = new ERC20Splitter.Allocation[](2);

        vm.expectRevert("CoreRef: no role on core");
        splitter.setAllocation(allocations);
    }

    function testSplitterSucceedsNotOriginalToken() public {
        uint256 tokenAmount = 100e18;
        MockERC20 newToken = new MockERC20();
        newToken.mint(address(splitter), tokenAmount);

        splitter.allocate(address(newToken));

        assertEq(newToken.balanceOf(depositOne), tokenAmount * 4 / 10);
        assertEq(newToken.balanceOf(depositTwo), tokenAmount * 6 / 10);
    }
}
