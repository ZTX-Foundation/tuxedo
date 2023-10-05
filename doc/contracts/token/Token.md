# Token.sol

## Introduction
Custom implementation built upon several extensions of the OpenZeppelin's ERC20 standard token contract. This documentation provides a comprehensive architectural review of the contract. 

### Overview
These diagrams provide a visual representation of how `Token.sol` interacts with its various features and dependencies. It primarily shows the flow of actions a user can initiate and how the contract interacts with other referenced contracts and utilities.

```mermaid
graph TD

A[User] --> B[Token Contract]
B --> C[ERC20 Base]
B --> D[ERC20Permit]
B --> E[ERC20Votes]

subgraph Base Contracts
    C --> |"Inherits/Uses"| F[transfer]
    C --> |"Inherits/Uses"| G[approve]
    C --> |"Inherits/Uses"| H[balanceOf]
    C --> |"Inherits/Uses"| I[allowance]
    D --> |"Inherits/Uses"| J[permit]
    E --> |"Inherits/Uses"| K[delegate]
    E --> |"Inherits/Uses"| L[getPastVotes]
    E --> |"Inherits/Uses"| M[getVotes]
end

B --> |"Defines/Uses"| N[maxSupply]
B --> |"Defines/Uses"| O[_beforeTokenTransfer]
B --> |"Defines/Uses"| P[_afterTokenTransfer]
B --> |"Defines/Uses"| Q[_burn]
B --> |"Defines/Uses"| R[_mint]
```

```mermaid
sequenceDiagram
    participant User
    participant Token
    participant ERC20 (from OpenZeppelin)
    participant Roles
    
    User->>Token: setTokenName(newName)
    note right of Token: Check if user has TOKEN_GOVERNOR role
    Token->>Roles: hasRole(TOKEN_GOVERNOR, User)
    Roles-->>Token: Result (true/false)
    Token-->>User: Token name updated (or error)

    User->>Token: setTokenSymbol(newSymbol)
    note right of Token: Check if user has TOKEN_GOVERNOR role
    Token->>Roles: hasRole(TOKEN_GOVERNOR, User)
    Roles-->>Token: Result (true/false)
    Token-->>User: Token symbol updated (or error)

    User->>Token: mint(to, amount)
    note right of Token: Check if user has MINTER role
    Token->>Roles: hasRole(MINTER, User)
    Roles-->>Token: Result (true/false)
    Token->>ERC20: _mint(to, amount)
    ERC20-->>Token: Tokens minted
    Token-->>User: Tokens minted (or error)

    User->>Token: burn(amount)
    note right of Token: Check if user can burn tokens (balances and allowances)
    Token->>ERC20: _burn(User, amount)
    ERC20-->>Token: Tokens burned
    Token-->>User: Tokens burned (or error)

    User->>Token: burnFrom(account, amount)
    note right of Token: Check if user can burn tokens on behalf of another account
    Token->>ERC20: _burn(account, amount)
    ERC20-->>Token: Tokens burned
    Token-->>User: Tokens burned from account (or error)
```

## Base Contracts
### OpenZeppelin
* [ERC20](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol): This is the core implementation provided by OpenZeppelin for the ERC20 standard, which is a widely-used fungible token standard on Ethereum.
* [ERC20Permit](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Permit.sol): An extension of ERC20 that introduces a permit function, which allows holders to give a spender allowance to transfer tokens with a signed message, eliminating the need for an initial transaction to approve the transfer.
* [ERC20Votes](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Votes.sol): An extension of ERC20 that facilitates on-chain voting with token-backed votes.

## Features
* Non-Burnable: The contract does not allow burning tokens, meaning tokens once minted cannot be destroyed.
* Fixed Supply: The contract has a fixed maximum supply of 10 billion tokens (10^10) with 18 decimals. This means no new tokens can be minted beyond this limit.

## Constants
* `MAX_SUPPLY`: Represents the maximum supply of the token, which is 10 billion tokens with 18 decimals.

## Constructor
The constructor accepts two string arguments:

* `name`: Represents the name of the token.
* `symbol`: Represents the symbol or ticker of the token.

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
