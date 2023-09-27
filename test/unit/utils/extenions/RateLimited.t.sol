pragma solidity 0.8.18;

import "@forge-std/Test.sol";

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {Core} from "@protocol/core/Core.sol";
import {MockRateLimited} from "@test/mock/MockRateLimited.sol";
import {getCore} from "@test/fixtures/Fixtures.sol";

import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";

contract UnitTestRateLimited is Test {
    using SafeCast for *;

    /// @notice event emitted when buffer cap is updated
    event BufferCapUpdate(uint256 oldBufferCap, uint256 newBufferCap);

    /// @notice event emitted when replenish rate per second is updated
    event ReplenishRatePerSecondUpdate(uint256 oldReplenishRatePerSecond, uint256 newRateReplenishPerSecond);

    /// @notice event emitted when buffer gets eaten into
    event BufferUsed(uint256 amountUsed, uint256 bufferRemaining);

    /// @notice rate limited v2 contract
    MockRateLimited rlm;

    /// @notice reference to core
    Core private core;

    /// @notice rate limit per second in RateLimited
    uint128 private constant replenishRatePerSecond = 10_000e18;

    /// @notice buffer cap in RateLimitedV2
    uint128 private constant bufferCap = 10_000_000e18;

    function setUp() public {
        core = getCore(vm);
        rlm = new MockRateLimited(address(core), replenishRatePerSecond, bufferCap);
    }

    function testSetup() public {
        assertEq(rlm.bufferCap(), bufferCap);
        assertEq(rlm.replenishRatePerSecond(), replenishRatePerSecond);
        assertEq(rlm.buffer(), bufferCap); /// buffer has not been depleted
    }

    /// ACL Tests

    function testSetBufferCapNoAuthFails() public {
        vm.expectRevert("CoreRef: no role on core");
        rlm.setBufferCap(0);
    }

    function testSetBufferCapGovSucceeds() public {
        uint256 newBufferCap = 100_000e18;

        vm.prank(addresses.tokenGovernorAddress);
        vm.expectEmit(true, false, false, true, address(rlm));
        emit BufferCapUpdate(bufferCap, newBufferCap);
        rlm.setBufferCap(newBufferCap.toUint128());

        assertEq(rlm.bufferCap(), newBufferCap);
        assertEq(rlm.buffer(), newBufferCap); /// buffer has not been depleted
    }

    function testSetBufferCapAdminSucceeds() public {
        uint256 newBufferCap = 100_000e18;

        vm.prank(addresses.adminAddress);
        vm.expectEmit(true, false, false, true, address(rlm));
        emit BufferCapUpdate(bufferCap, newBufferCap);
        rlm.setBufferCap(newBufferCap.toUint128());

        assertEq(rlm.bufferCap(), newBufferCap);
        assertEq(rlm.buffer(), newBufferCap); /// buffer has not been depleted
    }

    function testSetRateLimitPerSecondNoAuthedFails() public {
        vm.expectRevert("CoreRef: no role on core");
        rlm.setReplenishRatePerSecond(0);
    }

    function testSetReplenishRatePerSecondGovSuccess() public {
        vm.prank(addresses.tokenGovernorAddress);
        rlm.setReplenishRatePerSecond(replenishRatePerSecond + 1);
        assertEq(rlm.replenishRatePerSecond(), replenishRatePerSecond + 1);
    }

    function testSetReplenishRatePerSecondAdminSuccess() public {
        vm.prank(addresses.adminAddress);
        rlm.setReplenishRatePerSecond(replenishRatePerSecond + 1);
        assertEq(rlm.replenishRatePerSecond(), replenishRatePerSecond + 1);
    }

    function testDepleteBufferFailsWhenZeroBuffer() public {
        rlm.depleteBuffer(bufferCap);
        vm.expectRevert("RateLimited: no rate limit buffer");
        rlm.depleteBuffer(bufferCap);
    }

    function testSetReplenishRatePerSecondGovSucess() public {
        uint256 newReplenishRatePerSecond = 15_000e18;

        vm.prank(addresses.tokenGovernorAddress);
        vm.expectEmit(true, false, false, true, address(rlm));
        emit ReplenishRatePerSecondUpdate(replenishRatePerSecond, newReplenishRatePerSecond);
        rlm.setReplenishRatePerSecond(newReplenishRatePerSecond.toUint128());

        assertEq(rlm.replenishRatePerSecond(), newReplenishRatePerSecond);
    }

    function testSetReplenishRatePerSecondAdminSucess() public {
        uint256 newReplenishRatePerSecond = 15_000e18;

        vm.prank(addresses.adminAddress);
        vm.expectEmit(true, false, false, true, address(rlm));
        emit ReplenishRatePerSecondUpdate(replenishRatePerSecond, newReplenishRatePerSecond);
        rlm.setReplenishRatePerSecond(newReplenishRatePerSecond.toUint128());

        assertEq(rlm.replenishRatePerSecond(), newReplenishRatePerSecond);
    }

    function testDepleteBufferFuzzy(uint256 depleteAmount) public {
        depleteAmount = bound(depleteAmount, 1, bufferCap);

        vm.expectEmit(true, false, false, true, address(rlm));
        emit BufferUsed(depleteAmount, bufferCap - depleteAmount);

        rlm.depleteBuffer(depleteAmount);

        uint256 endingBuffer = rlm.buffer();
        assertEq(endingBuffer, bufferCap - depleteAmount);
        assertEq(block.timestamp, rlm.lastBufferUsedTime());
    }

    function testDepleteBuffer(uint128 amountToPull, uint16 warpAmount) public {
        if (amountToPull > bufferCap) {
            vm.expectRevert("RateLimited: rate limit hit");
            rlm.depleteBuffer(amountToPull);
        } else {
            vm.expectEmit(true, false, false, true, address(rlm));
            emit BufferUsed(amountToPull, bufferCap - amountToPull);
            rlm.depleteBuffer(amountToPull);
            uint256 endingBuffer = rlm.buffer();
            assertEq(endingBuffer, bufferCap - amountToPull);
            assertEq(block.timestamp, rlm.lastBufferUsedTime());

            vm.warp(block.timestamp + warpAmount);

            uint256 accruedBuffer = warpAmount * replenishRatePerSecond;
            uint256 expectedBuffer = Math.min(endingBuffer + accruedBuffer, bufferCap);
            assertEq(expectedBuffer, rlm.buffer());
        }
    }
}
