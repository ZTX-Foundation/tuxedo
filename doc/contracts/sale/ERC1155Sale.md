# ERC1155Sale.sol

## Introduction
Allows users to purchase ERC1155 tokens using either ETH or specific ERC20 tokens. The contract has built-in mechanisms for setting token prices, sweeping unclaimed amounts, and maintaining Merkle proofs to validate transactions. This document will provide a detailed breakdown of the contract's structure and interactions.

### Overview
These diagrams provide a visual representation of how `ERC1155Sale.sol` interacts with its various features and dependencies. It primarily shows the flow of actions a user can initiate and how the contract interacts with other referenced contracts and utilities.

#### Top-down
```mermaid
graph TD
    ERC1155Sale --> MerkleProof
    ERC1155Sale --> SafeERC20
    ERC1155Sale --> SafeCast
    ERC1155Sale --> IERC20
    ERC1155Sale --> Roles
    ERC1155Sale --> IWETH
    ERC1155Sale --> CoreRef
    ERC1155Sale --> Constants
    ERC1155Sale --> IERC1155Sale
    ERC1155Sale --> ERC1155MaxSupplyMintable
```

#### Sequence
```mermaid
sequenceDiagram
    participant User as User/Caller
    participant ERC1155Sale
    participant ERC1155MaxSupplyMintable
    participant ERC20
    participant IWETH

    User->>+ERC1155Sale: getTokenRecipientsAndUnclaimed()
    ERC1155Sale->>-User: Return tokenRecipients and unclaimed amounts

    User->>+ERC1155Sale: getPurchasePrice(...)
    ERC1155Sale->>-User: Return purchase price

    User->>+ERC1155Sale: getBulkPurchaseTotal(...)
    loop For each erc1155TokenId
        ERC1155Sale->>ERC1155Sale: getPurchasePrice(...)
    end
    ERC1155Sale->>-User: Return total purchase price

    User->>+ERC1155Sale: getMaxMintAmountOut(...)
    ERC1155Sale->>-User: Return max number of tokens left for purchase

    User->>+ERC1155Sale: buyTokenWithEth(...)
    alt require ERC1155Sale is not paused
        ERC1155Sale->>ERC1155Sale: getPurchasePrice(...)
        alt msg.value == totalCost
            ERC1155Sale->>ERC1155Sale: _helperBuyWithEth(...)
            ERC1155Sale->>ERC1155MaxSupplyMintable: mint(...)
            ERC1155Sale->>ERC1155Sale: Emit TokensPurchased event
        else
            ERC1155Sale-->>User: Revert
        end
    else
        ERC1155Sale-->>-User: Revert
    end
    
    User->>+ERC1155Sale: buyTokensWithEth(...)
    alt require ERC1155Sale is not paused
        ERC1155Sale->>ERC1155Sale: getPurchasePrice(...)
        ERC1155Sale->>ERC1155Sale: _arityCheck(...)
        ERC1155Sale->>ERC1155Sale: getBulkPurchaseTotal(...)
        alt msg.value == total
            loop For each erc1155TokenId
                ERC1155Sale->>ERC1155Sale: _helperBuyWithEth(...)
            end
            ERC1155Sale->>ERC1155MaxSupplyMintable: mintBatch(...)
        end
    else
        ERC1155Sale-->>-User: Revert
    end

    User->>+ERC1155Sale: buyToken(...)
    alt require ERC1155Sale is not paused
        ERC1155Sale->>ERC1155Sale: _buyTokenChecks(...)
        ERC1155Sale->>ERC20: safeTransferFrom(...)
        ERC1155Sale->>ERC1155MaxSupplyMintable: mint(...)
        ERC1155Sale->>ERC1155Sale: Emit TokensPurchased event
    else
        ERC1155Sale-->>-User: Revert
    end

    User->>+ERC1155Sale: buyTokens(...)
    alt require ERC1155Sale is not paused
        ERC1155Sale->>ERC1155Sale: _arityCheck(...)
        loop For each erc1155TokenId
            ERC1155Sale->>ERC1155Sale: _buyTokenChecks(...)
            ERC1155Sale->>ERC20: safeTransferFrom(...)
            ERC1155Sale->>ERC1155Sale: Emit TokensPurchased event
        end
        ERC1155Sale->>ERC1155MaxSupplyMintable: mintBatch(...)
    else
        ERC1155Sale-->>-User: Revert
    end
    
    User->>+ERC1155Sale: sweepUnclaimed(...)
    ERC1155Sale->>ERC20: safeTransfer(...) (fees)
    ERC1155Sale->>ERC20: safeTransfer(...) (proceeds)
    ERC1155Sale->>ERC1155Sale: Emit TokensSwept event (fees)
    ERC1155Sale->>-ERC1155Sale: Emit TokensSwept event (proceeds)

    User->>+ERC1155Sale: wrapEth()
    alt ADMIN role
        ERC1155Sale->>IWETH: deposit(...)
    else
        ERC1155Sale-->>-User: Revert
    end

    User->>+ERC1155Sale: setTokenRecipients(...)
    alt ADMIN role
        ERC1155Sale->>ERC1155Sale: Update tokenRecipients mapping
        ERC1155Sale->>ERC1155Sale: Emit TokenRecipientsUpdated event
    else
        ERC1155Sale-->>-User: Revert
    end

    User->>+ERC1155Sale: setTokenConfig(...)
    alt ADMIN role
        ERC1155Sale->>ERC1155Sale: Update tokenInfo mapping
        ERC1155Sale->>ERC1155Sale: Emit TokenConfigUpdated event
    else
        ERC1155Sale-->>-User: Revert
    end
    
    User->>+ERC1155Sale: setFee(...)
    alt TOKEN_GOVERNOR or ADMIN role
        ERC1155Sale->>ERC1155Sale: Update tokenInfo mapping
        ERC1155Sale->>ERC1155Sale: Emit FeeUpdated event
    else
        ERC1155Sale-->>-User: Revert 
    end

    User->>+ERC1155Sale: withdrawERC20(...)
    alt FINANCIAL_CONTROLLER role
        ERC1155Sale->>ERC20: safeTransfer(...)
    else
        ERC1155Sale-->>-User: Revert
    end
```

## Base Contracts
### OpenZeppelin
- [MerkleProof](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol): Enables the verification of Merkle proofs.
- [SafeERC20](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol): Adds safeguards to the standard ERC20 transfer and approve functions.
- [SafeCast](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol): Safely casts between different integer types.
- [IERC20](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol): Interface for the ERC20 standard.
### Protocol Specific
- [Roles](https://github.com/ZTX-Foundation/tuxedo/blob/develop/src/core/Roles.sol): Manages different roles for access control.
- [IWETH](https://github.com/ZTX-Foundation/tuxedo/blob/develop/src/interface/IWETH.sol): Interface for Wrapped Ethereum.
- [CoreRef](https://github.com/ZTX-Foundation/tuxedo/blob/develop/src/refs/CoreRef.sol): Provides a reference to the protocol's core contract.
- [Constants](https://github.com/ZTX-Foundation/tuxedo/blob/develop/src/Constants.sol): Contains various constants used across the protocol.
- [IERC1155Sale](IERC1155Sale.sol): Interface for the ERC1155 sale functionality.
- [ERC1155MaxSupplyMintable](https://github.com/ZTX-Foundation/tuxedo/blob/develop/src/nfts/ERC1155MaxSupplyMintable.sol): An ERC1155 contract that supports minting with a max supply.

## Features
* Merkle Proof Validation: Ensures the legitimacy of purchase requests.
* Safe Transfers: Implements OpenZeppelin's `SafeERC20` to ensure safe transfers of ERC20 tokens.
* Multiple Token Purchases: Allows users to purchase multiple ERC1155 tokens at once.
* Fee Handling: Implements a fee structure for purchases.
* Wrapping ETH: Converts raw Ethereum into WETH (Wrapped ETH).
* Role-based Access Control: Uses OpenZeppelin's Roles system for controlling access to administrative functions.

## Constants
- `MAX_FEE`: Max fee for a purchase.

## Structs
### `TokenInfo`
Stores information related to a specific token, including:
- `tokenPricedIn`: The ERC20 token in which the ERC1155 token is priced.
- `saleStartTime`: The time at which the sale for the ERC1155 token begins.
- `price`: The price of the ERC1155 token.
- `fee`: The fee for the ERC1155 token.
- `overrideMerkleRoot`: Override the merkle root check.
- `merkleRoot`: The default merkle root for a given token.

### `TokenRecipient`
Keeps track of the recipients for token proceeds and fees.
- `proceedsRecipient`: The address to which proceeds from the sale of the token are sent.
- `feeRecipient`: The address to which fees from the sale of the token are sent.
- `unclaimedProceeds`: The amount of proceeds that have not yet been claimed.
- `unclaimedFees`: The amount of fees that have not yet been claimed.

## Constructor
The constructor accepts three arguments:

- `_core`: An address representing the core contract.
- `_nft`: An address representing the ERC1155 contract.
- `_weth`: An address representing the WETH (Wrapped Ethereum) contract.

The constructor doesn't have any explicit modifiers, but it contains checks to ensure non-zero addresses for `_nft` and `_weth`.

## Functions
### `buyTokenWithEth()`
Allows a user to purchase ERC1155 tokens using raw Ethereum, ensures the sale has started and provided ETH matches the calculated total cost, mints the ERC1155 tokens to the recipient and emits a `TokensPurchased` event.

### `buyTokensWithEth()`
Allows a user to bulk purchase multiple ERC1155 tokens using raw Ethereum, validates provided ETH matches the bulk purchase total and mints the ERC1155 tokens in a batch to the recipient.

### `buyToken()`
Allows a user to purchase ERC1155 tokens using ERC20 tokens, ensures the sale has started, checks the approved amount, and transfers ERC20 from the buyer, mints the ERC1155 tokens to the recipient and emits a `TokensPurchased` event.

### `buyTokens()`
Enables bulk purchasing of multiple ERC1155 tokens using ERC20 tokens. Transfers ERC20 tokens from the buyer for each purchase. Mints the ERC1155 tokens in a batch to the recipient.

### `sweepUnclaimed()`
Allows transferring unclaimed fees and proceeds to the respective destinations for a given purchase token and emits two `TokensSwept` events, one for fees and one for proceeds. 

### `wrapEth()`
Admin-only function to convert raw Ethereum held in the contract to WETH (Wrapped Ethereum). 

###  `setTokenRecipients()`
Admin-only function to set recipients for a given purchase token and emits a `TokenRecipientsUpdated` event.

### `setTokenConfig()`
Admin-only function to set the price and configuration of a token in terms of an ERC20 token and emits a `TokenConfigUpdated` event.

###  `setFee()`
Token governor or admin function to set the fee associated with a given ERC1155 token and emits a `FeeUpdated` event.

###  `withdrawERC20()`
A FinancialController-only function used in emergency situations to withdraw ERC20 tokens from the contract. Emits a `WithdrawERC20` event.

###  `_helperBuyWithEth()`
Internal function to facilitate buying with ETH.

### `_arityCheck()`
Private function to ensure consistent array lengths for bulk operations.

### `_buyTokenChecks()`
Internal function for checks and effects when buying tokens.

### `_buyTokenWithEthChecks()`
Private function for specific checks when buying tokens with ETH.

### `getTokenRecipientsAndUnclaimed()`
Fetches token recipients and unclaimed amounts for a given purchase token.

### `getTokenInfo()`
Retrieves information for a given token ID.

### `getPurchasePrice()`
Calculates the purchase price for a token.

###  `getBulkPurchaseTotal()`
Computes the total cost for a bulk purchase.

###  `getMaxMintAmountOut()`
Gets the maximum mint amount remaining for a token.

### `isRootOverriden()`
Checks if the Merkle root for a token is overridden.

## Roles
The contract uses a role-based access control mechanism, primarily through the `Roles` contract. This allows specific operations (like changing token configurations or handling emergencies) to be restricted to certain roles, like `ADMIN`, `TOKEN_GOVERNOR`, and `FINANCIAL_CONTROLLER`. This setup ensures that critical operations can only be executed by trusted entities, adding security and governance to the system.

## Design Rationale
`MerkleProof` ensures that purchase requests are legitimate by allowing for the verification of Merkle proofs. This adds a layer of security to the contract, ensuring that only approved purchases can be made.

`SafeERC20` standardizes ERC20 token transfers, ensuring they execute correctly and securely.

In Solidity, typecasting can lead to overflows or underflows if not done carefully. `SafeCast` provides safe casting methods that revert in case of an overflow or underflow, adding an extra layer of security.

`IERC20` is the standard interface for ERC20 tokens. By adhering to this interface, the contract ensures compatibility with a wide range of ERC20 tokens.

