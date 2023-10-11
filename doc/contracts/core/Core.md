# Core.md

## Introduction
This contract is a foundational pillar in the ZTX protocol, emphasizing robust role-based access management and a systemic defense against reentrancy attacks. It harmoniously brings together critical functionalities to ensure system integrity, safety, and modularity.

### Overview
The diagrams below provide a visual representation of how `Core.sol` interacts with its various features and dependencies. It primarily shows the flow of actions a user can initiate and how the contract interacts with other referenced contracts and utilities.

#### Top-down
```mermaid
graph TD
    Core --> AccessControlEnumerable
    Core --> IGlobalReentrancyLock
    Core --> Roles
```

#### Sequence
```mermaid
sequenceDiagram
    participant User as User/Caller
    participant Core
    participant AccessControlEnumerable
    participant Lock as IGlobalReentrancyLock

    User->>Core: constructor()
    Core->>AccessControlEnumerable: _grantRole(Roles.ADMIN, msg.sender)
    Core->>AccessControlEnumerable: _setRoleAdmin(Various Roles, Roles.ADMIN)

    User->>Core: createRole(role, adminRole)
    alt has ADMIN role
        Core->>AccessControlEnumerable: _setRoleAdmin(role, adminRole)
        Core-->>User: Role created
    else
        Core-->>User: Revert
    end
    
    User->>Core: setGlobalLock(_lock)
    alt has ADMIN or TOKEN_GOVERNOR role
        Core->>Lock: set new lock address
        Core-->>User: Lock updated
    else
        Core-->>User: Revert
    end
    
    User->>Core: emergencyRevoke(role, account)
    alt has GUARDIAN role and role isn't ADMIN
        Core->>AccessControlEnumerable: _revokeRole(role, account)
        Core-->>User: Role revoked
    else
        Core-->>User: Revert
    end
```

## Base Contracts
### OpenZeppelin
- [AccessControlEnumerable](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/extensions/AccessControlEnumerable.sol): provides role-based access control. It allows the creation of different roles and permissions for those roles, ensuring that only authorized addresses can call certain functions.
### Protocol Specific
- [Roles](https://github.com/ZTX-Foundation/tuxedo/blob/develop/src/core/Roles.sol): Defines the various roles utilized within the system.
- [IGlobalReentrancyLock](https://github.com/ZTX-Foundation/tuxedo/blob/develop/src/core/IGlobalReentrancyLock.sol): An interface for `GlobalReentrancyLock`.
