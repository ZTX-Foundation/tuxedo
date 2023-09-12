pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {ERC1155, ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract SeasonsBase is CoreRef {
    using SafeERC20 for IERC20;
    ERC1155MaxSupplyMintable public immutable nftSeaonContract;
    IERC20 public immutable rewardToken;

    /// @notice Total amount of reward tokens needed by the contract to be solvent
    uint256 public totalRewardTokens;

    constructor(address _core, address _nftSeasonContract, address _rewardToken) CoreRef(_core) {
        nftSeaonContract = ERC1155MaxSupplyMintable(_nftSeasonContract);
        rewardToken = IERC20(_rewardToken);
    }

    /// @notice Any wallet can fund the contract.
    function fund() public {
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), totalRewardTokens);
    }
}
