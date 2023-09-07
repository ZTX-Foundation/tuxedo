pragma solidity 0.8.18;

import "@protocol/utils/extensions/RateLimited.sol";

contract MockRateLimited is RateLimited {
    constructor(
        address _core,
        uint128 _rateLimitPerSecond,
        uint128 _bufferCap
    )
        RateLimited(_rateLimitPerSecond, _bufferCap)
        CoreRef(_core)
    {}

    function depleteBuffer(uint256 amount) public {
        _depleteBuffer(amount);
    }
}
