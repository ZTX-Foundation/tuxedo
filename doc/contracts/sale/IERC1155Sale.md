# IERC1155Sale.sol

## Introduction
An interface for defining how `ERC1155Sale` functions. Please see [ERC1155Sale.sol](./ERC1155Sale.md) for more details.

## Events
### `TokensPurchased`
Emitted when tokens are successfully purchased.
Logs:
- `recipient`: Address receiving the purchased tokens.
- `amount`: Amount of tokens purchased.
- `total`: Total cost (price + fees) of the purchase.

### `TokensSwept`
Emitted when unclaimed fees or proceeds are transferred to their respective destinations.
Logs:
- `recipient`: Address receiving the swept tokens.
- `amount`: Amount of tokens that were swept.

### `TokenRecipientsUpdated`
Emitted when recipients for a given purchase token are set or updated.
Logs:
- `purchaseToken`: Address of the purchase token for which recipients are set.
- `proceedsRecipient`: Address designated to receive the proceeds from the sale.
- `feeRecipient`: Address designated to receive the fees from the sale.

### `TokenConfigUpdated`
Emitted when the configuration (like price, start time, etc.) for a token is set or updated.
Logs:
- `erc1155TokenId`: ID of the ERC1155 token whose configuration is updated.
- `erc20TokenAddress`: Address of the ERC20 token in which the ERC1155 token is priced.
- `saleStartTime`: Start time of the sale.
- `price`: Price of the token in terms of the ERC20 token.
- `fee`: Fee associated with the token sale.
- `overrideMerkleRoot`: Boolean indicating if the Merkle root is overridden.
- `merkleRoot`: The Merkle root associated with the token sale.

### `FeeUpdated`
Emitted when the fee for an ERC1155 token is updated.
Logs:
- `tokenId`: ID of the ERC1155 token whose fee is updated.
- `fee`: Updated fee value.

### `WithdrawERC20`
Emitted when ERC20 tokens are withdrawn from the contract, typically in emergency situations.
Logs:
- `caller`: Address that initiated the withdrawal.
- `token`: Address of the ERC20 token that's withdrawn.
- `to`: Destination address receiving the withdrawn tokens.
- `amount`: Amount of tokens that were withdrawn.
