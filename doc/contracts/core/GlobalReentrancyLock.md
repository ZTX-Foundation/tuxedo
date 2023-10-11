# GlobalReentrancyLock.sol

## Introduction
Designed to mitigate reentrancy attacks. Reentrancy attacks occur when external contract calls are made within a function, potentially allowing malicious actors to reenter the same function and exploit it. This can lead to significant vulnerabilities, particularly in financial contracts where an attacker could drain funds.

### Overview
The diagrams below provide a visual representation of how `GlobalReentrancyLock.sol` interacts with its various features and dependencies. It primarily shows the flow of actions a user can initiate and how the contract interacts with other referenced contracts and utilities.

#### Top-down
```mermaid
graph TD
    GlobalReentrancyLock --> IGlobalReentrancyLock
    GlobalReentrancyLock --> CoreRef
    GlobalReentrancyLock --> Roles
```

#### Sequence
```mermaid
sequenceDiagram
    participant User as User/Caller
    participant GlobalReentrancyLock
    participant Block as EVM
    
    User->>GlobalReentrancyLock: call isUnlocked()
    alt isUnlocked
        GlobalReentrancyLock-->>User: return true
    else
        GlobalReentrancyLock-->>User: return false
    end
    
    User->>GlobalReentrancyLock: call isLocked()
    alt isLocked
        GlobalReentrancyLock-->>User: return true
    else
        GlobalReentrancyLock-->>User: return false
    end
    
    User->>GlobalReentrancyLock: call lock(toLock)
    alt Valid Lock Request & has LOCKER Role
        GlobalReentrancyLock->>Block: fetch block.number
        Block-->>GlobalReentrancyLock: return block number
        GlobalReentrancyLock-->>User: Lock successful
    else
        GlobalReentrancyLock-->>User: Revert
    end
    
    User->>GlobalReentrancyLock: call unlock(toUnlock)
    alt Valid Unlock Request & has LOCKER Role
        GlobalReentrancyLock->>Block: fetch block.number
        Block-->>GlobalReentrancyLock: return block number
        GlobalReentrancyLock-->>User: Unlock successful
    else
        GlobalReentrancyLock-->>User: Revert
    end
    
    User->>GlobalReentrancyLock: call adminEmergencyRecover() / adminEmergencyPause()
    alt has ADMIN Role
        GlobalReentrancyLock-->>User: Recovery/Pause successful
    else
        GlobalReentrancyLock-->>User: Revert
    end
```

## Base Contracts
### Protocol Specific
- [Roles](https://github.com/ZTX-Foundation/tuxedo/blob/develop/src/core/Roles.sol): Defines the various roles utilized within the system.
- [CoreRef](https://github.com/ZTX-Foundation/tuxedo/blob/develop/src/refs/CoreRef.sol): Provides a reference to the protocol's core contract.
- [IGlobalReentrancyLock](https://github.com/ZTX-Foundation/tuxedo/blob/develop/src/core/IGlobalReentrancyLock.sol): An interface for `GlobalReentrancyLock`.
