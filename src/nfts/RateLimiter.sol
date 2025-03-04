// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

/// @title RateLimiter
/// @notice Library for rate limiting operations
library RateLimiter {
    /// @dev Structure to store rate limiting state
    struct RateLimitState {
        uint128 replenishRatePerSecond;
        uint128 bufferCap;
        uint128 bufferRemaining;
        uint32 lastReplenishTimestamp;
    }

    /// @dev Replenishes the buffer based on time passed
    /// @param state The rate limit state
    /// @param currentTime The current timestamp
    /// @return The new buffer amount after replenishment
    function replenishBuffer(RateLimitState storage state, uint256 currentTime) internal returns (uint128) {
        uint256 timePassed = currentTime - state.lastReplenishTimestamp;
        uint256 toReplenish = uint256(state.replenishRatePerSecond) * timePassed;

        // Cap replenishment
        uint256 newBufferRemaining = state.bufferRemaining + toReplenish;
        if (newBufferRemaining > state.bufferCap) {
            newBufferRemaining = state.bufferCap;
        }

        // Update state
        state.bufferRemaining = uint128(newBufferRemaining);
        state.lastReplenishTimestamp = uint32(currentTime);

        return state.bufferRemaining;
    }

    /// @dev Depletes the buffer by a specified amount
    /// @param state The rate limit state
    /// @param amount The amount to deplete
    /// @param currentTime The current timestamp
    /// @return The new buffer amount after depletion
    function depleteBuffer(
        RateLimitState storage state,
        uint256 amount,
        uint256 currentTime
    ) internal returns (uint128) {
        replenishBuffer(state, currentTime);
        require(amount <= state.bufferRemaining, "Buffer depleted");
        state.bufferRemaining = state.bufferRemaining - uint128(amount);
        return state.bufferRemaining;
    }

    /// @dev Initializes the rate limit state
    /// @param state The rate limit state to initialize
    /// @param _replenishRatePerSecond The rate at which buffer replenishes per second
    /// @param _bufferCap The maximum buffer size
    /// @param currentTime The current timestamp
    function initializeRateLimit(
        RateLimitState storage state,
        uint128 _replenishRatePerSecond,
        uint128 _bufferCap,
        uint32 currentTime
    ) internal {
        state.replenishRatePerSecond = _replenishRatePerSecond;
        state.bufferCap = _bufferCap;
        state.bufferRemaining = _bufferCap;
        state.lastReplenishTimestamp = currentTime;
    }
}
