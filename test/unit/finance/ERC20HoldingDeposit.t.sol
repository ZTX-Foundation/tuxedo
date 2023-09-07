pragma solidity 0.8.18;

import "@forge-std/Test.sol";

import {Core} from "@protocol/core/Core.sol";
import {MockERC20} from "@test/mock/MockERC20.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {MockERC20, IERC20} from "@test/mock/MockERC20.sol";
import {ERC20HoldingDeposit} from "@protocol/finance/ERC20HoldingDeposit.sol";
import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";
import {getCore} from "@test/fixtures/Fixtures.sol";

contract UnitTestERC20HoldingsDeposit is Test {
    event Deposit(address indexed _from, uint256 _amount);

    Core private core;

    ERC20HoldingDeposit private erc20HoldingDeposit;

    /// @notice token to deposit
    MockERC20 private token;

    function setUp() public {
        core = getCore(vm);
        token = new MockERC20();

        erc20HoldingDeposit = new ERC20HoldingDeposit(address(core), address(token));
    }

    function testSetup() public {
        assertEq(token.balanceOf(address(erc20HoldingDeposit)), erc20HoldingDeposit.balance());
        assertEq(address(erc20HoldingDeposit.core()), address(core));
        assertEq(address(erc20HoldingDeposit.token()), address(token));
        assertEq(address(erc20HoldingDeposit.balanceReportedIn()), address(erc20HoldingDeposit.token()));
    }

    function testWithdrawSucceeds() public {
        uint256 tokenAmount = 10_000_000e18;
        token.mint(address(erc20HoldingDeposit), tokenAmount);

        assertEq(token.balanceOf(address(erc20HoldingDeposit)), tokenAmount);
        assertEq(token.balanceOf(address(this)), 0);

        vm.prank(addresses.financialControllerAddress);
        erc20HoldingDeposit.withdraw(address(this), tokenAmount);

        assertEq(token.balanceOf(address(this)), tokenAmount);
        assertEq(token.balanceOf(address(erc20HoldingDeposit)), 0);
    }

    function testWithdrawERC20Succeeds() public {
        uint256 tokenAmount = 10_000_000e18;
        token.mint(address(erc20HoldingDeposit), tokenAmount);

        assertEq(token.balanceOf(address(erc20HoldingDeposit)), tokenAmount);
        assertEq(token.balanceOf(address(this)), 0);

        vm.prank(addresses.financialControllerAddress);
        erc20HoldingDeposit.withdrawERC20(address(token), address(this), tokenAmount);

        assertEq(token.balanceOf(address(this)), tokenAmount);
        assertEq(token.balanceOf(address(erc20HoldingDeposit)), 0);
    }

    function testWithdrawERC20FailsNonFinancalController() public {
        vm.expectRevert("CoreRef: no role on core");
        erc20HoldingDeposit.withdrawERC20(address(token), address(this), 0);
    }

    function testWithdrawFailsNonFinancalController() public {
        vm.expectRevert("CoreRef: no role on core");
        erc20HoldingDeposit.withdraw(address(this), 10);
    }
}
