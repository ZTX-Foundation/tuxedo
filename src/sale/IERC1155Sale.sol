// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

// Interface for the ERC1155Sale Contract
interface IERC1155Sale {
    /// --------------- EVENTS ---------------

    /// @notice event emitted when a token's config is updated
    event TokenConfigUpdated(
        uint256 indexed erc1155TokenId,
        address indexed token,
        uint96 saleStartTime,
        uint240 price,
        uint16 fee,
        bool overrideMerkleRoot,
        bytes32 merkleRoot
    );

    /// @notice event emitted when a token's recipients are updated
    event TokenRecipientsUpdated(address indexed purchaseToken, address proceedsRecipient, address feeRecipient);

    /// @notice event emitted when tokens are purchased
    event TokensPurchased(address indexed recipient, uint256 amountPurchased, uint256 amountSpent);

    /// @notice event emitted when tokens are swept
    event TokensSwept(address indexed recipient, uint256 amount);

    /// @notice event emitted when the merkle root is set
    event MerkleRootSet(uint256 tokenId, bytes32 merkleRoot);

    /// @notice event emitted when a token is withdrawn via withdrawERC20
    event WithdrawERC20(address indexed caller, address indexed token, address indexed to, uint256 amount);

    /// @notice event emitted when the fee is updated
    event FeeUpdated(uint256 tokenId, uint16 fee);

    /// @notice maximum fee is 50%
    // solhint-disable-next-line
    function MAX_FEE() external view returns (uint256);

    /// --------------- PUBLIC STATE CHANGING API ---------------

    /// @notice buy tokens with raw eth
    /// @param erc1155TokenId the id of the token to buy
    /// @param amountToPurchase the amounts of the token to buy
    /// @param approvedAmount the amounts of the tokens to buy
    /// @param merkleProof the merkle proof for the token to buy
    /// @param recipient the address to send the ERC11-55 tokens
    /// @dev locks up to level 1 and pauseable
    function buyTokenWithEth(
        uint256 erc1155TokenId,
        uint256 amountToPurchase,
        uint256 approvedAmount,
        bytes32[] calldata merkleProof,
        address recipient
    ) external payable returns (uint256);

    /// @notice buy tokens with raw eth
    /// @param erc1155TokenIds the ids of the tokens to buy
    /// @param amountsToPurchase the amounts of the tokens to buy
    /// @param approvedAmounts the amounts of the tokens to buy
    /// @param merkleProofs the merkle proofs for the tokens to buy
    /// @param recipient the address to send the ERC11-55 tokens
    function buyTokensWithEth(
        uint256[] calldata erc1155TokenIds,
        uint256[] calldata amountsToPurchase,
        uint256[] calldata approvedAmounts,
        bytes32[][] calldata merkleProofs,
        address recipient
    ) external payable returns (uint256);

    /// @notice buy ERC1155 tokens in exchange for ERC20 tokens
    /// @param erc1155TokenId the id of the token to buy
    /// @param amountToPurchase the amounts of the token to buy
    /// @param approvedAmount the amounts of the tokens to buy
    /// @param merkleProof the merkle proof for the token to buy
    /// @param recipient the address to send the ERC11-55 tokens
    /// @return The amount of purchaseToken paid.
    function buyToken(
        uint256 erc1155TokenId,
        uint256 amountToPurchase,
        uint256 approvedAmount,
        bytes32[] calldata merkleProof,
        address recipient
    ) external returns (uint256);

    /// @notice buy ERC1155 tokens in exchange for ERC20 tokens
    /// @param erc1155TokenIds the ids of the tokens to buy
    /// @param amountsToPurchase the amounts of the tokens to buy
    /// @param approvedAmounts the amounts of the tokens to buy
    /// @param merkleProofs the merkle proofs for the tokens to buy
    /// @param recipient the address to send the ERC11-55 tokens
    function buyTokens(
        uint256[] calldata erc1155TokenIds,
        uint256[] calldata amountsToPurchase,
        uint256[] calldata approvedAmounts,
        bytes32[][] calldata merkleProofs,
        address recipient
    ) external;

    /// @notice sweep fees to respective destinations
    /// @param purchaseToken the purchaseToken token to sweep
    function sweepUnclaimed(address purchaseToken) external;

    /// --------------- ADMIN ONLY API ---------------

    /// @notice Set the price of an ERC1155 token in terms of an ERC20 token.
    /// @param erc1155TokenId The ID of the ERC1155 token being sold.
    /// @param erc20TokenAddress The address of the ERC20 token users will pay in exchange for the ERC1155 token.
    /// @param saleStartTime the start time of the sale
    /// @param price The price of the ERC1155 token in terms of the ERC20 token.
    /// @param fee The fee taken by the sale contract when a user buys the ERC1155 token.
    /// @param overrideMerkleRoot whether or not to override the merkle root
    /// @param merkleRoot the merkle root of the token sale
    function setTokenConfig(
        uint256 erc1155TokenId,
        address erc20TokenAddress,
        uint96 saleStartTime,
        uint232 price,
        uint16 fee,
        bool overrideMerkleRoot,
        bytes32 merkleRoot
    ) external;

    /// @notice set the recipients for a given purchaseToken token
    /// callable only by admin
    /// @param purchaseToken the token to set the recipients for
    /// @param proceedsRecipient the address to send proceeds to
    /// @param feeRecipient the address to send fees to
    function setTokenRecipients(address purchaseToken, address proceedsRecipient, address feeRecipient) external;

    /// --------------- TOKEN GOVERNOR and ADMIN API ---------------

    /// @notice set the fee of purchasing an ERC1155 token
    /// callable by token governor and admin
    /// @param tokenId the id of the token to set the price for
    /// @param fee the fee to charge for buying the token
    function setFee(uint256 tokenId, uint16 fee) external;

    /// --------------- FINANCIAL CONTROLLER ONLY API ---------------

    /// @notice withdraw ERC20 from the contract
    /// @param token address of the ERC20 to send
    /// @param to address destination of the ERC20
    /// @param amount quantity of ERC20 to send
    function withdrawERC20(address token, address to, uint256 amount) external;
}
