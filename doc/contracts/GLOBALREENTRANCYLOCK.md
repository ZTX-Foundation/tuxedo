# GlobalReentrancyLock Contract Documentation

The `GlobalReentrancyLock` contract is designed to protect a system from reentrancy attacks. This contract allows certain roles, like a `LOCKER`, to lock and unlock the system at two levels. Once locked, only the original locker can unlock the system unless it's an emergency case in which the `ADMIN` can unlock the system. This contract should only be called from within the CoreRef `globalLock` modifier from contracts with the LOCKER role. This ensures there will be no reverts or deadlocks.

## Public State Variables

- `lastSender`: Stores the address that last locked the system.
- `lastBlockEntered`: Represents the last block at which the system was entered.
- `lockLevel`: Current level of system lock.

## Constants

- `_NOT_ENTERED`: Represents the system's unlocked state.
- `_ENTERED_LEVEL_ONE`: Signifies a level one lock on the system.
- `_ENTERED_LEVEL_TWO`: Signifies a level two lock on the system.

## Functions

### View Functions

- `isUnlocked()`: Returns `true` if the contract is not locked, else `false`.
- `isLocked()`: Returns `true` if the contract is locked, else `false`.

### State Changing Functions

- `lock(uint8 toLock)`: Sets the system status to the specified lock level. This function is only callable by accounts with the `LOCKER` role. Can only go up 1 from the current level. Must respect _ENTERED_LEVEL_TWO as the highest lock level, cannot go above that.
- `unlock(uint8 toUnlock)`: Sets the system status to the specified unlock level. Only the original locker or an account with the `LOCKER` role can call this function. Can only go down 1 from the current level. Must respect _NOT_ENTERED as the lowest lock level, cannot go beneath that.
- `adminEmergencyRecover()`: This function allows the `ADMIN` to recover the system from an incorrect state by setting the status to not entered.
- `adminEmergencyPause()`: This `ADMIN`-only function pauses the entire system by setting the lock to level two.

## Events

- `EmergencyUnlock`: Emitted when the `ADMIN` successfully unlocks the system in an emergency.
- `EmergencyLock`: Emitted when the `ADMIN` successfully locks the system in an emergency.

## Notes

1. The lock level transitions are restricted and must follow a sequence: 0 -> 1 -> 2.
2. The unlock operations must be performed by the original locker.
3. The `ADMIN` role can forcefully unlock or pause the system in case of emergencies.

## Security Considerations

1. The contract should be secure from reentrancy attacks and audited thoroughly.
2. It is crucial that the locker role is properly managed, and the locker cannot manipulate the lock states arbitrarily.
3. The `ADMIN` role should be used carefully due to its powerful privileges, especially in emergency cases.
