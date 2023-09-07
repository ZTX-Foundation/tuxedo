# Core Contract Documentation

The `Core` contract is central to managing roles and provides a pointer to a global reentrancy lock. All other contracts that use roles inherit `CoreRef`, which contains a pointer to this contract. Roles are managed by the `ADMIN` role, and the contract leverages OpenZeppelin's `AccessControlEnumerable` for role-based access control.

## Public State Variables

- `lock`: A reference to the global reentrancy lock of type `IGlobalReentrancyLock`.

## Functions

- `createRole(bytes32 role, bytes32 adminRole)`: This function creates a new role with an associated admin role. It's only callable by the `ADMIN` role.
- `setGlobalLock(address _lock)`: Updates the global reentrancy lock with the address of the new lock. It can only be called by accounts with the `ADMIN` or `TOKEN_GOVERNOR` role.
- `emergencyRevoke(bytes32 role, address account)`: Used to revoke roles during an emergency. This can only be called by the `GUARDIAN` role, and cannot be used to revoke the `ADMIN` role.

## Events

- `EmergencyRevoke`: Emitted when a role is revoked by the `GUARDIAN`.
- `RoleCreated`: Emitted when a new role is created.
- `GlobalReentrancyLockUpdate`: Emitted when the pointer to the global reentrancy lock is updated.

## Constructor

The constructor grants the `ADMIN` role to the contract deployer (`msg.sender`), and sets the admin roles for `ADMIN`, `TOKEN_GOVERNOR`, `GUARDIAN`, `MINTER`, `FINANCIAL_CONTROLLER`, `FINANCIAL_GUARDIAN`, `LOCKER`, `MINTER_NOTARY`, and `GAME_CONSUMER_NOTARY` as `ADMIN`.

## Roles

- `ADMIN`: Manages all other roles and can update the global lock.
- `TOKEN_GOVERNOR`: Can update the global lock.
- `GUARDIAN`: Can revoke any role except `ADMIN` in case of emergency.

## Notes

1. The contract should be secure and audited thoroughly.
2. Role management should be performed with due care.
3. The `GUARDIAN` role should be used carefully due to its emergency powers.
