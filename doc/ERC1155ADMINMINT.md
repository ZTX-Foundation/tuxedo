# Overview

This document describes how to use the `ERC1155AdminMint` contract to mint ERC1155 tokens.

## Contract

This contract calls into an instance of `ERC1155MaxSupplyMintable`, but first locks up to lock level 1, then calls into the ERC1155 contract and mints the requested amount of tokens, then emits a `TokensMinted` event that specifies the type and amount of tokens that were emitted.

## Usage

First, ensure the supply cap is set for the tokenId being minted. Do this by calling the `setSupplyCap(uint256 tokenId, uint256 maxSupply)` function on the ERC1155 that is being minted. This will set the supply cap for the token type.

Then, call the `mintToken(address nftContract, address recipient uint256 tokenId, uint256 amount)` function on the `ERC1155AdminMint` contract. This will mint the tokens to the specified recipient, and emit a `TokensMinted` event.

Alternatively, you can call the `bulkMintTokens(BulkMint[] toMint)` function to mint multiple tokens to multiple recipients once.

## Gnosis Usage

To use this in Gnosis, navigate to the apps section of the Gnosis UI. Then search `transaction builder`, click into open Safe App.

If the supply cap has not been set for the asset you would like to mint, you will need to set it. To do this, enter the address of the ERC1155 contract you would like to mint from. Then select the function `setSupplyCap(tokenId,maxSupply)`. Now, enter the parameters with the first being the tokenId you would like to mint and the second being the maximum supply for the given tokenId. Then, click `Add transaction`.

Once the supply cap has been set, you will need to mint tokens. If the supply cap needed to be set, the minting can happen in the same transaction. To do this, enter the ERC1155AdminMinter contract and select the function `mintToken(nftContract,recipient,tokenId,amount)`. Now, enter the parameters with the first being the address of the ERC1155 contract you would like to mint from, the second being the address of the recipient, the third being the tokenId you would like to mint (which should have a non zero supply cap), and the fourth being the amount of tokens you would like to mint. Then, click `Add transaction`.

Now click `Create Batch`, click `Simulate` to ensure the transaction succeeds before submitting it for signing, and then if the simulation is successful, click `Send Batch` to allow other signers to sign the transaction in the Safe. If the simulation is unsuccessful, you will need to edit the parameters and try the simulation again before submitting.
