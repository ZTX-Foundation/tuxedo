//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";
import {TimelockProposal} from "@proposals/proposalTypes/TimelockProposal.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {Token, MAX_SUPPLY} from "@protocol/token/Token.sol";
import {ERC20HoldingDeposit} from "@protocol/finance/ERC20HoldingDeposit.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {ERC1155SeasonOne} from "@protocol/nfts/seasons/ERC1155SeasonOne.sol";
import {TokenIdRewardAmount} from "@protocol/nfts/seasons/SeasonsBase.sol";

contract zip004 is Proposal, TimelockProposal {
    string public name = "ZIP004";
    string public description = "ZTX CGv1 tokenIds, MaxSupply and Capsules config proposal";

    struct TokenIDMaxSupplySettings {
        uint256 tokenId;
        uint256 maxSupply;
    }

    TokenIDMaxSupplySettings[] public placeableTokenIDMaxSupplySettings;
    TokenIDMaxSupplySettings[] public wearableTokenIDMaxSupplySettings;
    TokenIDMaxSupplySettings[] public consumableTokenIDMaxSupplySettings;

    TokenIdRewardAmount[] public tokenIdRewardAmounts;

    function setAndConfirmPlaceableData() public {
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(1, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(4, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(12, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(14, 2500));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(17, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(21, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(27, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(28, 50));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(31, 4000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(43, 4000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(45, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(60, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(64, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(65, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(67, 2500));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(69, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(70, 50));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(72, 4000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(74, 4000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(76, 1000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(82, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(90, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(94, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(96, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(106, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(107, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(111, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(124, 500));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(129, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(149, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(152, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(153, 4000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(154, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(156, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(161, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(163, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(167, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(170, 1000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(175, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(179, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(182, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(184, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(187, 4000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(190, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(193, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(201, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(206, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(214, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(235, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(239, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(240, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(244, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(247, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(249, 4000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(252, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(258, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(262, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(267, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(279, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(284, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(288, 500));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(292, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(294, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(300, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(302, 100_000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(303, 2500));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(314, 2500));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(325, 4000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(329, 4000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(331, 50));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(334, 4000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(335, 4000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(336, 2500));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(337, 1000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(338, 50));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(339, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(340, 4000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(341, 2500));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(342, 1000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(343, 500));

        // sanity checks
        assertEq(placeableTokenIDMaxSupplySettings.length, 80, "Invalid placeableTokenIDMaxSupplySettings length");

        uint tokenIDTotal = 0;
        uint maxSupplyTotal = 0;

        // sum numbers from requrements sheet
        for (uint256 i = 0; i < placeableTokenIDMaxSupplySettings.length; i++) {
            tokenIDTotal += placeableTokenIDMaxSupplySettings[i].tokenId;
            maxSupplyTotal += placeableTokenIDMaxSupplySettings[i].maxSupply;
        }

        assertEq(tokenIDTotal, 14_654, "Invalid tokenIDTotal");
        assertEq(maxSupplyTotal, 3_852_700, "Invalid maxSupplyTotal");
    }

    function setAndConfirmWearableData() public {
        wearableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(1, 100_000));
        wearableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(2, 6000));
        wearableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(3, 6000));
        wearableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(4, 6000));
        wearableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(5, 6000));
        wearableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(6, 6000));
        wearableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(8, 500));
        wearableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(9, 500));
        wearableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(10, 500));
        wearableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(11, 100_000));
        wearableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(12, 100_000));

        // sanity checks
        assertEq(wearableTokenIDMaxSupplySettings.length, 11, "Invalid wearableTokenIDMaxSupplySettings length");

        uint tokenIDTotal = 0;
        uint maxSupplyTotal = 0;

        // sum numbers from requrements sheet
        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            tokenIDTotal += wearableTokenIDMaxSupplySettings[i].tokenId;
            maxSupplyTotal += wearableTokenIDMaxSupplySettings[i].maxSupply;
        }

        assertEq(tokenIDTotal, 71, "Invalid tokenIDTotal");
        assertEq(maxSupplyTotal, 331500, "Invalid maxSupplyTotal");
    }

    function setAndConfirmConsumableData() public {
        consumableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(1, 15_000));
        consumableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(2, 5538));
        consumableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(3, 2025));

        // sanity checks
        assertEq(consumableTokenIDMaxSupplySettings.length, 3, "Invalid consumableTokenIDMaxSupplySettings length");

        uint tokenIDTotal = 0;
        uint maxSupplyTotal = 0;

        // sum numbers from requrements sheet
        for (uint256 i = 0; i < consumableTokenIDMaxSupplySettings.length; i++) {
            tokenIDTotal += consumableTokenIDMaxSupplySettings[i].tokenId;
            maxSupplyTotal += consumableTokenIDMaxSupplySettings[i].maxSupply;
        }

        assertEq(tokenIDTotal, 6, "Invalid tokenIDTotal");
        assertEq(maxSupplyTotal, 22_563, "Invalid maxSupplyTotal");
    }

    function setAndConfirmSeaonOneData() public {
        // config the season distribution
        tokenIdRewardAmounts.push(TokenIdRewardAmount({tokenId: 1, rewardAmount: 300e18}));
        tokenIdRewardAmounts.push(TokenIdRewardAmount({tokenId: 2, rewardAmount: 2167e18}));
        tokenIdRewardAmounts.push(TokenIdRewardAmount({tokenId: 3, rewardAmount: 6667e18}));

        // sanity checks
        assertEq(tokenIdRewardAmounts.length, 3, "Invalid tokenIdRewardAmounts length");

        uint tokenIDTotal = 0;
        uint rewardAmountTotal = 0;

        // sum numbers from requrements sheet
        for (uint256 i = 0; i < tokenIdRewardAmounts.length; i++) {
            tokenIDTotal += tokenIdRewardAmounts[i].tokenId;
            rewardAmountTotal += tokenIdRewardAmounts[i].rewardAmount;
        }

        assertEq(tokenIDTotal, 6, "Invalid tokenIDTotal");
        assertEq(rewardAmountTotal, 9134e18, "Invalid rewardAmountTotal"); // numbers from santiy check sheet
    }

    function _beforeDeploy(Addresses, address deployer) internal override {
        setAndConfirmPlaceableData();
        setAndConfirmWearableData();
        setAndConfirmConsumableData();
        setAndConfirmSeaonOneData();
    }

    function _deploy(Addresses addresses, address) internal override {}

    function _afterDeploy(Addresses addresses, address) internal override {}

    function _afterDeployOnChain(Addresses, address deployer) internal virtual override {}

    function _aferDeployForTestingOnly(Addresses, address deployer) internal virtual override {}

    function _teardown(Addresses addresses, address deployer) internal override {}

    function _build(Addresses addresses, address) internal override {
        /// Placeables config
        for (uint256 i = 0; i < placeableTokenIDMaxSupplySettings.length; i++) {
            _pushTimelockAction(
                addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"),
                abi.encodeWithSignature(
                    "setSupplyCap(uint256,uint256)",
                    placeableTokenIDMaxSupplySettings[i].tokenId,
                    placeableTokenIDMaxSupplySettings[i].maxSupply
                ),
                string(
                    abi.encodePacked(
                        "Set placeable tokenId ",
                        placeableTokenIDMaxSupplySettings[i].tokenId,
                        " to max supply ",
                        placeableTokenIDMaxSupplySettings[i].maxSupply
                    )
                )
            );
        }

        /// Wearables config
        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            _pushTimelockAction(
                addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES"),
                abi.encodeWithSignature(
                    "setSupplyCap(uint256,uint256)",
                    wearableTokenIDMaxSupplySettings[i].tokenId,
                    wearableTokenIDMaxSupplySettings[i].maxSupply
                ),
                string(
                    abi.encodePacked(
                        "Set wearable tokenId ",
                        wearableTokenIDMaxSupplySettings[i].tokenId,
                        " to max supply ",
                        wearableTokenIDMaxSupplySettings[i].maxSupply
                    )
                )
            );
        }

        /// Consumables config
        for (uint256 i = 0; i < consumableTokenIDMaxSupplySettings.length; i++) {
            _pushTimelockAction(
                addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES"),
                abi.encodeWithSignature(
                    "setSupplyCap(uint256,uint256)",
                    consumableTokenIDMaxSupplySettings[i].tokenId,
                    consumableTokenIDMaxSupplySettings[i].maxSupply
                ),
                string(
                    abi.encodePacked(
                        "Set consumable tokenId ",
                        consumableTokenIDMaxSupplySettings[i].tokenId,
                        " to max supply ",
                        consumableTokenIDMaxSupplySettings[i].maxSupply
                    )
                )
            );
        }

        /// Season One config
        _pushTimelockAction(
            addresses.getAddress("ERC1155_SEASON_ONE"),
            abi.encodeWithSignature("initalizeSeasonDistribution((uint256,uint256)[])", tokenIdRewardAmounts),
            string(abi.encodePacked("Initalize Season One"))
        );
    }

    function _run(Addresses addresses, address) internal override {
        this.setDebug(true);

        _simulateTimelockActions(
            addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"),
            addresses.getAddress("ADMIN_MULTISIG"),
            addresses.getAddress("ADMIN_MULTISIG")
        );
    }

    function _validate(Addresses addresses, address) internal override {
        /// Verfiy Placeable
        for (uint256 i = 0; i < placeableTokenIDMaxSupplySettings.length; i++) {
            uint256 tokenId = placeableTokenIDMaxSupplySettings[i].tokenId;
            uint256 maxSupply = placeableTokenIDMaxSupplySettings[i].maxSupply;

            ERC1155MaxSupplyMintable placeable = ERC1155MaxSupplyMintable(
                addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")
            );

            assertEq(placeable.maxTokenSupply(tokenId), maxSupply, "Invalid getMintAmountLeft for tokenId");
            assertEq(placeable.getMintAmountLeft(tokenId), maxSupply, "Invalid getMintAmountLeft for tokenId");
        }

        /// Verfiy Wearable
        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            uint256 tokenId = wearableTokenIDMaxSupplySettings[i].tokenId;
            uint256 maxSupply = wearableTokenIDMaxSupplySettings[i].maxSupply;

            ERC1155MaxSupplyMintable wearable = ERC1155MaxSupplyMintable(
                addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")
            );

            assertEq(wearable.maxTokenSupply(tokenId), maxSupply, "Invalid getMintAmountLeft for tokenId");
            assertEq(wearable.getMintAmountLeft(tokenId), maxSupply, "Invalid getMintAmountLeft for tokenId");
        }

        /// Verfiy Consumable
        for (uint256 i = 0; i < consumableTokenIDMaxSupplySettings.length; i++) {
            uint256 tokenId = consumableTokenIDMaxSupplySettings[i].tokenId;
            uint256 maxSupply = consumableTokenIDMaxSupplySettings[i].maxSupply;

            ERC1155MaxSupplyMintable consumable = ERC1155MaxSupplyMintable(
                addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES")
            );

            assertEq(consumable.maxTokenSupply(tokenId), maxSupply, "Invalid getMintAmountLeft for tokenId");
            assertEq(consumable.getMintAmountLeft(tokenId), maxSupply, "Invalid getMintAmountLeft for tokenId");
        }

        /// Verfiy Season One
        ERC1155SeasonOne seasonOne = ERC1155SeasonOne(addresses.getAddress("ERC1155_SEASON_ONE"));

        assertEq(seasonOne.totalRewardTokens(), 30001521e18, "Invalid totalRewardTokens");
        assertEq(seasonOne.totalRewardTokensUsed(), 0, "Invalid totalRewardTokensUsed");
        assertEq(seasonOne.totalClawedBack(), 0, "Invalid totalClawedBack");

        for (uint256 i = 0; i < tokenIdRewardAmounts.length; i++) {
            uint256 tokenId = tokenIdRewardAmounts[i].tokenId;
            uint256 rewardAmount = tokenIdRewardAmounts[i].rewardAmount;

            assertEq(seasonOne.tokenIdRewardAmount(tokenId), rewardAmount, "Invalid tokenIdRewardAmount");
            assertEq(seasonOne.tokenIdUsedAmount(tokenId), 0, "Invalid tokenIdUsedAmount");
        }
    }

    function _validateOnChain(Addresses, address deployer) internal virtual override {}

    function _validateForTestingOnly(Addresses, address deployer) internal virtual override {}
}
