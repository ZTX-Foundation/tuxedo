# ERC20HoldingDeposit Contract Documentation

## Contract Overview
The ERC20HoldingDeposit contract is a deposit contract that holds ERC20 tokens as a safe harbor. It acts as a storage mechanism for the tokens and allows for controlled withdrawals. The deposit contract is a no-op, meaning it does not perform any actions or calculations on the deposited tokens.

## Contract Details
- Imports: SafeERC20, IERC20, Roles, CoreRef, Constants, DepositBase
- Inheritance: DepositBase
- Roles:
  - FINANCIAL_CONTROLLER: Can withdraw ERC20 tokens from the contract.
- Libraries Used: SafeERC20

## State Variables
- token: The ERC20 token that is being held by the deposit contract.

## Constructor
- ERC20HoldingDeposit: Initializes the ERC20HoldingDeposit contract with the address of the core contract and the ERC20 token to be held.

## Read-Only Methods
1. balance: Retrieves the total balance of the held ERC20 tokens in the deposit contract.
2. balanceReportedIn: Retrieves the address of the ERC20 token in which the balance is reported.

## Public State-Changing Function
1. withdraw: Allows the financial controller to withdraw ERC20 tokens from the contract. Transfers the specified amount of tokens to the specified address.

## DepositBase Contract
The ERC20HoldingDeposit contract inherits from the DepositBase contract, which provides additional functionality for withdrawing ERC20 tokens using a Financial Controller.

## DepositBase Contract Details
- Imports: SafeERC20, Address, Roles, CoreRef, IDepositBase
- Inheritance: CoreRef, IDepositBase
- Roles:
  - FINANCIAL_CONTROLLER: Can withdraw ERC20 tokens from the contract.
- Libraries Used: SafeERC20

## DepositBase Functions
1. withdrawERC20: Allows the financial controller to withdraw ERC20 tokens from the contract. Transfers the specified amount of tokens to the specified address.

Please refer to the DepositBase contract documentation for more details on the inherited functions.

Note: Additional events emitted by the contracts have not been included in this documentation.

## Events

The ERC20HoldingDeposit contract emits the following event to provide information about important contract interactions:

1. `Withdrawal`: Emits when ERC20 tokens are successfully withdrawn from the contract.
   - Parameters:
     - `caller`: Address of the caller who initiated the withdrawal.
     - `to`: Address where the ERC20 tokens are transferred.
     - `amountUnderlying`: Amount of ERC20 tokens being withdrawn.

2. `WithdrawERC20`: Emits when ERC20 tokens are successfully withdrawn from the contract.
   - Parameters:
     - `caller`: Address of the caller who initiated the withdrawal.
     - `token`: Address of the ERC20 token being withdrawn.
     - `to`: Address of the destination where the tokens are transferred.
     - `amount`: Amount of ERC20 tokens being withdrawn.

These events provide transparency and allow interested parties to track and verify important contract actions and state changes.
