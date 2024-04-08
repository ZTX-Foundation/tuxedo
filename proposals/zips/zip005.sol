//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";
import {TimelockProposal} from "@proposals/proposalTypes/TimelockProposal.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

contract zip005 is Proposal, TimelockProposal {
    string public name = "ZIP005";
    string public description = "ZTX CGv1.2 MaxSupply updates for placeables";

    struct TokenIDMaxSupplySettings {
        uint256 tokenId;
        uint256 maxSupply;
    }

    TokenIDMaxSupplySettings[] private placeableTokenIDMaxSupplySettings;

    function setAndConfirmPlaceableData() private {
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(2, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(3, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(5, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(6, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(7, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(9, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(10, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(11, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(13, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(19, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(20, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(22, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(26, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(29, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(30, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(32, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(33, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(34, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(35, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(36, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(37, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(39, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(41, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(42, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(44, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(48, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(49, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(50, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(51, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(52, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(53, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(55, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(56, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(57, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(58, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(59, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(61, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(62, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(63, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(66, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(68, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(71, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(73, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(75, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(77, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(78, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(79, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(80, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(81, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(83, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(89, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(91, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(92, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(93, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(97, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(98, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(99, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(100, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(101, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(102, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(104, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(108, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(109, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(110, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(112, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(113, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(114, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(115, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(118, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(125, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(128, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(131, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(132, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(133, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(134, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(135, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(138, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(139, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(140, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(141, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(142, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(143, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(145, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(146, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(147, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(150, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(151, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(168, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(349, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(350, 6000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(352, 100000));
        placeableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(353, 100000));

        // sanity checks
        assertEq(placeableTokenIDMaxSupplySettings.length, 92, "Invalid placeableTokenIDMaxSupplySettings length");

        uint tokenIDTotal = 0;
        uint maxSupplyTotal = 0;

        // sum numbers from requrements sheet
        for (uint256 i = 0; i < placeableTokenIDMaxSupplySettings.length; i++) {
            tokenIDTotal += placeableTokenIDMaxSupplySettings[i].tokenId;
            maxSupplyTotal += placeableTokenIDMaxSupplySettings[i].maxSupply;
        }

        assertEq(tokenIDTotal, 8_227, "Invalid tokenIDTotal");
        assertEq(maxSupplyTotal, 6_380_000, "Invalid maxSupplyTotal");
    }

    function _beforeDeploy(Addresses, address deployer) internal override {
        setAndConfirmPlaceableData();
    }

    function _deploy(Addresses addresses, address) internal override {}

    function _afterDeploy(Addresses addresses, address) internal override {}

    function _afterDeployOnChain(Addresses, address deployer) internal virtual override {}

    function _aferDeployForTestingOnly(Addresses, address deployer) internal virtual override {}

    function _teardown(Addresses addresses, address deployer) internal override {}

    function _build(Addresses addresses, address) internal override {
        /// Placeables config
        address placeables = addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES");
        for (uint256 i = 0; i < placeableTokenIDMaxSupplySettings.length; i++) {
            _pushTimelockAction(
                placeables,
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

            assertEq(placeable.maxTokenSupply(tokenId), maxSupply, "Invalid maxTokenSupply for tokenId");
            assertEq(placeable.getMintAmountLeft(tokenId), maxSupply, "Invalid getMintAmountLeft for tokenId");
        }
    }

    function _validateOnChain(Addresses, address deployer) internal virtual override {}

    function _validateForTestingOnly(Addresses, address deployer) internal virtual override {}
}
