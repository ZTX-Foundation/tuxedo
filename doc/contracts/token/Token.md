# Token.sol

## Introduction
Custom implementation built upon several extensions of the OpenZeppelin's ERC20 standard token contract. This documentation provides a comprehensive architectural review of the contract. 

### Overview
These diagrams provide a visual representation of how `Token.sol` interacts with its various features and dependencies. It primarily shows the flow of actions a user can initiate and how the contract interacts with other referenced contracts and utilities.

#### Top-down
```mermaid
graph TD
    Token --> ERC20
    Token --> ERC20Permit
    Token --> ERC20Votes
```

#### Sequence
```mermaid
sequenceDiagram
    participant User as User/Caller
    participant Token
    participant ERC20
    participant ERC20Permit
    participant ERC20Votes

    User->>Token: constructor(name, symbol)
    Token->>ERC20: Initialize(name, symbol)
    Token->>ERC20Permit: Initialize(name)
    Token->>Token: _mint(msg.sender, MAX_SUPPLY)
    activate Token
    Token->>ERC20Votes: _mint(account, amount)
    Token->>ERC20: _mint(account, amount)
    deactivate Token

    User->>Token: Transfer (to, amount)
    Token->>Token: _beforeTokenTransfer(from, to, amount)
    Token->>ERC20: Transfer(from, to, amount)
    Token->>Token: _afterTokenTransfer(from, to, amount)
    activate Token
    Token->>ERC20Votes: _afterTokenTransfer(from, to, amount)
    Token->>ERC20Votes: _delegate(to, to)
    deactivate Token

    User->>Token: Burn (amount)
    Token->>Token: _burn(account, amount)
    activate Token
    Token->>ERC20Votes: _burn(account, amount)
    Token->>ERC20: _burn(account, amount)
    deactivate Token
```

## Base Contracts
### OpenZeppelin
- [ERC20](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol): This is the core implementation provided by OpenZeppelin for the ERC20 standard, which is a widely-used fungible token standard on Ethereum.
- [ERC20Permit](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Permit.sol): An extension of ERC20 that introduces a permit function, which allows holders to give a spender allowance to transfer tokens with a signed message, eliminating the need for an initial transaction to approve the transfer.
- [ERC20Votes](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Votes.sol): An extension of ERC20 that facilitates on-chain voting with token-backed votes.

## Features
- Non-Burnable: The contract does not allow burning tokens, meaning tokens once minted cannot be destroyed.
- Fixed Supply: The contract has a fixed maximum supply of 10 billion tokens (10^10) with 18 decimals. This means no new tokens can be minted beyond this limit.

## Constants
- `MAX_SUPPLY`: Represents the maximum supply of the token, which is 10 billion tokens with 18 decimals.

## Constructor
The constructor accepts two arguments:

- `name`: Represents the name of the token.
- `symbol`: Represents the symbol or ticker of the token.

Upon deployment, the contract mints the `MAX_SUPPLY` of tokens and assigns them to the deployer of the contract. 

## Functions
### `maxSupply()`
A pure function that returns the `MAX_SUPPLY`.

### `_beforeTokenTransfer()`
This is an internal function required by the ERC20 standard, especially when extensions like `ERC20Snapshot` are used (although it's not directly used here). It's a hook that can be extended to customize behavior before any transfer, minting, or burning operation.

### `_afterTokenTransfer()`
Another internal hook function that gets called after token transfer operations. It's crucial for the functioning of both `ERC20` and `ERC20Votes` to maintain vote counts.

### `_burn()`
An internal function to burn tokens. Even though the contract is labeled non-burnable, this function still exists in the base contract and is overridden here to ensure it aligns with both `ERC20` and `ERC20Votes`.

### `_mint()`
An internal function to mint tokens. This is used in the constructor to mint the initial `MAX_SUPPLY` tokens.

## Design Rationale
The `ERC20Permit` extension is used to eliminate the need for two transactions when a user wants to spend another user's tokens. Traditionally, the token owner would first need to approve the spender, and then the spender would call transferFrom. With permit, the owner can sign a message off-chain that gives the spender permission, and the spender can then submit this permission on-chain in a single transaction.

The `ERC20Votes` extension is used to enable on-chain voting using the token. Token holders can delegate their voting power or vote on proposals. The _afterTokenTransfer hook ensures that voting power is correctly adjusted after any token transfer.
