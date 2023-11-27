// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {BaseTest} from "@test/integration/BaseTest.sol";
import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {ERC1155SeasonOne} from "@protocol/nfts/seasons/ERC1155SeasonOne.sol";
import {SeasonBase} from "@test/unit/nfts/seasons/SeasonBase.t.sol";
import {SeasonsTokenIdRegistry} from "@protocol/nfts/seasons/SeasonsTokenIdRegistry.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {ERC1155AutoGraphMinter} from "@protocol/nfts/ERC1155AutoGraphMinter.sol";
import {ERC1155AutoGraphMinterHelperLib} from "@test/helpers/ERC1155AutoGraphMinterHelper.sol";
import {TokenIdRewardAmount} from "@protocol/nfts/seasons/SeasonsBase.sol";
import {ERC1155SeaonsHelperLib as Helper} from "@test/helpers/ERC1155SeasonsHelper.sol";
import {Token} from "@protocol/token/Token.sol";

contract IntegrationTestERC1155SeasonOne is BaseTest {
    SeasonsTokenIdRegistry private _registry;
    ERC1155SeasonOne private _seasonOne;
    ERC1155MaxSupplyMintable private _erc1155Consumables;
    ERC1155AutoGraphMinter private _autoGraphMinter;
    Token private _token;
    address _multisig;
    address _treasury;

    /// @notice private key for the offline notary hash signing
    uint256 private _privateKey;
    address private _notary;

    function setUp() public override {
        super.setUp();

        string memory mnemonic = "test test test test test test test test test test test junk";
        _privateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/1/", 0);
        _notary = vm.addr(_privateKey);

        _erc1155Consumables = ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES"));
        _registry = SeasonsTokenIdRegistry(addresses.getAddress("SEASONS_TOKEN_ID_REGISTRY"));
        _seasonOne = ERC1155SeasonOne(addresses.getAddress("ERC1155_SEASON_ONE"));
        _autoGraphMinter = ERC1155AutoGraphMinter(addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER"));
        _token = Token(addresses.getAddress("TOKEN"));
        _multisig = addresses.getAddress("ADMIN_MULTISIG");
        _treasury = addresses.getAddress("TREASURY_WALLET_MULTISIG");

        vm.startPrank(addresses.getAddress("ADMIN_MULTISIG"));
        /// @dev setup notary signing role
        Core(addresses.getAddress("CORE")).grantRole(Roles.MINTER_NOTARY_PROTOCOL_ROLE, _notary);

        /// @dev setup the inital supply caps ie start of a season
        _erc1155Consumables.setSupplyCap(1, 10_000); // tier 1
        _erc1155Consumables.setSupplyCap(2, 10_000); // tier 2
        _erc1155Consumables.setSupplyCap(3, 10_000); // tier 3
        vm.stopPrank();

        // Confirm supply
        assertEq(_erc1155Consumables.maxTokenSupply(1), 10_000);
        assertEq(_erc1155Consumables.maxTokenSupply(2), 10_000);
        assertEq(_erc1155Consumables.maxTokenSupply(3), 10_000);
    }

    /// ------------------------------------------ helper functions ------------------------------------------ ///

    /// @dev helper function to mint a NFT
    function mintNft(uint tokenId, uint units) public {
        ERC1155AutoGraphMinterHelperLib.mintForFree(
            vm,
            _privateKey,
            address(_autoGraphMinter),
            address(_erc1155Consumables),
            tokenId,
            units
        );
        assertEq(_erc1155Consumables.balanceOf(address(this), tokenId), units);
    }

    /// @dev helper for the SeasonDistributionStruct
    function SeasonDistributionStruct() public pure returns (TokenIdRewardAmount[] memory) {
        TokenIdRewardAmount[] memory tokenIdRewardAmounts = new TokenIdRewardAmount[](3);

        // Set tokenId to Reward Amount.
        tokenIdRewardAmounts[0] = TokenIdRewardAmount({tokenId: 1, rewardAmount: 400});
        tokenIdRewardAmounts[1] = TokenIdRewardAmount({tokenId: 2, rewardAmount: 1000});
        tokenIdRewardAmounts[2] = TokenIdRewardAmount({tokenId: 3, rewardAmount: 1600});
        return tokenIdRewardAmounts;
    }

    /// ------------------------------------------ test functions ------------------------------------------ ///

    function testAutoGraphMinterHelper() public {
        mintNft(1, 1);
    }

    /// @dev config the season distribution
    function testInitalizeSeasonDistribution() public returns (uint256) {
        vm.startPrank(_multisig);
        _seasonOne.initalizeSeasonDistribution(SeasonDistributionStruct());
        vm.stopPrank();

        /// verify the totalRewardTokens is correct
        assertEq(
            _seasonOne.totalRewardTokens(),
            Helper.calulateTotalRewardAmount(SeasonDistributionStruct(), _erc1155Consumables)
        );

        /// verify the tokenId have been registored in the registry contract
        assertEq(_registry.tokenIdSeasonContract(1), address(_seasonOne));
        assertEq(_registry.tokenIdSeasonContract(2), address(_seasonOne));
        assertEq(_registry.tokenIdSeasonContract(3), address(_seasonOne));

        /// verify the season is not solvent ie not fund in contract yet.
        assertEq(_seasonOne.solvent(), false);

        return _seasonOne.totalRewardTokens();
    }

    function testInitalizeCalledTwice() public {
        testInitalizeSeasonDistribution();
        vm.expectRevert("SeasonsTokenIdRegistry: tokenId already registered to a Season Contract");
        testInitalizeSeasonDistribution();
    }

    function testInitalizeAndFundSeason() public returns (uint256) {
        uint256 totalRewardTokens = testInitalizeSeasonDistribution();

        /// @dev fund the season
        vm.startPrank(_treasury);
        _token.transfer(address(_seasonOne), totalRewardTokens);
        vm.stopPrank();

        /// verify the season is solvent ie fund in contract
        assertEq(_seasonOne.solvent(), true);
        return totalRewardTokens;
    }

    function testBalance() public {
        testInitalizeAndFundSeason();

        /// @dev verify the balance of the season contract
        assertEq(_token.balanceOf(address(_seasonOne)), _seasonOne.totalRewardTokens());
    }

    function testInitalizeFundAndRedeem() public {
        testInitalizeAndFundSeason();
        uint beforeTotalRewardTokens = _seasonOne.totalRewardTokens();

        uint _tokenId = 1;

        // mint NFT
        mintNft(_tokenId, 1);

        // redeem nft
        _erc1155Consumables.setApprovalForAll(address(_seasonOne), true);
        _seasonOne.redeem(_tokenId);

        // verify the balance of the season contract
        assertEq(_seasonOne.tokenIdUsedAmount(_tokenId), 400);
        assertEq(_seasonOne.totalRewardTokens(), beforeTotalRewardTokens - 400);
        assertEq(_erc1155Consumables.balanceOf(address(this), _tokenId), 0); // moved
        assertEq(_erc1155Consumables.balanceOf(address(_seasonOne), _tokenId), 0); // burnt
        assertEq(_token.balanceOf(address(this)), 400);
        assertEq(_token.balanceOf(address(_seasonOne)), beforeTotalRewardTokens - 400);
    }

    function testInitalizeFundReconfigAndFundAgainSeason() public {
        testInitalizeAndFundSeason();

        /// @dev increase the supply cap
        vm.startPrank(_multisig);
        _erc1155Consumables.setSupplyCap(1, 100_000); // tier 1
        _erc1155Consumables.setSupplyCap(2, 100_000); // tier 2
        _erc1155Consumables.setSupplyCap(3, 100_000); // tier 3
        vm.stopPrank();

        // Confirm supply
        assertEq(_erc1155Consumables.maxTokenSupply(1), 100_000);
        assertEq(_erc1155Consumables.maxTokenSupply(2), 100_000);
        assertEq(_erc1155Consumables.maxTokenSupply(3), 100_000);

        // reconfig the season
        vm.prank(_multisig);
        _seasonOne.reconfigSeasonDistribution();

        // verify the balance of the season contract
        assertEq(
            _seasonOne.totalRewardTokens(),
            Helper.calulateTotalRewardAmount(SeasonDistributionStruct(), _erc1155Consumables)
        );

        assertEq(_seasonOne.solvent(), false);

        // fund the season again
        vm.startPrank(_treasury);
        _token.transfer(address(_seasonOne), _seasonOne.totalRewardTokens());
        vm.stopPrank();

        // verify the season is solvent ie fund in contract
        assertEq(_seasonOne.solvent(), true);
    }

    function testInitalizeFundRedeemAndReConfigSeason() public {
        testInitalizeFundAndRedeem();

        /// @dev increase the supply cap
        vm.startPrank(_multisig);
        _erc1155Consumables.setSupplyCap(1, 100_000); // tier 1
        _erc1155Consumables.setSupplyCap(2, 100_000); // tier 2
        _erc1155Consumables.setSupplyCap(3, 100_000); // tier 3
        vm.stopPrank();

        // Confirm supply
        assertEq(_erc1155Consumables.maxTokenSupply(1), 100_000);
        assertEq(_erc1155Consumables.maxTokenSupply(2), 100_000);
        assertEq(_erc1155Consumables.maxTokenSupply(3), 100_000);

        // reconfig the season
        vm.prank(_multisig);
        _seasonOne.reconfigSeasonDistribution();

        // verify the balance of the season contract
        assertEq(
            _seasonOne.totalRewardTokens(),
            Helper.calulateTotalRewardAmount(SeasonDistributionStruct(), _erc1155Consumables) - 400
        );

        assertEq(_seasonOne.solvent(), false);
    }
}
