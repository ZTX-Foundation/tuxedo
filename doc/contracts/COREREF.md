# CoreRef Contract Documentation

The `CoreRef` is an abstract contract intended for inheritance by system contracts. It maintains a pointer to a `Core` contract, uses the Access Control List (ACL) defined in `Core` for access control, and utilizes OpenZeppelin's `Pausable` contract for pausing functionality.

## Public State Variables

- `core`: This is a reference to the `Core` contract.

## Functions

- `pause()`: Pauses all functions which are using the `Pausable` modifier. Can be called by accounts with the `ADMIN`, `TOKEN_GOVERNOR`, or `GUARDIAN` role.
- `unpause()`: Unpauses all paused functions. Can be called by accounts with the `ADMIN`, `TOKEN_GOVERNOR`, or `GUARDIAN` role.
- `setCore(address newCore)`: Updates the reference to the `Core` contract. This function can only be called by accounts with the `ADMIN` role.
- `emergencyAction(Call[] calldata calls)`: Executes arbitrary calldata against arbitrary addresses. This function is only callable by the `ADMIN` role.

## Modifiers

- `globalLock(uint8 level)`: A modifier which locks the `IGlobalReentrancyLock` with a given level and unlocks it after execution of the function.
- `onlyRole(bytes32 role)`: A modifier which allows function access only to accounts with a specified role.
- `hasAnyOfTwoRoles(bytes32 role1, bytes32 role2)`, `hasAnyOfThreeRoles(bytes32 role1, bytes32 role2, bytes32 role3)`, `hasAnyOfFourRoles(bytes32 role1, bytes32 role2, bytes32 role3, bytes32 role4)`: These modifiers allow function access to accounts with any of the specified roles.

## Events

- `CoreUpdate`: Emitted when the `core` reference is updated.

## Constructor

The constructor initializes the `core` variable with the `Core` contract address passed in the argument.

## Notes

1. Use `setCore` with caution. Setting it to an invalid core could cause a Denial of Service (DoS) attack on the contract.
2. Access to functions is controlled by roles specified in the `Core` contract. Be mindful of access control.
3. `emergencyAction` allows to execute arbitrary calls, handle it with extra caution.
