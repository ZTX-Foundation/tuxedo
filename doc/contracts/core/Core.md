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
    participant IGlobalReentrancyLock

    User->>+Core: createRole(...)
    alt ADMIN role
        Core->>AccessControlEnumerable: _setRoleAdmin(...)
    else
        Core->>-User: Revert
    end
    
    User->>+Core: setGlobalLock(...)
    alt ADMIN or TOKEN_GOVERNOR role
        Core->>IGlobalReentrancyLock: set new lock address
        Core->>Core: Emit GlobalReentrancyLockUpdate event
    else
        Core->>-User: Revert
    end
    
    User->>+Core: emergencyRevoke(...)
    alt GUARDIAN role and not ADMIN
        Core->>AccessControlEnumerable: _revokeRole(...)
        Core->>Core: Emit EmergencyRevoke event
    else
        Core->>-User: Revert
    end
```

## Base Contracts
### OpenZeppelin
- [AccessControlEnumerable](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/extensions/AccessControlEnumerable.sol): provides role-based access control. It allows the creation of different roles and permissions for those roles, ensuring that only authorized addresses can call certain functions.
### Protocol Specific
- [Roles](https://github.com/ZTX-Foundation/tuxedo/blob/develop/src/core/Roles.sol): Defines the various roles utilized within the system.
- [IGlobalReentrancyLock](https://github.com/ZTX-Foundation/tuxedo/blob/develop/src/core/IGlobalReentrancyLock.sol): An interface for `GlobalReentrancyLock`.

## Features
- Inherits from OpenZeppelin's `AccessControlEnumerable`, meaning it can define a flexible set of roles and permissions. Each role can have an associated admin role, and only accounts with the admin role can grant or revoke the associated role from other accounts.
- On deployment, several roles are defined. The `ADMIN` role is granted to the account that deploys the contract, and it's the highest level of permission.
- The `createRole()` function allows the `ADMIN` to dynamically create new roles and specify their admin roles. This offers flexibility in expanding the role-based access system as the protocol grows.
- The `emergencyRevoke()` function provides a mechanism for the `GUARDIAN` role to revoke roles from accounts in case of emergencies. However, the guardian cannot revoke the `ADMIN` role. This ensures that in the event of a security threat or other issues, rapid action can be taken.
- The contract holds a reference to a global reentrancy lock (of type `IGlobalReentrancyLock`) named lock.
- The `setGlobalLock()` function allows `ADMIN` or `TOKEN_GOVERNOR` to update the address of the reentrancy lock.

## Events
These events offer a mechanism to track and audit the various interactions and updates that occur within the `Core` contract.

### `EmergencyRevoke`
This event is emitted when a role is revoked by the guardian.
Logs:
- `role`: The role that was revoked.
- `account`: The address from which the role was revoked.

### `RoleCreated`
This event is emitted when a new role is created.
Logs:
- `role`: The newly created role.
- `adminRole`: The admin role associated with the new role.

### `GlobalReentrancyLockUpdate`
This event is emitted when the pointer to the global reentrancy lock is updated.
Logs:
- `oldLock`: The address of the previous global reentrancy lock.
- `newLock`: The address of the new global reentrancy lock.

## Constructor
The constructor accepts no arguments. The constructor sets the initial protocol roles and grants the `ADMIN` role to the account that deploys the contract.
 
## Functions
### `createRole()`
Allows `ADMIN` to create a new role and specify its admin role. This function is used to create roles within the protocol.

### `setGlobalLock()`
Allows `ADMIN` or `TOKEN_GOVERNOR` to set the address of the global reentrancy lock. This lock helps prevent reentrancy attacks in the protocol.

### `emergencyRevoke()`
Allows `GUARDIAN` to revoke a specific role from an account. This function is used to remove a role in emergency situations.
