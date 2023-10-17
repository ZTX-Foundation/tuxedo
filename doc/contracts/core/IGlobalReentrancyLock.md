# IGlobalReentrancyLock.sol

## Introduction
An interface for defining how `GlobalReentrancyLock` functions. Please see [GlobalReentrancyLock.sol](./GlobalReentrancyLock.md) for more details.

## Events
### `EmergencyUnlock()`
Emitted when the contract is unlocked in an emergency.
Logs:
- `sender`: Address of the user who unlocked the contract.
- `timestamp`: Timestamp.
### `EmergencyLock()`
Emitted when the contract is locked in an emergency.
Logs:
- `sender`: Address of the user who locked the contract.
- `timestamp`: Timestamp.
