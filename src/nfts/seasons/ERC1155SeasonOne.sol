pragma solidity 0.8.18;

import "@forge-std/console.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SeasonsBase} from "@protocol/nfts/seasons/SeasonsBase.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

struct TokenIdRewardAmount {
    uint256 tokenId;
    uint256 rewardAmount;
}

contract ERC1155SeasonOne is SeasonsBase {
    using SafeERC20 for IERC20;

    mapping(uint256 tokenId => uint256 rewardAmount) public tokenIdRewardAmount;
    mapping(uint256 tokenId => uint256 usedAmount) public tokenIdUsedAmount;

    constructor(
        address _core,
        address _nftContract,
        address _rewardToken
    ) SeasonsBase(_core, _nftContract, _rewardToken) {}

    /// @notice config the season distribution
    /// @dev _nftContract much have setSupplyCap() set or this tx will revert.
    function configSeasonDistribution(
        TokenIdRewardAmount[] memory tokenIdRewardAmounts
    ) external whenNotPaused onlyRole(Roles.ADMIN) returns (uint256) {
        uint256 _totalRewardTokens = 0;
        // set tokenIdRewardAmount mapping
        for (uint256 i = 0; i < tokenIdRewardAmounts.length; i++) {
            require(tokenIdRewardAmounts[i].rewardAmount > 0, "ERC1155SeasonOne: rewardAmount cannot be 0");
            tokenIdRewardAmount[tokenIdRewardAmounts[i].tokenId] = tokenIdRewardAmounts[i].rewardAmount;

            uint _maxTokenSupply = ERC1155MaxSupplyMintable(nftContract).maxTokenSupply(
                tokenIdRewardAmounts[i].tokenId
            );
            require(_maxTokenSupply != 0, "ERC1155SeasonOne: maxTokenSupply cannot be 0");

            // Running total of totalPaymentToken amount needed by the contract to be solvent
            _totalRewardTokens += (tokenIdRewardAmounts[i].rewardAmount * _maxTokenSupply);
        }
        totalRewardTokens = _totalRewardTokens;
        return totalRewardTokens;
    }

    function redeem(uint256 tokenId) public {
        /// ---- checks ---- ///
        require(solvent(), "ERC1155SeasonOne: Contract Not solvent");
        require(tokenIdRewardAmount[tokenId] > 0, "ERC1155SeasonOne: No redeemable tokens for given tokenId");
        require(
            ERC1155MaxSupplyMintable(nftContract).balanceOf(msg.sender, tokenId) > 0,
            "ERC1155SeasonOne: No capsule available in users wallet"
        );

        /// ---- effects ---- ///
        uint256 _rewardAmount = tokenIdRewardAmount[tokenId];

        // Increase the counter for the amount of reward tokens used
        tokenIdUsedAmount[tokenId] += _rewardAmount;

        // Update total reward tokens needed in contract
        totalRewardTokens -= _rewardAmount;

        /// ---- interaction ---- ///
        // Transfer
        nftContract.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");

        // Burn
        nftContract.burn(address(this), tokenId, 1);

        // Release reward tokens
        rewardToken.safeTransfer(msg.sender, _rewardAmount);

        require(solvent(), "Contract not solvent");
    }
}
