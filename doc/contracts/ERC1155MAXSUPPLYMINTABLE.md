# ERC1155MaxSupplyMintable Contract Documentation

The `ERC1155MaxSupplyMintable` contract is an ERC1155 compliant token contract with the ability to set maximum supply caps for each token. It allows minting of tokens up to the specified maximum supply and provides functionality for managing token metadata and supply limits. The contract inherits from `ERC1155Supply`, `ERC1155Burnable`, and `CoreRef`.

## Roles Required

The following role is required for this contract to function correctly:

- `LOCKER`: The role that is required to use the global reentrancy lock.

## Events

The contract emits the following events:

3. `SupplyCapUpdated(tokenId, previousMaxSupply, maxSupply)`: Emits when a token's supply cap is updated.

   - `tokenId`: The id of the token to update.
   - `previousMaxSupply`: The previous maximum supply of the token.
   - `maxSupply`: The new maximum supply of the token.

4. `URIUpdated(newuri)`: Emits when the URI is updated for a token.

   - `newuri`: The new URI for the tokens.

5. `TokenMinted(account, tokenId, amount)`: Emits when a token is minted.

   - `account`: The address of the recipient who received the minted tokens.
   - `tokenId`: The id of the minted token.
   - `amount`: The amount of tokens minted.

6. `TokenBurned(account, tokenId, amount)`: Emits when a token is burned.

   - `account`: The address of the account from which tokens were burned.
   - `tokenId`: The id of the burned token.
   - `amount`: The amount of tokens burned.

7. `BatchMinted(account, tokenIds, amounts)`: Emits when a batch of tokens are minted.

   - `account`: The address of the recipient who received the minted tokens.
   - `tokenIds`: An array of token ids that were minted.
   - `amounts`: An array of corresponding amounts of tokens minted.

## Functions

The contract provides the following functions:

1. `setSupplyCap(tokenId, maxSupply)`: Sets the supply cap for a given token.

   - `tokenId`: The id of the token to update the supply cap.
   - `maxSupply`: The new maximum supply of the token.

   This function can only be called by an address with the `ADMIN` role.

2. `setURI(newuri)`: Sets the URI (metadata) for the tokens.

   - `newuri`: The new URI for the tokens.

   This function can only be called by an address with the `ADMIN` role.

3. `mint(recipient, tokenId, amount)`: Mints tokens up to the maximum supply for a specific token.

   - `recipient`: The address to mint tokens to.
   - `tokenId`: The id of the token to mint.
   - `amount`: The amount of tokens to mint.

   This function can only be called by an address with the `MINTER` role. It can only be accessed if the global lock is at level 1.

4. `mintBatch(recipient, tokenIds, amounts)`: Mints a batch of tokens up to their respective maximum supplies.

   - `recipient`: The address to mint tokens to.
   - `tokenIds`: An array of token ids to mint.
   - `amounts`: An array of corresponding amounts of tokens to mint.

   This function can only be called by an address with the `MINTER` role. It can only be accessed if the global

 lock is at level 1.

5. `getMintAmountLeft(tokenId)`: Returns the amount of tokens left to mint from the maximum supply.

   - `tokenId`: The id of the token to query.

   This function is a view-only function and does not modify the contract state.

6. `_beforeTokenTransfer(operator, from, to, ids, amounts, data)`: Internal override function to disallow sending of tokens to the token contract itself.

   - `operator`: The address performing the token transfer.
   - `from`: The address transferring tokens from.
   - `to`: The address receiving tokens.
   - `ids`: An array of token ids being transferred.
   - `amounts`: An array of corresponding amounts of tokens being transferred.
   - `data`: Additional data associated with the token transfer.

   This function is internally used to handle token transfers and cannot be called directly.