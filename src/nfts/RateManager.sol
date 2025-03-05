// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

/// @title RateManager
/// @notice Library for rate limiting functionality
library RateManager {
    /// @dev State for rate limiting
    struct RateState {
        uint128 lastReplenishTimestamp;
        uint128 buffer;
    }

    /// @notice Initialize rate limiting state
    /// @param state Rate state storage
    /// @param bufferCap Maximum buffer size
    function initialize(RateState storage state, uint128 bufferCap) internal {
        state.lastReplenishTimestamp = uint128(block.timestamp);
        state.buffer = bufferCap;
    }

    /// @notice Replenish the buffer based on elapsed time
    /// @param state Rate state storage
    /// @param replenishRate Rate at which buffer is replenished
    /// @param bufferCap Maximum buffer size
    /// @return newBuffer Updated buffer amount
    function replenish(
        RateState storage state, 
        uint128 replenishRate, 
        uint128 bufferCap
    ) internal returns (uint128 newBuffer) {
        // Calculate elapsed time since last replenishment
        uint128 elapsed = uint128(block.timestamp) - state.lastReplenishTimestamp;
        if (elapsed == 0) {
            return state.buffer;
        }

        // Update timestamp
        state.lastReplenishTimestamp = uint128(block.timestamp);

        // Calculate replenishment amount
        uint128 added = elapsed * replenishRate;

        // Update buffer without exceeding cap
        uint128 newBufferAmount = state.buffer + added;
        if (newBufferAmount < state.buffer) {
            // Overflow, cap at maximum
            state.buffer = bufferCap;
        } else if (newBufferAmount > bufferCap) {
            // Exceeds cap, cap at maximum
            state.buffer = bufferCap;
        } else {
            // Normal case
            state.buffer = newBufferAmount;
        }

        return state.buffer;
    }

    /// @notice Deplete buffer by an amount
    /// @param state Rate state storage
    /// @param amount Amount to deplete
    /// @param replenishRate Rate at which buffer is replenished
    /// @param bufferCap Maximum buffer size
    /// @return bufferRemaining Remaining buffer after depletion
    function deplete(
        RateState storage state, 
        uint256 amount,
        uint128 replenishRate, 
        uint128 bufferCap
    ) internal returns (uint128 bufferRemaining) {
        // First replenish buffer
        replenish(state, replenishRate, bufferCap);

        // Ensure amount is not too large
        require(amount <= type(uint128).max, "ERC1155AutoGraphMinter: Amount exceeds uint128 max");
        uint128 amountUint128 = uint128(amount);

        // Ensure sufficient buffer
        require(amountUint128 <= state.buffer, "ERC1155AutoGraphMinter: Insufficient buffer");

        // Deplete buffer
        state.buffer -= amountUint128;

        return state.buffer;
    }
} 