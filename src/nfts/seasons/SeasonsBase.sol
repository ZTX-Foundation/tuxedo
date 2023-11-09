// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {SeasonsTokenIdRegistry} from "@protocol/nfts/seasons/SeasonsTokenIdRegistry.sol";
import {Roles} from "@protocol/core/Roles.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct TokenIdRewardAmount {
    uint256 tokenId;
    uint256 rewardAmount;
}

abstract contract SeasonsBase is CoreRef, ERC1155Holder {
    using SafeERC20 for IERC20;

    /// --------------- Events -----------------///

    event TotalRewardTokensSet(uint256 oldtotalRewardTokens, uint256 newtotalRewardTokens);

    /// --------------- Storage -----------------///

    ERC1155MaxSupplyMintable public immutable nftContract;
    IERC20 public immutable rewardToken;
    SeasonsTokenIdRegistry public immutable tokenIdRegistryContract;

    /// @notice Total amount of reward tokens needed by the contract to be solvent
    uint256 public totalRewardTokens;

    /// @notice Total amount of reward tokens used for the whole season
    uint256 public totalRewardTokensUsed;

    /// @notice Total amount of reward tokens clawedback. Kept for record keeping.
    uint256 public totalClawedBack;

    /// --------------- modifiers -----------------///

    /// @notice Check if the contract has enough reward tokens to be solvent
    modifier verifySolvent() {
        require(solvent(), "SeasonsBase: Contract Not solvent");
        _;
        require(solvent(), "SeasonsBase: Contract Not solvent");
    }

    /// --------------- errors -----------------///
    error NoPaused();

    /// --------------- events -----------------///

    constructor(
        address _core,
        address _nftContract,
        address _rewardToken,
        address _tokenIdRegistryContract
    ) CoreRef(_core) {
        require(_nftContract != address(0), "SeasonsBase: _nftContract cannot be 0 address");
        require(_rewardToken != address(0), "SeasonsBase: _rewardToken cannot be 0 address");
        require(_tokenIdRegistryContract != address(0), "SeasonsBase: tokenIdRegistryContract cannot be 0 address");

        nftContract = ERC1155MaxSupplyMintable(_nftContract);
        rewardToken = IERC20(_rewardToken);
        tokenIdRegistryContract = SeasonsTokenIdRegistry(_tokenIdRegistryContract);
    }

    /// @notice Any wallet can fund the contract.
    function fund() public {
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), totalRewardTokens);
    }

    /// @notice Check if the contract has enough reward tokens to be solvent
    function solvent() public view returns (bool) {
        return IERC20(rewardToken).balanceOf(address(this)) >= totalRewardTokens;
    }

    /// @notice Check the balance of the contract
    function balance() public view returns (uint256) {
        return IERC20(rewardToken).balanceOf(address(this));
    }

    function initalizeSeasonDistribution(
        TokenIdRewardAmount[] memory tokenIdRewardAmounts
    ) external virtual returns (uint256);

    function redeem(uint256 tokenId) public virtual;

    /// @notice Register tokenIds to the tokenIdRegistryContract
    function registerTokenIds(TokenIdRewardAmount[] memory tokenIdRewardAmounts) internal {
        uint256[] memory tokenIds = new uint256[](tokenIdRewardAmounts.length);

        for (uint256 i = 0; i < tokenIdRewardAmounts.length; i++) {
            tokenIds[i] = tokenIdRewardAmounts[i].tokenId;
        }
        tokenIdRegistryContract.registerBatch(tokenIds, address(this));
    }

    /// @notice Reconfig the season distribution when a supply change increased
    function reconfigSeasonDistribution() external virtual returns (uint256) {}

    // TODO confirm roles?
    function clawback(address to) public hasAnyOfTwoRoles(Roles.ADMIN, Roles.FINANCIAL_CONTROLLER) {
        // checks
        if (!paused()) {
            revert NoPaused();
        }

        // effects
        totalClawedBack = totalRewardTokens;
        totalRewardTokens = 0;

        // interaction
        IERC20(rewardToken).safeTransfer(to, totalClawedBack);
    }
}
