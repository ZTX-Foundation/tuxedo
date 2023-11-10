// SPDX-License-Identifier: UNKNOWN
pragma solidity 0.8.18;

import "@forge-std/console.sol";

import {Roles} from "@protocol/core/Roles.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

import {ERC1155SeasonOne} from "@protocol/nfts/seasons/ERC1155SeasonOne.sol";
import {TokenIdRewardAmount} from "@protocol/nfts/seasons/SeasonsBase.sol";
import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

import {SeasonBase} from "@test/unit/nfts/seasons/SeasonBase.t.sol";
import {SeasonsTokenIdRegistry} from "@protocol/nfts/seasons/SeasonsTokenIdRegistry.sol";
import {ERC1155SeaonsHelperLib as Helper} from "@test/helpers/ERC1155SeasonsHelper.sol";

contract UnitTestERC1155SeasonOne is SeasonBase {
    /// ----------------------------------- Events ----------------------------------------------/

    /// @dev emitted when totalRewardTokens is set
    event TotalRewardTokensSet(uint256 oldtotalRewardTokens, uint256 newtotalRewardTokens);

    /// ------------------------------------------------------------------------------------------/

    SeasonsTokenIdRegistry private _registry;
    ERC1155SeasonOne private _seasonOne;
    ERC1155MaxSupplyMintable private _capsuleNFT;

    function setUp() public override(SeasonBase) {
        super.setUp();

        // Deploy registry
        _registry = new SeasonsTokenIdRegistry(address(core));

        // Deploy capsule NFT
        _capsuleNFT = new ERC1155MaxSupplyMintable(address(core), "", "Capsules NFTs", "CAPS");

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

        vm.prank(addresses.lockerAddress);
        lock.unlock(0);

        assertEq(_capsuleNFT.balanceOf(address(this), _tokenId), units);
    }

    function SeasonDistributionStruct() public pure returns (TokenIdRewardAmount[] memory) {
        TokenIdRewardAmount[] memory tokenIdRewardAmounts = new TokenIdRewardAmount[](3);

        // Set tokenId to Reward Amount.
        tokenIdRewardAmounts[0] = TokenIdRewardAmount({tokenId: 1, rewardAmount: 400});
        tokenIdRewardAmounts[1] = TokenIdRewardAmount({tokenId: 2, rewardAmount: 1000});
        tokenIdRewardAmounts[2] = TokenIdRewardAmount({tokenId: 3, rewardAmount: 1600});
        return tokenIdRewardAmounts;
    }

    /// ------------------------------------------------------------------------------------------/

    function testInitalizeSeasonDistribution() public returns (uint256) {
        uint _totalRewardTokens = Helper.calulateTotalRewardAmount(SeasonDistributionStruct(), _capsuleNFT);

        vm.startPrank(addresses.adminAddress);
        vm.expectEmit(true, true, true, true);
        emit TotalRewardTokensSet(0, _totalRewardTokens);
        _seasonOne.initalizeSeasonDistribution(SeasonDistributionStruct());
        vm.stopPrank();

        assertEq(
            _seasonOne.totalRewardTokens(),
            Helper.calulateTotalRewardAmount(SeasonDistributionStruct(), _capsuleNFT)
        );
        assertEq(_registry.tokenIdSeasonContract(1), address(_seasonOne));
        assertEq(_registry.tokenIdSeasonContract(2), address(_seasonOne));
        assertEq(_registry.tokenIdSeasonContract(3), address(_seasonOne));
        return _seasonOne.totalRewardTokens();
    }

    function testInitalizeSeasonDistributionFailZeroReward() public {
        TokenIdRewardAmount[] memory tokenIdRewardAmounts = new TokenIdRewardAmount[](1);

        // Set tokenId to Reward Amount.
        tokenIdRewardAmounts[0] = TokenIdRewardAmount({tokenId: 0, rewardAmount: 0});

        vm.prank(addresses.adminAddress);
        vm.expectRevert("ERC1155SeasonOne: rewardAmount cannot be 0");
        _seasonOne.initalizeSeasonDistribution(tokenIdRewardAmounts);
    }

    function testInitalizeSeasonDistributionFailZeroSupply() public {
        TokenIdRewardAmount[] memory tokenIdRewardAmounts = new TokenIdRewardAmount[](1);

        // Set tokenId to Reward Amount.
        tokenIdRewardAmounts[0] = TokenIdRewardAmount({tokenId: 0, rewardAmount: 1000});

        vm.prank(addresses.adminAddress);
        vm.expectRevert("ERC1155SeasonOne: maxTokenSupply cannot be 0");
        _seasonOne.initalizeSeasonDistribution(tokenIdRewardAmounts);
    }

    function testInitalizeSeasonDistributionFailNoDeployerRole() public {
        TokenIdRewardAmount[] memory tokenIdRewardAmounts = new TokenIdRewardAmount[](1);

        // Set tokenId to Reward Amount.
        tokenIdRewardAmounts[0] = TokenIdRewardAmount({tokenId: 1, rewardAmount: 1000});

        vm.expectRevert("CoreRef: no role on core");
        _seasonOne.initalizeSeasonDistribution(tokenIdRewardAmounts);
    }

    function testInitalizeNotSolvent() public {
        testInitalizeSeasonDistribution(); // config contract.
        assertEq(_seasonOne.solvent(), false); // no funds in contract.
    }

    function testInitalizeAndMakeSolvent() public returns (uint256) {
        uint256 _totalNeeded = testInitalizeSeasonDistribution();

        token.mint(address(this), _totalNeeded);
        token.approve(address(_seasonOne), _totalNeeded);
        _seasonOne.fund();

        assertEq(_seasonOne.solvent(), true);
        return _totalNeeded;
    }

    function testInitalizeCalledTwice() public {
        testInitalizeSeasonDistribution();

        vm.expectRevert("SeasonsTokenIdRegistry: tokenId already registered to a Season Contract");
        vm.startPrank(addresses.adminAddress);
        _seasonOne.initalizeSeasonDistribution(SeasonDistributionStruct());
        vm.stopPrank();
    }

    function testInitalizeAndMakeSolventAndReconfigSeasonDistributionMakeSolvent() public {
        uint256 _totalNeeded = testInitalizeAndMakeSolvent();
        assertEq(_seasonOne.totalRewardTokens(), _totalNeeded);

        // increase capsule NFT supply caps.
        vm.startPrank(addresses.adminAddress);
        _capsuleNFT.setSupplyCap(1, 3000);
        _capsuleNFT.setSupplyCap(2, 3000);
        _capsuleNFT.setSupplyCap(3, 3000);
        vm.stopPrank();

        // Confirm updated supply
        assertEq(_capsuleNFT.maxTokenSupply(1), 3000);
        assertEq(_capsuleNFT.maxTokenSupply(2), 3000);
        assertEq(_capsuleNFT.maxTokenSupply(3), 3000);

        uint _newTotalRewardTokens = Helper.calulateTotalRewardAmount(SeasonDistributionStruct(), _capsuleNFT);

        // Reconfig distribution
        vm.prank(addresses.adminAddress);
        vm.expectEmit(true, true, true, true);
        emit TotalRewardTokensSet(_totalNeeded, _newTotalRewardTokens);
        uint256 _newTotalNeeded = _seasonOne.reconfigSeasonDistribution();

        assertTrue(_newTotalNeeded > _totalNeeded);
        assertEq(_seasonOne.totalRewardTokens(), _newTotalNeeded);
        assertEq(
            _seasonOne.totalRewardTokens(),
            Helper.calulateTotalRewardAmount(SeasonDistributionStruct(), _capsuleNFT)
        );
        assertEq(_seasonOne.totalRewardTokens(), 9000000);
        assertEq(_seasonOne.solvent(), false);

        token.mint(address(this), _newTotalNeeded);
        token.approve(address(_seasonOne), _newTotalNeeded);
        _seasonOne.fund();
        assertEq(_seasonOne.solvent(), true);
    }

    function testBalance() public {
        uint256 _totalNeeded = testInitalizeSeasonDistribution(); // config contract.
        assertEq(_seasonOne.balance(), 0); // no funds in contract.

        token.mint(address(this), _totalNeeded);
        token.approve(address(_seasonOne), _totalNeeded);
        _seasonOne.fund();

        assertEq(_seasonOne.balance(), _totalNeeded);
    }

    function testRedeemNotSolvent() public {
        testInitalizeNotSolvent();
        vm.expectRevert("SeasonsBase: Contract Not solvent");
        _seasonOne.redeem(address(this), 1);
    }

    function testRedeemInvalidTokenId() public {
        testInitalizeAndMakeSolvent(); // config and fund contract

        vm.expectRevert("ERC1155SeasonOne: No redeemable tokens for given tokenId");
        _seasonOne.redeem(address(this), 0);
    }

    function testRedeemNoCapsulesInWallet() public {
        testInitalizeAndMakeSolvent(); // config and fund contract

        vm.expectRevert("ERC1155SeasonOne: No capsule available in users wallet");
        _seasonOne.redeem(address(this), 1);
    }

    function testRedeem() public {
        testInitalizeAndMakeSolvent(); // config and fund contract
        uint beforeTotalRewardTokens = _seasonOne.totalRewardTokens();
        assertEq(token.balanceOf(address(_seasonOne)), beforeTotalRewardTokens);

        uint _tokenId = 1;
        mint(_tokenId, 1); // mint 1 capsule of tokenId 1
        _capsuleNFT.setApprovalForAll(address(_seasonOne), true);
        _seasonOne.redeem(address(this), _tokenId);

        assertEq(_seasonOne.tokenIdUsedAmount(_tokenId), 400);
        assertEq(_seasonOne.totalRewardTokens(), beforeTotalRewardTokens - 400);
        assertEq(_seasonOne.totalRewardTokensUsed(), 400);
        assertEq(_capsuleNFT.balanceOf(address(this), _tokenId), 0); // moved
        assertEq(_capsuleNFT.balanceOf(address(_seasonOne), _tokenId), 0); // burnt
        assertEq(token.balanceOf(address(this)), 400);
        assertEq(token.balanceOf(address(_seasonOne)), beforeTotalRewardTokens - 400);
    }

    function testRedeemThenReConfigDistrbution() public {
        testInitalizeAndMakeSolvent(); // config and fund contract
        uint beforeTotalRewardTokens = _seasonOne.totalRewardTokens();
        assertEq(token.balanceOf(address(_seasonOne)), beforeTotalRewardTokens);

        uint _tokenId = 1;
        mint(_tokenId, 1); // mint 1 capsule of tokenId 1
        _capsuleNFT.setApprovalForAll(address(_seasonOne), true);
        _seasonOne.redeem(address(this), _tokenId);

        assertEq(_seasonOne.tokenIdUsedAmount(_tokenId), 400);
        assertEq(_seasonOne.totalRewardTokens(), beforeTotalRewardTokens - 400);
        assertEq(_capsuleNFT.balanceOf(address(this), _tokenId), 0); // moved
        assertEq(_capsuleNFT.balanceOf(address(_seasonOne), _tokenId), 0); // burnt
        assertEq(token.balanceOf(address(this)), 400);
        assertEq(token.balanceOf(address(_seasonOne)), beforeTotalRewardTokens - 400);

        _tokenId = 2;
        mint(_tokenId, 1); // mint 1 capsule of tokenId 2
        _capsuleNFT.setApprovalForAll(address(_seasonOne), true);
        _seasonOne.redeem(address(this), _tokenId);

        assertEq(_seasonOne.tokenIdUsedAmount(_tokenId), 1000);
        assertEq(_seasonOne.totalRewardTokens(), beforeTotalRewardTokens - 400 - 1000);
        assertEq(_capsuleNFT.balanceOf(address(this), _tokenId), 0); // moved
        assertEq(_capsuleNFT.balanceOf(address(_seasonOne), _tokenId), 0); // burnt
        assertEq(token.balanceOf(address(this)), 400 + 1000);
        assertEq(token.balanceOf(address(_seasonOne)), beforeTotalRewardTokens - 400 - 1000);

        /// increase capsule NFT supply caps.
        vm.startPrank(addresses.adminAddress);
        _capsuleNFT.setSupplyCap(1, 3000);
        _capsuleNFT.setSupplyCap(2, 3000);
        _capsuleNFT.setSupplyCap(3, 3000);
        vm.stopPrank();

        // Confirm updated supply
        assertEq(_capsuleNFT.maxTokenSupply(1), 3000);
        assertEq(_capsuleNFT.maxTokenSupply(2), 3000);
        assertEq(_capsuleNFT.maxTokenSupply(3), 3000);

        // Reconfig distribution
        vm.prank(addresses.adminAddress);
        uint256 _newTotal = _seasonOne.reconfigSeasonDistribution();
        assertEq(
            _seasonOne.totalRewardTokens(),
            Helper.calulateTotalRewardAmount(SeasonDistributionStruct(), _capsuleNFT) - 400 - 1000
        );
        assertEq(_newTotal, 8998600); // manual calulation

        assertEq(_seasonOne.solvent(), false);

        token.mint(address(this), _newTotal);
        token.approve(address(_seasonOne), _newTotal);
        _seasonOne.fund();
        assertEq(_seasonOne.solvent(), true);
    }

    function testRedeemWhenPaused() public {
        testInitalizeAndMakeSolvent(); // config and fund contract
        vm.prank(addresses.adminAddress);
        _seasonOne.pause();

        vm.expectRevert("Pausable: paused");
        _seasonOne.redeem(address(this), 1);
    }

    function testClawbackWithAdminRoleSuccess() public {
        uint totals = testInitalizeAndMakeSolvent(); // config and fund contract
        uint _tokenId = 1;
        address recepitent = address(123);

        assertEq(token.balanceOf(address(_seasonOne)), totals);

        vm.startPrank(addresses.adminAddress);
        _seasonOne.pause();
        _seasonOne.clawback(recepitent);
        vm.stopPrank();

        assertEq(_seasonOne.tokenIdUsedAmount(_tokenId), 0);
        assertEq(_seasonOne.totalClawedBack(), totals);

        assertEq(token.balanceOf(address(_seasonOne)), 0);
        assertEq(token.balanceOf(recepitent), totals);
    }

    function testClawbackWithFinanicalControllerRoleSuccess() public {
        uint totals = testInitalizeAndMakeSolvent(); // config and fund contract
        uint _tokenId = 1;
        address recepitent = address(123);

        assertEq(token.balanceOf(address(_seasonOne)), totals);

        vm.prank(addresses.adminAddress);
        _seasonOne.pause();

        vm.prank(addresses.financialControllerAddress);
        _seasonOne.clawback(recepitent);

        assertEq(_seasonOne.tokenIdUsedAmount(_tokenId), 0);
        assertEq(_seasonOne.totalClawedBack(), totals);

        assertEq(token.balanceOf(address(_seasonOne)), 0);
        assertEq(token.balanceOf(recepitent), totals);
    }

    function testClawbackWithOutRoleFail() public {
        uint totals = testInitalizeAndMakeSolvent(); // config and fund contract
        address recepitent = address(123);

        assertEq(token.balanceOf(address(_seasonOne)), totals);

        vm.expectRevert("CoreRef: no role on core");
        _seasonOne.clawback(recepitent);
    }
}
