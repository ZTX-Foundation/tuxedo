// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {MockReentrancyLock} from "@test/mock/MockReentrancyLock.sol";
import {IGlobalReentrancyLock} from "@protocol/core/IGlobalReentrancyLock.sol";

contract MockReentrancyLockFailure is CoreRef {
    using SafeCast for *;

    uint32 public lastBlockNumber;
    MockReentrancyLock public lock;

    constructor(address core, address _lock) CoreRef(core) {
        lock = MockReentrancyLock(_lock);
    }

    /// this will always fail due to the global reentrancy lock
    function globalReentrancyFails() external globalLock(1) {
        lock.testGlobalLock();
    }
}
