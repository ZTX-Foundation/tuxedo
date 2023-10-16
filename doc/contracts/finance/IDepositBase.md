# IDepositBase.sol

## Introduction
An interface for defining how the `DepositBase` functions. Please see [DepositBase.sol](./DepositBase.md) for more details.

## Events
### `Deposit()`
Emitted when tokens are deposited.
Logs:
- `_from`: Address of the user who deposited tokens.
- `_amount`: Amount of tokens deposited.
### `Withdrawal()`
Emitted when tokens are withdrawn.
Logs:
- `_caller`: Address of the user who withdrew tokens.
- `_to`: Address of the user who received the withdrawn tokens.
- `_amount`: Amount of tokens withdrawn.
### `WithdrawERC20()`
Emitted when ERC20 tokens are withdrawn from the contract.
Logs:
- `_caller`: Address of the user who initiated the withdrawal.
- `_token`: Address of the ERC20 token that's withdrawn.
- `_to`: Destination address receiving the withdrawn tokens.
- `_amount`: Amount of tokens that were withdrawn.
