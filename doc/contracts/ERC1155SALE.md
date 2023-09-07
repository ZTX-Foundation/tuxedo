# ERC1155Sale Contract Documentation

## Contract Overview
The ERC1155Sale contract is a contract that allows users to purchase ERC1155 tokens in exchange for ERC20 tokens or ETH. It provides functions to buy tokens using raw ETH or ERC20 tokens, as well as view functions to retrieve token information and calculate purchase prices. The contract also includes functionality for setting token configurations, managing token recipients, and sweeping unclaimed tokens to their respective destinations.

## Contract Details
- Uses: MerkleProof (from OpenZeppelin), SafeERC20, SafeCast, IERC20, Roles, IWETH, ERC1155MaxSupplyMintable, Constants
- Inheritance: CoreRef, IERC1155Sale
- Roles:
  - ADMIN: Can set token recipients and token configurations, toggle merkle root usage, change/update merkle root, set start time, set fees, set prices, set fee and proceeds recipients, and withdraw ERC20 tokens.
  - TOKEN_GOVERNOR: Can set fees for specific tokens.
  - FINANCIAL_CONTROLLER: Can withdraw ERC20 tokens in emergency situations. This breaks internal accounting and should only be done in case of emergency.

## Structs
1. TokenInfo: Contains information about a token, including the token it is priced in, sale start time, price, fee, overrideMerkleRoot flag, and merkle root.
2. TokenRecipient: Contains information about the recipients of a token, including the proceeds recipient, fee recipient, and unclaimed proceeds and fees.

## State Variables
- MAX_FEE: Maximum fee percentage (50%).
- nft: Reference to the ERC1155MaxSupplyMintable contract for minting tokens.
- weth: Reference to the wrapped ETH (WETH) contract for handling ETH transactions.
- tokenInfo: Mapping of token IDs to TokenInfo structs to store token-specific information.
- purchased: Mapping of token IDs to purchaser addresses to track the amount of tokens purchased by each address.
- tokenRecipients: Mapping of purchaseToken addresses to TokenRecipient structs to store recipient and unclaimed amount information.

## Constructor
- ERC1155Sale: Initializes the ERC1155Sale contract with the address of the core contract, ERC1155 contract whose tokens this contract will sell, and WETH contract.

## View Functions
1. getTokenRecipientsAndUnclaimed: Retrieves the recipients and unclaimed amounts for a given purchaseToken.
2. getTokenInfo: Retrieves the token info for a given token ID.
3. getPurchasePrice: Calculates the total purchase price, purchase price, and fee amount for a given token ID and amount.
4. getBulkPurchaseTotal: Calculates the total price for a bulk purchase of tokens with the same underlying token value.
5. getMaxMintAmountOut: Returns the maximum amount of tokens that can be minted for a given token ID.
6. isRootOverridden: Checks whether the merkle root for a token ID is overridden.

## Public State-Changing Functions
1. buyTokenWithEth: Allows users to buy tokens of a single id with raw ETH. Requires locking and is pausable. Lock level: 1.
2. buyTokensWithEth: Allows users to buy multiple tokens of multiple ids with raw ETH. Requires locking and is pausable. Lock level: 1.
3. buyToken: Allows users to buy tokens from a single id with ERC20 tokens. Requires locking and is pausable. Lock level: 1.
4. buyTokens: Allows users to buy multiple tokens from multiple ids with ERC20 tokens. Requires locking and is pausable. Lock level: 1.
5. wrapEth: Converts any raw ETH held in contract to wrapped ETH (WETH).

## Admin-Only Functions
1. setTokenRecipients: Sets the recipients for a given purchaseToken.
2. setTokenConfig: Sets the token configuration for a token ID, including the purchaseToken, sale start time, price, fee, overrideMerkleRoot flag, and merkle root.
3. setFee: Sets the fee for purchasing a specific token.

## Financial Controller-Only Function
1. withdrawERC20: Allows the financial controller to withdraw ERC20 tokens from the contract. Should only be used in emergency situations as this breaks accounting logic of where funds were supposed to be sent.

## Events

The ERC1155Sale contract emits the following events to provide information about important contract interactions:

1. `TokensPurchased`: Emits when tokens are successfully purchased.
   - Parameters:
     - `recipient`: Address of the recipient who received the tokens.
     - `amountPurchased`: Amount of tokens purchased.
     - `totalCost`: Total cost of the purchase.

2. `TokensSwept`: Emits when unclaimed tokens are successfully swept to their respective recipients.
   - Parameters:
     - `recipient`: Address of the recipient who received the swept tokens.
     - `amount`: Amount of tokens swept.

3. `TokenRecipientsUpdated`: Emits when the recipients for a purchaseToken are updated.
   - Parameters:
     - `purchaseToken`: Address of the purchaseToken token.
     - `proceedsRecipient`: Address of the proceeds recipient.
     - `feeRecipient`: Address of the fee recipient.

4. `TokenConfigUpdated`: Emits when the token configuration is updated for a specific token.
   - Parameters:
     - `tokenId`: ID of the token.
     - `erc20TokenAddress`: Address of the purchaseToken ERC20 token.
     - `saleStartTime`: Start time of the token sale.
     - `price`: Price of the token in terms of the purchaseToken ERC20 token.
     - `fee`: Fee charged for buying the token.
     - `overrideMerkleRoot`: Flag indicating whether the merkle root is overridden.
     - `merkleRoot`: Merkle root of the token sale.

5. `FeeUpdated`: Emits when the fee for purchasing a specific token is updated.
   - Parameters:
     - `tokenId`: ID of the token.
     - `fee`: Updated fee amount.

6. `WithdrawERC20`: Emits when ERC20 tokens are successfully withdrawn from the contract.
   - Parameters:
     - `caller`: Address of the caller who initiated the withdrawal.
     - `token`: Address of the ERC20 token being withdrawn.
     - `to`: Address of the destination where the tokens are transferred.
     - `amount`: Amount of ERC20 tokens being withdrawn.

These events provide transparency and allow offchain tracking and indexing of onchain sale activity.
