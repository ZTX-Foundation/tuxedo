// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Roles} from "@protocol/core/Roles.sol";
import {IWETH} from "@protocol/interface/IWETH.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {Constants} from "@protocol/Constants.sol";
import {IERC1155Sale} from "@protocol/sale/IERC1155Sale.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

/// @dev Base ERC 1155 NFT with total supply
/// Inherits CoreRef for roles and access
/// requires locker and minter role
/// Warning: using the emergency action or withdrawERC20 function to withdraw funds from this contract
/// will completely brick the sweep function as the internal accounting will be incorrect
contract ERC1155Sale is IERC1155Sale, CoreRef {
    using SafeERC20 for *;
    using SafeCast for uint256;

    /// --------------- STRUCTS ---------------

    /// @notice token info
    struct TokenInfo {
        /// storage slot 1
        address tokenPricedIn; /// 20 bytes
        uint96 saleStartTime; /// 12 bytes
        /// storage slot 2
        uint232 price;
        uint16 fee;
        bool overrideMerkleRoot;
        /// storage slot 3
        bytes32 merkleRoot;
    }

    /// @notice token info for a given token users purchase with
    struct TokenRecipient {
        /// 1st storage slots
        address proceedsRecipient;
        /// 2nd storage slots
        address feeRecipient;
        /// 3rd storage slot
        uint128 unclaimedProceeds;
        uint128 unclaimedFees;
    }

    /// --------------- STATE VARIABLES ---------------

    /// @notice maximum fee is 50%
    uint256 public constant override MAX_FEE = 5_000;

    /// @notice the wearable NFT contract tokens will be minted from
    /// immutable because a pop and shift architecture allows us to redeploy another sale contract
    /// if we want to make another
    ERC1155MaxSupplyMintable public immutable nft;

    /// @notice pointer to the WETH token
    IWETH public immutable weth;

    /// @notice token info for a given token id
    mapping(uint256 tokenId => TokenInfo tokenPurchaseInfo) public tokenInfo;

    /// @notice token id to purchaser to amount purchased
    mapping(uint256 tokenId => mapping(address account => uint256 tokensPurchased)) public purchased;

    /// @notice purchaseToken address to token recipients and unclaimed amounts
    mapping(address purchaseToken => TokenRecipient) public tokenRecipients;

    /// @notice construct the sale contract with a reference to the ERC1155 total supply and CoreRef
    /// @param _core the address of the core contract
    /// @param _nft the address of the ERC1155 contract
    constructor(address _core, address _nft, address _weth) CoreRef(_core) {
        require(_nft != address(0), "ERC1155Sale: nft cannot be address(0)");
        require(_weth != address(0), "ERC1155Sale: weth cannot be address(0)");

        nft = ERC1155MaxSupplyMintable(_nft);
        weth = IWETH(_weth);
    }

    /// --------------- VIEW ONLY API ---------------

    /// @notice get the token info for a given purchaseToken
    /// @param purchaseToken token to get the info for
    function getTokenRecipientsAndUnclaimed(
        address purchaseToken
    )
        external
        view
        returns (address proceedsRecipient, address feeRecipient, uint128 unclaimedProceeds, uint128 unclaimedFees)
    {
        TokenRecipient memory recipient = tokenRecipients[purchaseToken];
        proceedsRecipient = recipient.proceedsRecipient;
        feeRecipient = recipient.feeRecipient;
        unclaimedProceeds = recipient.unclaimedProceeds;
        unclaimedFees = recipient.unclaimedFees;
    }

    /// @notice get the token info for a given token id
    /// @param tokenId token id to get the info for
    function getTokenInfo(
        uint256 tokenId
    )
        external
        view
        returns (
            address tokenPricedIn,
            uint96 saleStartTime,
            uint232 price,
            uint16 fee,
            bool overrideMerkleRoot,
            bytes32 merkleRoot
        )
    {
        TokenInfo memory info = tokenInfo[tokenId];
        tokenPricedIn = info.tokenPricedIn;
        saleStartTime = info.saleStartTime;
        price = info.price;
        fee = info.fee;
        overrideMerkleRoot = info.overrideMerkleRoot;
        merkleRoot = info.merkleRoot;
    }

    /// @notice get the purchase price of a given token
    /// @param tokenId token id to get the price for
    /// @param amountToPurchase the amount of the token to purchase
    /// returns the total price, the purchase price, and the fee amount
    function getPurchasePrice(
        uint256 tokenId,
        uint256 amountToPurchase
    ) public view returns (uint256 total, uint256 purchasePrice, uint256 fees) {
        TokenInfo memory info = tokenInfo[tokenId];
        purchasePrice = amountToPurchase * info.price;
        fees = (purchasePrice * info.fee) / Constants.BASIS_POINTS_GRANULARITY;
        total = purchasePrice + fees;
    }

    /// @notice get the total price of a bulk purchase
    /// do not use this for bulk purchases with different underlying token values
    /// @param erc1155TokenIds the ids of the tokens to buy
    /// @param amountsToPurchase the amounts of the tokens to buy
    function getBulkPurchaseTotal(
        uint256[] calldata erc1155TokenIds,
        uint256[] calldata amountsToPurchase
    ) public view returns (uint256 total) {
        for (uint256 i = 0; i < erc1155TokenIds.length; i++) {
            (uint256 _total, , ) = getPurchasePrice(erc1155TokenIds[i], amountsToPurchase[i]);
            total += _total;
        }
    }

    /// @notice the maximum mint amount out
    /// @param tokenId of asset to get max amount of tokens left for purchase
    function getMaxMintAmountOut(uint256 tokenId) external view returns (uint256) {
        return nft.getMintAmountLeft(tokenId);
    }

    /// @notice check whether a root is overriden
    /// @param tokenId of asset to check
    function isRootOverriden(uint256 tokenId) external view returns (bool) {
        return tokenInfo[tokenId].overrideMerkleRoot;
    }

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
    ) external payable override whenNotPaused globalLock(1) returns (uint256 total) {
        (uint256 totalCost, , ) = getPurchasePrice(erc1155TokenId, amountToPurchase);
        /// user must pay fee amount + total cost
        require(msg.value == totalCost, "ERC1155Sale: incorrect eth value");

        total = _helperBuyWithEth(erc1155TokenId, amountToPurchase, approvedAmount, merkleProof);

        nft.mint(recipient, erc1155TokenId, amountToPurchase); /// trusted contract, can make untrusted calls via annoying after transfer hook

        emit TokensPurchased(recipient, amountToPurchase, total);
    }

    /// @notice buy tokens with raw eth
    /// @param erc1155TokenIds the ids of the tokens to buy
    /// @param amountsToPurchase the amounts of the tokens to buy
    /// @param approvedAmounts the amounts of the tokens to buy
    /// @param merkleProofs the merkle proofs for the tokens to buy
    /// @param recipient the address to send the ERC1155 tokens
    /// @dev locks up to level 1 and pauseable
    function buyTokensWithEth(
        uint256[] calldata erc1155TokenIds,
        uint256[] calldata amountsToPurchase,
        uint256[] calldata approvedAmounts,
        bytes32[][] calldata merkleProofs,
        address recipient
    ) external payable override whenNotPaused globalLock(1) returns (uint256) {
        /// checks
        _arityCheck(erc1155TokenIds, amountsToPurchase, approvedAmounts, merkleProofs);

        uint256 total = getBulkPurchaseTotal(erc1155TokenIds, amountsToPurchase);
        require(msg.value == total, "ERC1155Sale: incorrect eth value");

        unchecked {
            for (uint256 i = 0; i < erc1155TokenIds.length; i++) {
                /// checks and effects
                _helperBuyWithEth(erc1155TokenIds[i], amountsToPurchase[i], approvedAmounts[i], merkleProofs[i]);
            }
        }

        /// interactions
        nft.mintBatch(recipient, erc1155TokenIds, amountsToPurchase); /// trusted contract, can make untrusted calls via annoying after transfer hook

        return total;
    }

    function _helperBuyWithEth(
        uint256 erc1155TokenId,
        uint256 amountToPurchase,
        uint256 approvedAmount,
        bytes32[] calldata merkleProof
    ) private returns (uint256) {
        (uint256 total, address purchaseToken) = _buyTokenChecks(
            erc1155TokenId,
            amountToPurchase,
            approvedAmount,
            merkleProof
        );

        /// purchaseToken for tokenId must be weth
        require(purchaseToken == address(weth), "ERC1155Sale: purchase token token must be weth");

        return total;
    }

    function _arityCheck(
        uint256[] calldata erc1155TokenIds,
        uint256[] calldata amountsToPurchase,
        uint256[] calldata approvedAmounts,
        bytes32[][] calldata merkleProofs
    ) private pure {
        require(erc1155TokenIds.length == amountsToPurchase.length, "ERC1155Sale: arity mismatch 0");
        require(erc1155TokenIds.length == approvedAmounts.length, "ERC1155Sale: arity mismatch 1");
        require(erc1155TokenIds.length == merkleProofs.length, "ERC1155Sale: arity mismatch 2");
    }

    /// @notice buy ERC1155 tokens in exchange for ERC20 tokens
    /// @param erc1155TokenId the id of the token to buy
    /// @param amountToPurchase the amounts of the token to buy
    /// @param approvedAmount the amounts of the tokens to buy
    /// @param merkleProof the merkle proof for the token to buy
    /// @param recipient the address to send the ERC11-55 tokens
    /// @dev locks up to level 1 and pauseable
    function buyToken(
        uint256 erc1155TokenId,
        uint256 amountToPurchase,
        uint256 approvedAmount,
        bytes32[] calldata merkleProof,
        address recipient
    ) external override whenNotPaused globalLock(1) returns (uint256) {
        (uint256 total, address purchaseToken) = _buyTokenChecks(
            erc1155TokenId,
            amountToPurchase,
            approvedAmount,
            merkleProof
        );

        /// user must pay fee amount + total cost
        IERC20(purchaseToken).safeTransferFrom(msg.sender, address(this), total); /// untrusted contract

        nft.mint(recipient, erc1155TokenId, amountToPurchase); /// trusted contract, can make untrusted calls via annoying after transfer hook

        emit TokensPurchased(recipient, amountToPurchase, total);

        return total;
    }

    /// @notice buy ERC1155 tokens in exchange for ERC20 tokens
    /// @param erc1155TokenIds the ids of the tokens to buy
    /// @param amountsToPurchase the amounts of the tokens to buy
    /// @param approvedAmounts the amounts of the tokens to buy
    /// @param merkleProofs the merkle proofs for the tokens to buy
    /// @param recipient the address to send the ERC11-55 tokens
    /// @dev locks up to level 1 and pauseable
    function buyTokens(
        uint256[] calldata erc1155TokenIds,
        uint256[] calldata amountsToPurchase,
        uint256[] calldata approvedAmounts,
        bytes32[][] calldata merkleProofs,
        address recipient
    ) external override whenNotPaused globalLock(1) {
        _arityCheck(erc1155TokenIds, amountsToPurchase, approvedAmounts, merkleProofs);

        unchecked {
            for (uint256 i = 0; i < erc1155TokenIds.length; i++) {
                /// checks and effects
                (uint256 cost, address purchaseToken) = _buyTokenChecks(
                    erc1155TokenIds[i],
                    amountsToPurchase[i],
                    approvedAmounts[i],
                    merkleProofs[i]
                );

                /// Interactions

                /// user must pay fee amount + total cost
                //slither-disable-next-line
                IERC20(purchaseToken).safeTransferFrom(msg.sender, address(this), cost); /// untrusted contract

                emit TokensPurchased(recipient, amountsToPurchase[i], cost);
            }
        }

        nft.mintBatch(recipient, erc1155TokenIds, amountsToPurchase); /// trusted contract, can make untrusted calls via annoying after transfer hook
    }

    /// @notice helper function to buy tokens with underlying ERC20
    /// @param erc1155TokenId the id of the token to buy
    /// @param amountToPurchase the amounts of the token to buy
    /// @param approvedAmount the amounts of the tokens to buy
    /// @param merkleProof the merkle proof for the token to buy
    function _buyTokenChecks(
        uint256 erc1155TokenId,
        uint256 amountToPurchase,
        uint256 approvedAmount,
        bytes32[] calldata merkleProof
    ) private returns (uint256 totalCost, address purchaseToken) {
        /// Checks around purchased amount and merkle root, saves SLOADs on failure cases
        /// if we aren't overriding the root, check the proof, approved amounts and
        /// purchased amounts if we did override the root, we don't need to check the proof
        if (!tokenInfo[erc1155TokenId].overrideMerkleRoot) {
            bytes32 node = keccak256(abi.encode(keccak256(abi.encode(msg.sender, approvedAmount))));

            require(
                MerkleProof.verify(merkleProof, tokenInfo[erc1155TokenId].merkleRoot, node),
                "ERC1155Sale: invalid proof"
            );
            require(
                purchased[erc1155TokenId][msg.sender] + amountToPurchase <= approvedAmount,
                "ERC1155Sale: purchased amount exceeds approved amount"
            );
        }

        uint256 cost;
        uint256 feeAmount;

        purchaseToken = tokenInfo[erc1155TokenId].tokenPricedIn;
        (totalCost, cost, feeAmount) = getPurchasePrice(erc1155TokenId, amountToPurchase);
        TokenRecipient storage tokenRecipient = tokenRecipients[purchaseToken];

        /// Checks

        require(tokenInfo[erc1155TokenId].saleStartTime <= block.timestamp, "ERC1155Sale: sale has not started"); /// start time must be either right now or in the past
        require(tokenRecipient.proceedsRecipient != address(0), "ERC1155Sale: no recipient set");
        require(tokenRecipient.feeRecipient != address(0), "ERC1155Sale: no fee recipient set");
        require(cost != 0, "ERC1155Sale: no token out"); /// covers price not set and 0 amountToPurchase

        /// Effects

        {
            uint128 unclaimedProceeds128 = cost.toUint128();
            uint128 unclaimedFees128 = feeAmount.toUint128();

            /// single SSTORE
            tokenRecipient.unclaimedProceeds += unclaimedProceeds128;
            tokenRecipient.unclaimedFees += unclaimedFees128;
        }

        /// save an SSTORE if we override merkle validation logic
        if (!tokenInfo[erc1155TokenId].overrideMerkleRoot) {
            purchased[erc1155TokenId][msg.sender] += amountToPurchase;

            /// assertion for SMT solver
            assert(purchased[erc1155TokenId][msg.sender] <= approvedAmount);
        }
    }

    /// @notice sweep fees to respective destinations
    /// @param purchaseToken the purchaseToken token to sweep
    function sweepUnclaimed(address purchaseToken) external override {
        /// get storage reference as we need to zero unclaimed amounts
        TokenRecipient storage recipient = tokenRecipients[purchaseToken];

        uint256 feeAmount = recipient.unclaimedFees;
        uint256 proceedsAmount = recipient.unclaimedProceeds;

        /// Checks
        /// validate purchaseToken token is correct
        require(feeAmount != 0 && proceedsAmount != 0, "ERC1155Sale: nothing to pay");
        require(
            recipient.proceedsRecipient != address(0) && recipient.feeRecipient != address(0),
            "ERC1155Sale: no recipient set"
        );

        /// Effects
        recipient.unclaimedFees = 0;
        recipient.unclaimedProceeds = 0;

        /// Interactions
        IERC20(purchaseToken).safeTransfer(recipient.feeRecipient, feeAmount);
        IERC20(purchaseToken).safeTransfer(recipient.proceedsRecipient, proceedsAmount);

        emit TokensSwept(recipient.feeRecipient, feeAmount);
        emit TokensSwept(recipient.proceedsRecipient, proceedsAmount);
    }

    /// @notice turn raw eth into wrapped eth
    function wrapEth() external onlyRole(Roles.ADMIN) {
        //slither-disable-next-line arbitrary-send-eth
        weth.deposit{value: address(this).balance}();
    }

    /// --------------- ADMIN ONLY API ---------------

    /// @notice set the recipients for a given purchaseToken token
    /// callable only by admin
    /// @param purchaseToken the purchaseToken token to set the recipients for
    /// @param proceedsRecipient the address to send proceeds to
    /// @param feeRecipient the address to send fees to
    function setTokenRecipients(
        address purchaseToken,
        address proceedsRecipient,
        address feeRecipient
    ) external onlyRole(Roles.ADMIN) {
        TokenRecipient storage recipient = tokenRecipients[purchaseToken];
        recipient.proceedsRecipient = proceedsRecipient;
        recipient.feeRecipient = feeRecipient;

        emit TokenRecipientsUpdated(purchaseToken, proceedsRecipient, feeRecipient);
    }

    /// @notice set the price of a token in terms of an purchaseToken ERC20 token
    /// callable only by admin
    /// @param erc1155TokenId the id of the token to set the price for
    /// @param erc20TokenAddress the address of the purchaseToken ERC20 token
    /// @param saleStartTime the start time of the sale
    /// @param price the price of the token in terms of the purchaseToken ERC20 token
    /// @param fee the fee to charge for buying the token
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
    ) external onlyRole(Roles.ADMIN) {
        require(saleStartTime > block.timestamp, "ERC1155Sale: sale must start in the future");
        require(fee != 0, "ERC1155Sale: fee cannot be 0");
        require(fee <= MAX_FEE, "ERC1155Sale: fee cannot exceed max");

        TokenInfo storage info = tokenInfo[erc1155TokenId];

        info.tokenPricedIn = erc20TokenAddress;
        info.saleStartTime = saleStartTime;
        info.price = price;
        info.fee = fee;
        info.overrideMerkleRoot = overrideMerkleRoot;
        info.merkleRoot = merkleRoot;

        emit TokenConfigUpdated(
            erc1155TokenId,
            erc20TokenAddress,
            saleStartTime,
            price,
            fee,
            overrideMerkleRoot,
            merkleRoot
        );
    }

    /// --------------- TOKEN GOVERNOR and ADMIN API ---------------

    /// @notice set the fee of purchasing an ERC1155 token
    /// callable by token governor and admin
    /// @param tokenId the id of the token to set the price for
    /// @param fee the fee to charge for buying the token
    function setFee(uint256 tokenId, uint16 fee) external override hasAnyOfTwoRoles(Roles.TOKEN_GOVERNOR, Roles.ADMIN) {
        require(tokenInfo[tokenId].saleStartTime != 0, "ERC1155Sale: asset not listed");
        require(fee != 0, "ERC1155Sale: fee cannot be 0");
        require(fee <= MAX_FEE, "ERC1155Sale: fee cannot exceed max");

        tokenInfo[tokenId].fee = fee;

        emit FeeUpdated(tokenId, fee);
    }

    /// --------------- FINANCIAL CONTROLLER ONLY API ---------------

    /// @dev WARNING, ONLY USE THIS FUNCTION THROUGH THE FINANCE GUARDIAN
    /// IN AN EMERGENCY SITUATION. OTHERWISE THIS WILL MESS UP ACCOUNTING
    /// IN THE CONTRACT AND PREVENT THE SWEEP FUNCTION FROM WORKING
    /// @notice withdraw ERC20 from the contract
    /// @param token address of the ERC20 to send
    /// @param to address destination of the ERC20
    /// @param amount quantity of ERC20 to send
    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) public override onlyRole(Roles.FINANCIAL_CONTROLLER) whenNotPaused {
        IERC20(token).safeTransfer(to, amount);
        emit WithdrawERC20(msg.sender, token, to, amount);
    }
}
