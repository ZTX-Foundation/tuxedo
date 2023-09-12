// SPDX-License-Identifier: UNKNOWN
pragma solidity 0.8.18;

import "@forge-std/console.sol";

import {ERC1155SeasonOne, TokenIdRewardAmount} from "@protocol/nfts/seasons/ERC1155SeasonOne.sol";

import {SeasonBase} from "@test/unit/nfts/seasons/SeasonBase.t.sol";

contract UnitTestERC1155SeasonOne is SeasonBase {
    ERC1155SeasonOne private seasonOne;

    function setUp() public override(SeasonBase) {
        super.setUp();

        TokenIdRewardAmount[] memory tokenIdRewardAmounts = new TokenIdRewardAmount[](3);

        // Set tokenId to Reward Amount.
        tokenIdRewardAmounts[0] = TokenIdRewardAmount({tokenId: 1, tokenSupply: 1000, rewardAmount: 400});
        tokenIdRewardAmounts[1] = TokenIdRewardAmount({tokenId: 2, tokenSupply: 1000, rewardAmount: 1000});
        tokenIdRewardAmounts[2] = TokenIdRewardAmount({tokenId: 3, tokenSupply: 1000, rewardAmount: 1600});

        seasonOne = new ERC1155SeasonOne(address(core), address(nft), address(token), tokenIdRewardAmounts);

        token.mint(address(this), 100_000_000); // random number
        token.approve(address(seasonOne), calulateTotalRewardAmount(tokenIdRewardAmounts));

        seasonOne.fund();
    }

    /// ----------------------------------- Helpers ----------------------------------------------/
    function calulateTotalRewardAmount(TokenIdRewardAmount[] memory tokenIdRewardAmounts) public returns (uint256) {
        uint256 total = 0;

        for (uint256 i = 0; i < tokenIdRewardAmounts.length; i++) {
            total += (tokenIdRewardAmounts[i].rewardAmount * tokenIdRewardAmounts[i].tokenSupply);
        }

        console.log("total: %s", total);
        return total;
    }

    /// ------------------------------------------------------------------------------------------/

    function testBurnAndRelease() public {
        // TODO
    }
}
