# ERC20Splitter Contract Documentation

The `ERC20Splitter` contract is responsible for splitting ERC20 tokens into different deposits based on defined ratios. It allows efficient allocation of funds among multiple destinations. This contract utilizes the `CoreRef` contract for role management and access control.

## Events

1. `AllocationUpdate`: Emits when the allocations for splitting the tokens are updated.

   - Parameters:
     - `oldDeposits`: An array of addresses representing the old deposit destinations.
     - `oldRatios`: An array of integers representing the old ratios for splitting.
     - `newDeposits`: An array of addresses representing the new deposit destinations.
     - `newRatios`: An array of integers representing the new ratios for splitting.

2. `Allocate`: Emits when funds are allocated to the deposits.

   - Parameters:
     - `caller`: The address of the account that triggered the allocation.
     - `amount`: The total amount of tokens allocated.

### Contract Functionality

The `ERC20Splitter` contract provides the following functions:

#### View Only Functions

1. `getNumberOfAllocations()`: Retrieves the number of allocations.

2. `getAllocationAt(uint256 index)`: Retrieves the allocation at a given index.

   - Parameters:
     - `index`: The index of the allocation.

   - Returns: An `Allocation` struct representing the allocation at the specified index.

3. `getAllocations()`: Retrieves all the allocations.

   - Returns: An array of `Allocation` structs representing all the allocations.

#### Public Functions

1. `allocate()`: Allocates all funds in the splitter to the deposits.

2. `allocate(address tokenToAllocate)`: Allocates all funds in the splitter to the deposits for a specific token.

   - Parameters:
     - `tokenToAllocate`: The address of the token to be allocated by the splitter based on the defined ratios.

   - Modifiers:
     - `whenNotPaused`: The function can only be called when the contract is not paused.

#### Admin Only Functions

1. `setAllocation(Allocation[] memory _allocations)`: Sets the allocation of each deposit.

   - Parameters:
     - `_allocations`: An array of `Allocation` structs representing the new allocations.

   - Modifiers:
     - `onlyRole(Roles.ADMIN)`: The function can only be called by an admin role.

  - Requirements:
    - allocation weights must sum up to 10,000

### Roles

To properly function within the system, the `ERC20Splitter` contract requires no roles. Only the admin can change state of this function.

### Dependencies

The `ERC20Splitter` contract relies on the following external libraries and contracts:

- `CoreRef`: A contract that manages roles and access control.
- `SafeERC20`: A library from the OpenZeppelin contracts that provides safe ERC20 token transfer operations.
