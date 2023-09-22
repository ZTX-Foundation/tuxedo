pragma solidity 0.8.18;

import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {SeasonsTokenIdRegistry} from "@protocol/nfts/seasons/SeasonsTokenIdRegistry.sol";
import {Roles} from "@protocol/core/Roles.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Sealable} from "@protocol/utils/extensions/Sealable.sol";

struct TokenIdRewardAmount {
    uint256 tokenId;
    uint256 rewardAmount;
}

abstract contract SeasonsBase is CoreRef, ERC1155Holder, Sealable {
    using SafeERC20 for IERC20;

    ERC1155MaxSupplyMintable public immutable nftContract;
    IERC20 public immutable rewardToken;
    SeasonsTokenIdRegistry public immutable tokenIdRegistryContract;

    /// @notice Total amount of reward tokens needed by the contract to be solvent
    uint256 public totalRewardTokens;

    constructor(
        address _core,
        address _nftSeasonContract,
        address _rewardToken,
        address _tokenIdRegistryContract
    ) CoreRef(_core) {
        require(_nftSeasonContract != address(0), "SeasonsBase: _nftSeasonContract cannot be 0");
        require(_rewardToken != address(0), "SeasonsBase: _rewardToken cannot be 0");
        require(_tokenIdRegistryContract != address(0), "SeasonsBase: tokenIdRegistryContract cannot be 0");

        nftContract = ERC1155MaxSupplyMintable(_nftSeasonContract);
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

    function configSeasonDistribution(
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
}
