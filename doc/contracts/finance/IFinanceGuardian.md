# IFinanceGuardian.md

## Introduction
An interface for defining how `FinanceGuardian` functions. Please see [FinanceGuardian.sol](./FinanceGuardian.md) for more details.

## Events
### `FinanceGuardianWithdrawal()`
Emitted when tokens are withdrawn from the contract.
Logs:
- `holdingDeposit`: Address of the holding deposit contract.
- `amount`: Amount of tokens that were withdrawn.
### `FinanceGuardianERC20Withdrawal()`
Emitted when ERC20 tokens are withdrawn from the contract.
Logs:
- `holdingDeposit`: Address of the holding deposit contract.
- `token`: Address of the ERC20 token that's withdrawn.
- `amount`: Amount of tokens that were withdrawn.
### `SafeAddressUpdated()`
Emitted when the safe address is updated.
Logs:
- `oldSafeAddress`: Old safe address.
- `newSafeAddress`: New safe address.
