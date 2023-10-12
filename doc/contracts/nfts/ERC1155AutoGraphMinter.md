# ERC1155AutoGraphMinter.sol

## Introduction
Its primary purpose is to facilitate the (rate-limited) minting of ERC-1155 tokens.

### Overview
The diagram below provides a visual representation of how `ERC1155AutoGraphMinter.sol` interacts with its various features and dependencies. It primarily shows the flow of actions a user can initiate and how the contract interacts with other referenced contracts and utilities.

#### Top-down
```mermaid
graph TD
    ERC1155AutoGraphMinter --> ECDSA
    ERC1155AutoGraphMinter --> IERC20
    ERC1155AutoGraphMinter --> SafeERC20
    ERC1155AutoGraphMinter --> CoreRef
    ERC1155AutoGraphMinter --> Roles
    ERC1155AutoGraphMinter --> ERC1155MaxSupplyMintable
    ERC1155AutoGraphMinter --> WhitelistedAddresses
    ERC1155AutoGraphMinter --> RateLimited
```

#### Sequence
```mermaid
sequenceDiagram
    participant User as User/Caller
    participant ERC1155AutoGraphMinter
    participant ERC20Token as IERC20
    participant ERC1155MaxSupplyMintable

    User->>ERC1155AutoGraphMinter: constructor(_core, _nftContracts, ...)
    ERC1155AutoGraphMinter->>ERC1155AutoGraphMinter: Initialize variables
    
    User->>ERC1155AutoGraphMinter: mintForFree(recipient, jobId, tokenId, ...)
    alt isExpiryTokenValid
        ERC1155AutoGraphMinter->>ERC1155AutoGraphMinter: _verifyHashAndSignerRoleExpireHashAndDepleteBuffer()
        alt Hash and Signature are Valid
            ERC1155AutoGraphMinter->>ERC1155MaxSupplyMintable: mint(recipient, tokenId, units)
            ERC1155MaxSupplyMintable-->>ERC1155AutoGraphMinter: Mint Successful
            ERC1155AutoGraphMinter-->>ERC1155AutoGraphMinter: Emit ERC1155Minted event
        else
            ERC1155AutoGraphMinter-->>User: Error
        end
    else
        ERC1155AutoGraphMinter-->>User: Error
    end

    User->>ERC1155AutoGraphMinter: mintWithPaymentTokenAsFee(params)
    alt isExpiryTokenValid
        ERC1155AutoGraphMinter->>ERC1155AutoGraphMinter: _mintChecksForPaymentTokenFee(paymentToken, paymentAmount)
        ERC1155AutoGraphMinter->>ERC1155AutoGraphMinter: _verifyHashAndSignerRoleExpireHashAndDepleteBuffer()
        alt Hash and Signature are Valid
            User->>ERC20Token: safeTransferFrom(msg.sender, paymentRecipient, paymentAmount)
            ERC20Token-->>ERC1155AutoGraphMinter: Transfer Successful
            ERC1155AutoGraphMinter->>ERC1155MaxSupplyMintable: mint(recipient, tokenId, units)
            ERC1155MaxSupplyMintable-->>ERC1155AutoGraphMinter: Mint Successful
            ERC1155AutoGraphMinter-->>ERC1155AutoGraphMinter: Emit ERC1155Minted event
        else
            ERC1155AutoGraphMinter-->>User: Error
        end
    else
        ERC1155AutoGraphMinter-->>User: Error
    end

    User->>ERC1155AutoGraphMinter: mintWithEthAsFee(params)
    alt isExpiryTokenValid and msg.value == paymentAmount
        ERC1155AutoGraphMinter->>ERC1155AutoGraphMinter: _verifyHashAndSignerRoleExpireHashAndDepleteBuffer()
        alt Hash and Signature are Valid
            User->>ERC1155AutoGraphMinter: Send Ether
            ERC1155AutoGraphMinter->>ERC1155AutoGraphMinter: Transfer Ether to paymentRecipient
            ERC1155AutoGraphMinter->>ERC1155MaxSupplyMintable: mint(recipient, tokenId, units)
            ERC1155MaxSupplyMintable-->>ERC1155AutoGraphMinter: Mint Successful
            ERC1155AutoGraphMinter-->>ERC1155AutoGraphMinter: Emit ERC1155Minted event
        else
            ERC1155AutoGraphMinter-->>User: Error
        end
    else
        ERC1155AutoGraphMinter-->>User: Error
    end

    User->>ERC1155AutoGraphMinter: mintBatchForFree(nftContract, recipient, inputs)
    ERC1155AutoGraphMinter->>ERC1155AutoGraphMinter: _mintBatch(...)
    ERC1155AutoGraphMinter->>ERC1155MaxSupplyMintable: mintBatch(recipient, tokenIds, units)
    ERC1155MaxSupplyMintable-->>ERC1155AutoGraphMinter: Batch Mint Successful
    ERC1155AutoGraphMinter-->>ERC1155AutoGraphMinter: Emit ERC1155BatchMinted event
    
    User->>ERC1155AutoGraphMinter: mintBatchWithPaymentTokenAsFee(...)
    ERC1155AutoGraphMinter->>ERC1155AutoGraphMinter: _mintBatch(...)
    User->>ERC20Token: safeTransferFrom(msg.sender, paymentRecipient, totalPayment)
    ERC20Token-->>ERC1155AutoGraphMinter: Transfer Successful
    ERC1155AutoGraphMinter->>ERC1155MaxSupplyMintable: mintBatch(recipient, tokenIds, units)
    ERC1155MaxSupplyMintable-->>ERC1155AutoGraphMinter: Batch Mint Successful
    ERC1155AutoGraphMinter-->>ERC1155AutoGraphMinter: Emit ERC1155BatchMinted event
    
    User->>ERC1155AutoGraphMinter: mintBatchWithEthAsFee(...)
    ERC1155AutoGraphMinter->>ERC1155AutoGraphMinter: _mintBatch(...)
    User->>ERC1155AutoGraphMinter: Send Ether (msg.value)
    ERC1155AutoGraphMinter->>ERC1155AutoGraphMinter: Transfer Ether to paymentRecipient
    ERC1155AutoGraphMinter->>ERC1155MaxSupplyMintable: mintBatch(recipient, tokenIds, units)
    ERC1155MaxSupplyMintable-->>ERC1155AutoGraphMinter: Batch Mint Successful
    ERC1155AutoGraphMinter-->>ERC1155AutoGraphMinter: Emit ERC1155BatchMinted event
    
    User->>ERC1155AutoGraphMinter: getHash(input)
    ERC1155AutoGraphMinter-->>User: returns bytes32 hash
    
    User->>ERC1155AutoGraphMinter: recoverSigner(hash, signature)
    ERC1155AutoGraphMinter-->>User: returns address signer
    
    User->>ERC1155AutoGraphMinter: addWhitelistedContract(nftContractAddress)
    ERC1155AutoGraphMinter-->>User: WhitelistedContractAdded Event
    
    User->>ERC1155AutoGraphMinter: removeWhitelistedContract(nftContractAddress)
    ERC1155AutoGraphMinter-->>User: WhitelistedContractRemoved Event
    
    User->>ERC1155AutoGraphMinter: addWhitelistedContracts(whitelistAddresses)
    ERC1155AutoGraphMinter->>ERC1155AutoGraphMinter: _addWhitelistAddresses(...)
    
    User->>ERC1155AutoGraphMinter: removeWhitelistedContracts(whitelistAddresses)
    ERC1155AutoGraphMinter->>ERC1155AutoGraphMinter: _removeWhitelistAddresses(...)
    
    User->>ERC1155AutoGraphMinter: updatePaymentRecipient(_paymentRecipient)
    ERC1155AutoGraphMinter->>ERC1155AutoGraphMinter: Update paymentRecipient
    ERC1155AutoGraphMinter-->>User: PaymentRecipientUpdated Event
    
    User->>ERC1155AutoGraphMinter: updateExpiryTokenHoursValid(_expiryTokenHoursValid)
    ERC1155AutoGraphMinter->>ERC1155AutoGraphMinter: Update expiryTokenHoursValid
```

## Base Contracts
### OpenZeppelin
- [ECDSA](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol): Provides functions related to the Elliptic Curve Digital Signature Algorithm (ECDSA). It's mainly used to handle signatures in Ethereum transactions.
- [SafeERC20](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol): Adds safeguards to the standard ERC20 transfer and approve functions.
- [IERC20](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol): Interface for the ERC20 standard.
### Protocol Specific
- [CoreRef](https://github.com/ZTX-Foundation/tuxedo/blob/develop/src/refs/CoreRef.sol): Provides a reference to the protocol's core contract.
- [Roles](https://github.com/ZTX-Foundation/tuxedo/blob/develop/src/core/Roles.sol): Manages different roles for access control.
- [ERC1155MaxSupplyMintable](https://github.com/ZTX-Foundation/tuxedo/blob/develop/src/nfts/ERC1155MaxSupplyMintable.sol): An extension of the standard ERC-1155 to support minting with a maximum supply.
- [WhitelistedAddreses](https://github.com/ZTX-Foundation/tuxedo/blob/develop/src/utils/extensions/WhitelistedAddreses.sol): Manages a list of approved addresses that are permitted to interact with specific functionalities of the contract.
- [RateLimited](https://github.com/ZTX-Foundation/tuxedo/blob/develop/src/utils/extensions/RateLimited.sol): Implements rate-limiting functionality to prevent abuse of the contract.

## Features
- Provides functions for generating and recovering message hashes and signatures.
- Allows `ADMIN` or `TOKEN_GOVERNOR` to add and remove contract addresses from a whitelist, controlling which NFT contracts are allowed to interact with the contract.
- Time-limited minting.
- Rate-limiting to prevent abuse of the contract.
- Mint with ETH or an ERC20.

## Structs
### `MintBatchParams`
Contains the parameters for minting a batch of NFTs.
- `jobId`: The backend job ID.
- `tokenId`: The ID of the token to mint.
- `units`: The number of tokens to mint.
- `hash`: The hash of the message to be signed.
- `salt`: The salt of the message to be signed.
- `signature`: The signature of the hash.
- `paymentAmount`: The amount to pay for the minting.
- `expiryToken`: The starting timestamp to use when calculating if the mint request has expired.

### `HashInputsParams`
Contains the parameters for generating a hash.
- `recipient`: The address to receive the minted tokens.
- `jobId`: The backend job ID.
- `tokenId`: The ID of the token to mint.
- `units`: The number of tokens to mint.
- `salt`: The salt of the message to be signed.
- `nftContract`: The address of the NFT contract.
- `paymentToken`: The address of the payment token.
- `paymentAmount`: The amount to pay for the minting.
- `expiryToken`: The starting timestamp to use when calculating if the mint request has expired.

### `VerifyInputParams`
Contains the parameters for comparing and validating a hash.
- `inputHash`: The hash of the minting params.
- `jobId`: The backend job ID.
- `generatedHash`: Hash of the message generated by the contract to compare against `inputHash`.
- `signature`: The signature of the hash.
- `units`: The number of tokens to mint.
- `nftContract`: The address of the NFT contract.
- `expiryToken`: The starting timestamp to use when calculating if the mint request has expired.

### `MintWithPaymentTokenAsFeeParams`
Contains the parameters for minting with a payment token as the fee.
- `recipient`: The address to receive the minted tokens.
- `jobId`: The backend job ID.
- `tokenId`: The ID of the token to mint.
- `units`: The number of tokens to mint.
- `hash`: The hash of the message to be signed.
- `salt`: The salt of the message to be signed.
- `signature`: The signature of the hash.
- `nftContract`: The address of the NFT contract.
- `paymentToken`: The address of the payment token.
- `paymentAmount`: The amount to pay for the minting.
- `expiryToken`: The starting timestamp to use when calculating if the mint request has expired.

### `MintWithEthAsFeeParams`
Contains the parameters for minting with ETH as the payment token.
- `recipient`: The address to receive the minted tokens.
- `jobId`: The backend job ID.
- `tokenId`: The ID of the token to mint.
- `units`: The number of tokens to mint.
- `hash`: The hash of the message to be signed.
- `salt`: The salt of the message to be signed.
- `signature`: The signature of the hash.
- `nftContract`: The address of the NFT contract.
- `paymentAmount`: The amount to pay for the minting (in ETH).
- `expiryToken`: The starting timestamp to use when calculating if the mint request has expired.

## Events
These events offer a mechanism to track and audit the various interactions and updates that occur within the `ERC1155AutoGraphMinter` contract.

### `WhitelistedContractAdded`
Emitted when a contract is added to the whitelist.
Logs:
- `nftContract`: The address of the contract that was added to the whitelist.

### `WhitelistedContractRemoved`
Emitted when a contract is removed from the whitelist.
Logs:
- `nftContract`: The address of the contract that was removed from the whitelist.

### `ERC1155Minted`
Emitted when an ERC1155 token is minted.
Logs:
- `nftContract`: The address of the contract that was minted.
- `recipient`: The address of the recipient of the minted token.
- `tokenId`: The ID of the token that was minted.
- `units`: The number of tokens that were minted.

### `ERC1155BatchMinted`
Emitted when a batch of ERC1155 tokens are minted.
Logs:
- `nftContract`: The address of the contract that was minted.
- `recipient`: The address of the recipient of the minted tokens.
- `tokenIds`: The IDs of the tokens that were minted.
- `units`: The number of tokens that were minted.

### `PaymentRecipientUpdated`
Emitted when the payment recipient is updated.
Logs:
- `paymentRecipient`: The address of the new payment recipient.

## Constructor
The constructor accepts six arguments:

- `_core`: The address of the core contract that provides roles and access control.
- `_nftContracts`: An array of addresses representing NFT contracts that will be whitelisted.
- `_replenishRatePerSecond`: The rate at which the rate limit buffer is replenished per second.
- `_bufferCap`: The maximum limit for the rate limit buffer.
- `_paymentRecipient`: The address that will receive payments.
- `_expiryTokenHoursValid`: The validity period (in hours) for an expiry token.

The constructor checks that `_paymentRecipient` is not the zero address and that `_expiryTokenHoursValid` is within a valid range (between 1 and 24 hours), and it initializes several state variables including:

- `paymentRecipient`: Stores the payment recipient's address.
- `expiryTokenHoursValid`: Sets the validity period for an expiry token.
