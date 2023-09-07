pragma solidity 0.8.18;

import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Roles} from "@protocol/core/Roles.sol";

/// @title abstract contract for putting a rate limit on how fast a contract can perform an action e.g. Minting
abstract contract RateLimited is CoreRef {
    using SafeCast for *;

    /// ------------- First Storage Slot -------------

    /// @notice the rate per second for this contract to replenish the bufferCap usage
    uint128 public replenishRatePerSecond;

    /// @notice the cap of the buffer that can be used at once
    uint128 public bufferCap;

    /// ------------- Second Storage Slot -------------

    /// @notice the last time the buffer was used by the contract
    uint32 public lastBufferUsedTime;

    /// @notice the buffer remaining at the timestamp of lastBufferUsedTime
    uint224 public bufferRemaining;

    /// @notice event emitted when buffer gets eaten into
    event BufferUsed(uint256 amountUsed, uint256 bufferRemaining);

    /// @notice event emitted when buffer gets replenished
    event BufferReplenished(uint256 amountReplenished, uint256 bufferRemaining);

    /// @notice event emitted when buffer cap is updated
    event BufferCapUpdate(uint256 oldBufferCap, uint256 newBufferCap);

    /// @notice event emitted when replenish rate per second is updated
    event ReplenishRatePerSecondUpdate(
        uint256 oldReplenishRatePerSecond,
        uint256 newRateReplenishPerSecond
    );

    /// @notice RateLimited constructor
    /// @param _replenishRatePerSecond to replenish the buffer by
    /// @param _bufferCap cap on buffer size for this rate limited instance
    constructor(
        uint128 _replenishRatePerSecond,
        uint128 _bufferCap
    ) {
        lastBufferUsedTime = block.timestamp.toUint32();

        _setBufferCap(_bufferCap);
        bufferRemaining = _bufferCap;

        _setReplenishRatePerSecond(_replenishRatePerSecond);

    }

    /// @notice set the rate limit per second
    function setReplenishRatePerSecond(
        uint128 newRateLimitPerSecond
    ) external virtual hasAnyOfTwoRoles(Roles.TOKEN_GOVERNOR, Roles.ADMIN) {
        _updateBufferRemaining();

        _setReplenishRatePerSecond(newRateLimitPerSecond);
    }

    /// @notice set the buffer cap
    function setBufferCap(uint128 newBufferCap) external virtual hasAnyOfTwoRoles(Roles.TOKEN_GOVERNOR, Roles.ADMIN) {
        _setBufferCap(newBufferCap);
    }

    /// @notice the amount of action used before hitting limit
    /// @dev replenishes at replenishRatePerSecond per second up to bufferCap
    function buffer() public view returns (uint256) {
        uint256 elapsed = block.timestamp.toUint32() - lastBufferUsedTime;
        return
            Math.min(bufferRemaining + (replenishRatePerSecond * elapsed), bufferCap);
    }

    /** 
        @notice the method that enforces the rate limit. Decreases buffer by "amount". 
        If buffer is <= amount either
        1. Does a partial mint by the amount remaining in the buffer or
        2. Reverts
        Depending on whether doPartialAction is true or false
    */
    function _depleteBuffer(uint256 amount) internal {
        uint256 newBuffer = buffer();

        require(newBuffer != 0, "RateLimited: no rate limit buffer");
        require(amount <= newBuffer, "RateLimited: rate limit hit");

        bufferRemaining = (newBuffer - amount).toUint224();

        lastBufferUsedTime = block.timestamp.toUint32();

        emit BufferUsed(amount, bufferRemaining);
    }

    function _setReplenishRatePerSecond(uint128 newReplenishRatePerSecond) internal {
        uint256 oldReplenishRatePerSecond = replenishRatePerSecond;
        replenishRatePerSecond = newReplenishRatePerSecond;

        emit ReplenishRatePerSecondUpdate(
            oldReplenishRatePerSecond,
            newReplenishRatePerSecond
        );
    }

    /// @notice set the buffer Cap of the total amount of actions that can take place
    /// @param newBufferCap to be set
    function _setBufferCap(uint128 newBufferCap) internal {
        _updateBufferRemaining();

        uint256 oldBufferCap = bufferCap;
        bufferCap = newBufferCap;

        emit BufferCapUpdate(oldBufferCap, newBufferCap);
    }

    // @notice update the bufferRemaining
    function _updateBufferRemaining() internal {
        uint224 newBufferRemaining = buffer().toUint224();
        uint32 newBlockTimestamp = block.timestamp.toUint32();

        bufferRemaining = newBufferRemaining;
        lastBufferUsedTime = newBlockTimestamp;
    }
}
