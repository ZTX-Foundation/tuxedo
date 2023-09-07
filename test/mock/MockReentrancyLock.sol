// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {IGlobalReentrancyLock} from "@protocol/core/IGlobalReentrancyLock.sol";

contract MockReentrancyLock is CoreRef {
    using SafeCast for *;

    uint32 public lastBlockNumber;

    constructor(address core) CoreRef(core) {}

    /// this contract asserts the core invariant of global reentrancy lock
    /// that it is always locked during execution
    function testGlobalLock() external globalLock(1) {
        require(
            core.lock().isLocked(),
            "System not locked correctly"
        );
        lastBlockNumber = block.number.toUint32();
    }

    /// this will always fail due to the global reentrancy lock
    function globalLockReentrantFailure() external globalLock(1) {
        MockReentrancyLock(address(this)).testGlobalLock();
    }
}
