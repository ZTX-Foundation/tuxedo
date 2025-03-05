// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

/// @title RateManager
/// @notice Library for managing rate limiting functionality
library RateManager {
    /// @dev Structure to store rate limiting state
    struct RateState {
        uint128 replenishRatePerSecond;
        uint128 bufferCap;
        uint128 bufferRemaining;
        uint32 lastReplenishTimestamp;
    }
    
    /// @dev Initializes rate limit state
    /// @param state The rate limit state to initialize
    /// @param replenishRate Rate of buffer replenishment per second
    /// @param bufferCap Maximum buffer size
    function initializeRate(
        RateState storage state,
        uint128 replenishRate,
        uint128 bufferCap
    ) internal {
        state.replenishRatePerSecond = replenishRate;
        state.bufferCap = bufferCap;
        state.bufferRemaining = bufferCap;
        state.lastReplenishTimestamp = uint32(block.timestamp);
    }
    
    /// @dev Replenishes the buffer based on time passed
    /// @param state The rate limit state
    /// @return The updated buffer amount
    function replenish(RateState storage state) internal returns (uint128) {
        uint256 timePassed = block.timestamp - state.lastReplenishTimestamp;
        uint256 toReplenish = uint256(state.replenishRatePerSecond) * timePassed;
        
        // Cap replenishment
        uint256 newBuffer = state.bufferRemaining + toReplenish;
        if (newBuffer > state.bufferCap) {
            newBuffer = state.bufferCap;
        }
        
        // Update state
        state.bufferRemaining = uint128(newBuffer);
        state.lastReplenishTimestamp = uint32(block.timestamp);
        
        return state.bufferRemaining;
    }
    
    /// @dev Depletes the buffer by a specified amount
    /// @param state The rate limit state
    /// @param amount The amount to deplete
    /// @return The remaining buffer amount
    function deplete(RateState storage state, uint256 amount) internal returns (uint128) {
        replenish(state);
        require(amount <= state.bufferRemaining, "Buffer depleted");
        state.bufferRemaining = state.bufferRemaining - uint128(amount);
        return state.bufferRemaining;
    }
} 