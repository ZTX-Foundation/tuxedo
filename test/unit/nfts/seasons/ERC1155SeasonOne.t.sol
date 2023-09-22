// SPDX-License-Identifier: UNKNOWN
pragma solidity 0.8.18;

import "@forge-std/console.sol";

import {Roles} from "@protocol/core/Roles.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

import {ERC1155SeasonOne} from "@protocol/nfts/seasons/ERC1155SeasonOne.sol";
import {TokenIdRewardAmount} from "@protocol/nfts/seasons/SeasonsBase.sol";
import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";
import {ERC1155AutoGraphMinter} from "@protocol/nfts/ERC1155AutoGraphMinter.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

import {SeasonBase} from "@test/unit/nfts/seasons/SeasonBase.t.sol";
import {SeasonsTokenIdRegistry} from "@protocol/nfts/seasons/SeasonsTokenIdRegistry.sol";

contract UnitTestERC1155SeasonOne is SeasonBase {
    SeasonsTokenIdRegistry private _registry;
    ERC1155SeasonOne private _seasonOne;
    ERC1155MaxSupplyMintable private _capsuleNFT;
    ERC1155AutoGraphMinter private _autoGraphMinter;

    function setUp() public override(SeasonBase) {
        super.setUp();

        // Deploy registry
        _registry = new SeasonsTokenIdRegistry(address(core));

        // Deploy capsule NFT
        _capsuleNFT = new ERC1155MaxSupplyMintable(address(core), "");

        // Set supply
        vm.startPrank(addresses.adminAddress);
        core.grantRole(Roles.LOCKER, address(_capsuleNFT));
        _capsuleNFT.setSupplyCap(1, 1000);
        _capsuleNFT.setSupplyCap(2, 1000);
        _capsuleNFT.setSupplyCap(3, 1000);
        vm.stopPrank();

        // Confirm supply
        assertEq(_capsuleNFT.maxTokenSupply(1), 1000);
        assertEq(_capsuleNFT.maxTokenSupply(2), 1000);
        assertEq(_capsuleNFT.maxTokenSupply(3), 1000);

        // Deploy season logic contract
        _seasonOne = new ERC1155SeasonOne(address(core), address(_capsuleNFT), address(token), address(_registry));

        // Give contract the registry operator role
        vm.prank(addresses.adminAddress);
        core.grantRole(Roles.REGISTRY_OPERATOR, address(_seasonOne));
    }

    /// ----------------------------------- Helpers ----------------------------------------------/

    /// @dev mint NFT helper
    function mint(uint _tokenId, uint units) public {
        vm.prank(addresses.lockerAddress);
        lock.lock(1);

        vm.prank(addresses.minterAddress);
        _capsuleNFT.mint(address(this), _tokenId, units);

        assertEq(_capsuleNFT.balanceOf(address(this), _tokenId), units);
    }

    function calulateTotalRewardAmount(
        TokenIdRewardAmount[] memory tokenIdRewardAmounts
    ) public view returns (uint256) {
        uint256 totalNeeded = 0;
        for (uint256 i = 0; i < tokenIdRewardAmounts.length; i++) {
            uint _maxTokenSupply = _capsuleNFT.maxTokenSupply(tokenIdRewardAmounts[i].tokenId);
            totalNeeded += (tokenIdRewardAmounts[i].rewardAmount * _maxTokenSupply);
        }
        return totalNeeded;
    }

    /// ------------------------------------------------------------------------------------------/

    function testConfigSeasonDistribution() public returns (uint256) {
        TokenIdRewardAmount[] memory tokenIdRewardAmounts = new TokenIdRewardAmount[](3);

        // Set tokenId to Reward Amount.
        tokenIdRewardAmounts[0] = TokenIdRewardAmount({tokenId: 1, rewardAmount: 400});
        tokenIdRewardAmounts[1] = TokenIdRewardAmount({tokenId: 2, rewardAmount: 1000});
        tokenIdRewardAmounts[2] = TokenIdRewardAmount({tokenId: 3, rewardAmount: 1600});

        vm.prank(addresses.deployerAddress);
        _seasonOne.configSeasonDistribution(tokenIdRewardAmounts);

        assertEq(_seasonOne.totalRewardTokens(), calulateTotalRewardAmount(tokenIdRewardAmounts));
        assertEq(_registry.tokenIdSeasonContract(1), address(_seasonOne));
        assertEq(_registry.tokenIdSeasonContract(2), address(_seasonOne));
        assertEq(_registry.tokenIdSeasonContract(3), address(_seasonOne));
        return _seasonOne.totalRewardTokens();
    }

    function testConfigSeasonDistributionFailZeroReward() public {
        TokenIdRewardAmount[] memory tokenIdRewardAmounts = new TokenIdRewardAmount[](1);

        // Set tokenId to Reward Amount.
        tokenIdRewardAmounts[0] = TokenIdRewardAmount({tokenId: 0, rewardAmount: 0});

        vm.prank(addresses.deployerAddress);
        vm.expectRevert("ERC1155SeasonOne: rewardAmount cannot be 0");
        _seasonOne.configSeasonDistribution(tokenIdRewardAmounts);
    }

    function testConfigSeasonDistributionFailZeroSupply() public {
        TokenIdRewardAmount[] memory tokenIdRewardAmounts = new TokenIdRewardAmount[](1);

        // Set tokenId to Reward Amount.
        tokenIdRewardAmounts[0] = TokenIdRewardAmount({tokenId: 0, rewardAmount: 1000});

        vm.prank(addresses.deployerAddress);
        vm.expectRevert("ERC1155SeasonOne: maxTokenSupply cannot be 0");
        _seasonOne.configSeasonDistribution(tokenIdRewardAmounts);
    }

    function testConfigSeasonDistributionFailNoDeployerRole() public {
        TokenIdRewardAmount[] memory tokenIdRewardAmounts = new TokenIdRewardAmount[](1);

        // Set tokenId to Reward Amount.
        tokenIdRewardAmounts[0] = TokenIdRewardAmount({tokenId: 1, rewardAmount: 1000});

        vm.expectRevert("CoreRef: no role on core");
        _seasonOne.configSeasonDistribution(tokenIdRewardAmounts);
    }

    function testConfigSeasonDistributionFailFunctionSealed() public {
        TokenIdRewardAmount[] memory tokenIdRewardAmounts = new TokenIdRewardAmount[](1);

        // Set tokenId to Reward Amount.
        tokenIdRewardAmounts[0] = TokenIdRewardAmount({tokenId: 1, rewardAmount: 1000});

        vm.prank(addresses.deployerAddress);
        _seasonOne.configSeasonDistribution(tokenIdRewardAmounts);

        vm.prank(addresses.deployerAddress);
        vm.expectRevert("Sealable: Contract already Sealed");
        _seasonOne.configSeasonDistribution(tokenIdRewardAmounts);
    }

    function testConfigNotSolvent() public {
        testConfigSeasonDistribution(); // config contract.
        assertEq(_seasonOne.solvent(), false); // no funds in contract.
    }

    function testConfigAndMakeSolvent() public {
        uint256 totalNeeded = testConfigSeasonDistribution(); // config contract.

        token.mint(address(this), totalNeeded);
        token.approve(address(_seasonOne), totalNeeded);
        _seasonOne.fund();

        assertEq(_seasonOne.solvent(), true);
    }

    function testBalance() public {
        uint256 totalNeeded = testConfigSeasonDistribution(); // config contract.
        assertEq(_seasonOne.balance(), 0); // no funds in contract.

        token.mint(address(this), totalNeeded);
        token.approve(address(_seasonOne), totalNeeded);
        _seasonOne.fund();

        assertEq(_seasonOne.balance(), totalNeeded);
    }

    function testRedeemNotSolvent() public {
        testConfigNotSolvent();
        vm.expectRevert("ERC1155SeasonOne: Contract Not solvent");
        _seasonOne.redeem(1);
    }

    function testRedeemInvalidTokenId() public {
        testConfigAndMakeSolvent(); // config and fund contract

        vm.expectRevert("ERC1155SeasonOne: No redeemable tokens for given tokenId");
        _seasonOne.redeem(0);
    }

    function testRedeemNoCapsulesInWallet() public {
        testConfigAndMakeSolvent(); // config and fund contract

        vm.expectRevert("ERC1155SeasonOne: No capsule available in users wallet");
        _seasonOne.redeem(1);
    }

    function testRedeem() public {
        testConfigAndMakeSolvent(); // config and fund contract
        uint _tokenId = 1;
        uint beforeTotalRewardTokens = _seasonOne.totalRewardTokens();
        assertEq(token.balanceOf(address(_seasonOne)), beforeTotalRewardTokens);

        mint(1, _tokenId); // mint 1 capsule of tokenId 1
        _capsuleNFT.setApprovalForAll(address(_seasonOne), true);
        _seasonOne.redeem(_tokenId);

        assertEq(_seasonOne.tokenIdUsedAmount(_tokenId), 400);
        assertEq(_capsuleNFT.balanceOf(address(this), _tokenId), 0); // moved
        assertEq(_capsuleNFT.balanceOf(address(_seasonOne), _tokenId), 0); // burnt
        assertEq(token.balanceOf(address(this)), 400);
        assertEq(token.balanceOf(address(_seasonOne)), beforeTotalRewardTokens - 400);
    }
}
