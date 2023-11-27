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
import {DepositBase} from "@protocol/finance/DepositBase.sol";

struct TokenIdRewardAmount {
    uint256 tokenId;
    uint256 rewardAmount;
}

abstract contract SeasonsBase is CoreRef, ERC1155Holder, DepositBase {
    using SafeERC20 for IERC20;

    /// --------------- Events -----------------///

    event TotalRewardTokensSet(uint256 oldtotalRewardTokens, uint256 newtotalRewardTokens);
    event Redeemed(address indexed user, uint256 indexed tokenId, uint256 rewardAmount);

    /// --------------- Storage -----------------///

    /// @notice ERC1155 contract for the season
    ERC1155MaxSupplyMintable public immutable nftContract;

    /// @notice ERC20 contract for the reward token, should be ZTX
    IERC20 public immutable rewardToken;

    /// @notice Contract to register tokenIds
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

    /// @notice Check the balance of the contract in reward token
    function balance() public view override returns (uint256) {
        return IERC20(rewardToken).balanceOf(address(this));
    }

    /// @notice return the address of the reward token for this season contract
    function balanceReportedIn() public view override returns (address) {
        return address(rewardToken);
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

    /// @notice Clawback all reward tokens to a specific address
    /// @param to address to send the reward tokens to
    /// @dev This function is only callable by the ADMIN or FINANCIAL_CONTROLLER
    /// this can push the contract into insolvency, be very careful calling this
    function clawbackAll(address to) external hasAnyOfTwoRoles(Roles.ADMIN, Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE) {
        uint256 amount = totalRewardTokens;

        // effects + interactions
        _withdrawTokens(to, amount);
    }

    /// @dev This function is only callable by the FINANCIAL_CONTROLLER
    /// Callable regardless of pause state.
    /// this can push the contract into insolvency, be very careful calling this
    function withdraw(address to, uint256 amount) public onlyRole(Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE) {
        /// this can push the contract into insolvency, be very careful
        _withdrawTokens(to, amount);
    }

    function _withdrawTokens(address to, uint256 amount) private {
        /// effects
        totalRewardTokens -= amount;
        totalClawedBack += amount;

        /// interaction
        IERC20(address(rewardToken)).safeTransfer(to, amount);

        emit WithdrawERC20(msg.sender, address(rewardToken), to, amount);
    }
}
