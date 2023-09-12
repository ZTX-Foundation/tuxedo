pragma solidity 0.8.18;

import "@forge-std/console.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SeasonsBase} from "@protocol/nfts/seasons/SeasonsBase.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";

struct TokenIdRewardAmount {
    uint256 tokenId;
    uint256 tokenSupply;
    uint256 rewardAmount;
}

contract ERC1155SeasonOne is SeasonsBase {
    using SafeERC20 for IERC20;

    mapping(uint256 tokenId => uint256 rewardAmount) public tokenIdRewardAmount;
    mapping(uint256 tokenId => uint256 tokenSupply) public tokenIdSupply;
    mapping(uint256 tokenId => uint256 usedAmount) public tokenIdUsedAmount;

    constructor(
        address _core,
        address _nftSeasonContract,
        address _rewardToken,
        TokenIdRewardAmount[] memory tokenIdRewardAmounts
    ) SeasonsBase(_core, _nftSeasonContract, _rewardToken) {
        uint256 totalRewardTokenAmount = 0;
        // set tokenIdRewardAmount mapping
        for (uint256 i = 0; i < tokenIdRewardAmounts.length; i++) {
            tokenIdRewardAmount[tokenIdRewardAmounts[i].tokenId] = tokenIdRewardAmounts[i].rewardAmount;
            tokenIdSupply[tokenIdRewardAmounts[i].tokenId] = tokenIdRewardAmounts[i].tokenSupply;

            // Running total of totalPaymentToken amount needed by the contract to be solvent
            totalRewardTokenAmount += (tokenIdRewardAmounts[i].rewardAmount * tokenIdRewardAmounts[i].tokenSupply);
        }
        totalRewardTokens = totalRewardTokenAmount;
    }
}
