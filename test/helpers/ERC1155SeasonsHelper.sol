pragma solidity 0.8.18;

import "@forge-std/Test.sol";
import {TokenIdRewardAmount} from "@protocol/nfts/seasons/SeasonsBase.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

library ERC1155SeaonsHelperLib {
    /// @dev helper to calculate the total reward amount needed for a season
    function calulateTotalRewardAmount(
        TokenIdRewardAmount[] memory tokenIdRewardAmounts,
        ERC1155MaxSupplyMintable _capsuleNFT
    ) public view returns (uint256) {
        uint256 totalNeeded = 0;
        for (uint256 i = 0; i < tokenIdRewardAmounts.length; i++) {
            uint _maxTokenSupply = _capsuleNFT.maxTokenSupply(tokenIdRewardAmounts[i].tokenId);
            totalNeeded += (tokenIdRewardAmounts[i].rewardAmount * _maxTokenSupply);
        }
        return totalNeeded;
    }
}
