// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ERC1155, ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {SeasonsBase} from "@protocol/nfts/seasons/SeasonsBase.sol";
import {TokenIdRewardAmount} from "@protocol/nfts/seasons/SeasonsBase.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";

contract ERC1155SeasonTwo is SeasonsBase {
    constructor(
        address _core,
        address _nftContract,
        address _rewardToken,
        address _tokenIdRegistryContract
    ) SeasonsBase(_core, _nftContract, _rewardToken, _tokenIdRegistryContract) {}

    function redeem(address hodler, uint256 tokenId) public override {}

    function initalizeSeasonDistribution(
        TokenIdRewardAmount[] memory tokenIdRewardAmounts
    ) external override whenNotPaused onlyRole(Roles.ADMIN) returns (uint256) {}
}
