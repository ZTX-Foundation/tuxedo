### FinanceGuardian Contract Documentation

The `FinanceGuardian` contract is responsible for safeguarding protocol funds by allowing authorized entities to withdraw funds from whitelisted deposits to a safe address. This contract utilizes the `CoreRef` contract for role management and access control and extends the `WhitelistedAddresses` contract to manage the whitelist of deposit addresses.

#### Events

1. `SafeAddressUpdated`: Emits when the safe address is updated.

   - Parameters:
     - `oldSafeAddress`: The previous safe address.
     - `newSafeAddress`: The new safe address.

2. `FinanceGuardianWithdrawal`: Emits when funds are withdrawn from a deposit.

   - Parameters:
     - `deposit`: The address of the deposit contract from which the funds are withdrawn.
     - `amount`: The amount of funds withdrawn.

3. `FinanceGuardianERC20Withdrawal`: Emits when ERC20 funds are withdrawn from a deposit.

   - Parameters:
     - `deposit`: The address of the deposit contract from which the funds are withdrawn.
     - `token`: The address of the ERC20 token being withdrawn.
     - `amount`: The amount of ERC20 funds withdrawn.

#### Contract Functionality

The `FinanceGuardian` contract provides the following functions:

##### Admin or Governor-Only State-Changing API

1. `setSafeAddress(address newSafeAddress)`: Updates the safe address.

   - Parameters:
     - `newSafeAddress`: The new safe address.

   - Modifiers:
     - `onlyRole(Roles.ADMIN)`: The function can only be called by an admin role.

2. `addWhitelistAddress(address deposit)`: Whitelists a deposit address to withdraw funds from.

   - Parameters:
     - `deposit`: The address of the deposit to be whitelisted.

   - Modifiers:
     - `hasAnyOfTwoRoles(Roles.TOKEN_GOVERNOR, Roles.ADMIN)`: The function can only be called by an admin or token governor role.

3. `addWhitelistAddresses(address[] calldata _whitelistAddresses)`: Batch version of `addWhitelistAddress()` to whitelist multiple deposit addresses.

   - Parameters:
     - `_whitelistAddresses`: An array of deposit addresses to be whitelisted.

   - Modifiers:
     - `hasAnyOfTwoRoles(Roles.TOKEN_GOVERNOR, Roles.ADMIN)`: The function can only be called by an admin or token governor role.

##### Admin, Governor-Or-Guardian-Only State-Changing API

1. `removeWhitelistAddress(address deposit)`: Removes a deposit address from the whitelist.

   - Parameters:
     - `deposit`: The address of the deposit to be removed from the whitelist.

   - Modifiers:
     - `hasAnyOfThreeRoles(Roles.TOKEN_GOVERNOR, Roles.ADMIN, Roles.GUARDIAN)`: The function can only be called by an admin, token governor, or guardian role.

2. `removeWhitelistAddresses(address[] calldata _whitelistAddresses)`: Batch version of `removeWhitelistAddress()` to remove multiple deposit addresses from the whitelist.

   - Parameters:
     - `_whitelistAddresses`: An array of deposit addresses to be removed from the whitelist.

   - Modifiers:
     - `hasAnyOfThreeRoles(Roles.TOKEN_GOVERNOR, Roles.ADMIN, Roles.GUARDIAN)`: The function can only be called by an admin, token governor, or guardian role.

##### Finance Guardian State-Changing API

The following functions allow the token governor, guardian, financial guardian, and the admin to pull funds from whitelisted addresses in the Financial Guardian to the safe address.

1. `withdrawToSafeAddress(address deposit, uint256 amount)`: Withdraws funds from a deposit to the safe address.

   - Parameters:
     - `deposit`: The address of the deposit contract.
     - `amount`: The amount of funds to withdraw.

2. `withdrawAllToSafeAddress(address deposit)`: Withdraws all funds from a deposit to the safe address.

   - Parameters:
     - `deposit`: The address of the deposit contract.

3. `withdrawERC20ToSafeAddress(address deposit, address token, uint256 amount)`: Withdraws ERC20 funds from a deposit to the safe address.

   - Parameters:
     - `deposit`: The address of the deposit contract.
     - `token`: The address of the ERC20 token to be withdrawn.
     - `amount`: The amount of ERC20 funds to withdraw.

4. `withdrawAllERC20ToSafeAddress(address deposit, address token)`: Withdraws all ERC20 funds from a deposit to the safe address.

   - Parameters:
     - `deposit`: The address of the deposit contract.
     - `token`: The address of the ERC20 token to be withdrawn.

#### Roles

To properly function within the system, the `FinanceGuardian` contract must be granted the following roles:

- `LOCKER`: The role that is required to use the global reentrancy lock.
- `GUARDIAN`: The guardian role allows unpausing paused deposits to withdraw funds.
- `FINANCIAL_CONTROLLER`: The financial controller role allows withdrawing funds from deposit addresses.

These roles ensure that the Finance Guardian can function properly.
