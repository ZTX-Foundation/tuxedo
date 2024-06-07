//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {TimelockProposal} from "@forge-proposal-simulator/src/proposals/TimelockProposal.sol";

import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

contract zip018 is TimelockProposal {

    struct TokenIDMaxSupplySettings {
        uint256 maxSupply;
        uint256 tokenId;
    }

    struct Collections {
        TokenIDMaxSupplySettings[] placeables;
        TokenIDMaxSupplySettings[] wearables;
    }

    TokenIDMaxSupplySettings[] private placeableTokenIDMaxSupplySettings;
    TokenIDMaxSupplySettings[] private wearableTokenIDMaxSupplySettings;

    /// @notice ERC1155 collections
    ERC1155MaxSupplyMintable placeable;
    ERC1155MaxSupplyMintable wearable;

    // Returns the name of the proposal.
    function name() public pure override returns (string memory) {
        return "ZIP018";
    }

    // Provides a brief description of the proposal.
    function description() public pure override returns (string memory) {
        return "ZTX CGv1.4 MaxSupply updates";
    }

    function _setAndConfirmData() private {
        // Wearable and placeable data
        string memory data = string(
            abi.encodePacked(vm.readFile("./proposals/zips/zip018.json"))
        );

        bytes memory parsedJson = vm.parseJson(data);

        Collections memory decodedData = abi.decode(
            parsedJson,
            (Collections)
        );

        for (uint256 i = 0; i < decodedData.placeables.length; i++) {
            placeableTokenIDMaxSupplySettings.push(
                TokenIDMaxSupplySettings(
                    decodedData.placeables[i].maxSupply,
                    decodedData.placeables[i].tokenId
                )
            );
        }

        for (uint256 i = 0; i < decodedData.wearables.length; i++) {
            wearableTokenIDMaxSupplySettings.push(
                TokenIDMaxSupplySettings(
                    decodedData.wearables[i].maxSupply,
                    decodedData.wearables[i].tokenId
                )
            );
        }

        /// @notice sanity checks for placeables
        assertEq(placeableTokenIDMaxSupplySettings.length, 24, "Invalid placeableTokenIDMaxSupplySettings length");

        uint placeableMaxSupplyTotal = 0;

        for (uint256 i = 0; i < placeableTokenIDMaxSupplySettings.length; i++) {
            placeableMaxSupplyTotal += placeableTokenIDMaxSupplySettings[i].maxSupply;
        }

        assertEq(placeableMaxSupplyTotal, 1366000, "Invalid maxSupplyTotal for placeables");

        /// @notice sanity checks for wearables
        assertEq(wearableTokenIDMaxSupplySettings.length, 5, "Invalid wearableTokenIDMaxSupplySettings length");

        uint wearableMaxSupplyTotal = 0;

        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            wearableMaxSupplyTotal += wearableTokenIDMaxSupplySettings[i].maxSupply;
        }

        assertEq(wearableMaxSupplyTotal, 268, "Invalid maxSupplyTotal for wearables");
    }

    function build()
        public
        override
        buildModifier(addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER")) 
    {
         /// @notice placeable config
        for (uint256 i = 0; i < placeableTokenIDMaxSupplySettings.length; i++) {
            placeable.setSupplyCap(placeableTokenIDMaxSupplySettings[i].tokenId, placeableTokenIDMaxSupplySettings[i].maxSupply);
        }

        /// @notice wearable config
        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            wearable.setSupplyCap(wearableTokenIDMaxSupplySettings[i].tokenId, wearableTokenIDMaxSupplySettings[i].maxSupply);
        }
    }

    function run() public override {
        setTimelock(addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"));

        placeable = ERC1155MaxSupplyMintable(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")
        );
        wearable = ERC1155MaxSupplyMintable(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")
        );

        _setAndConfirmData();

        super.run();
    }

    function simulate() public override {
        address multisig = addresses.getAddress("ADMIN_MULTISIG");

        /// Multisig is proposer and executor
        _simulateActions(multisig, multisig);
    }

    function validate() public override {
        /// @notice verify placeables
        for (uint256 i = 0; i < placeableTokenIDMaxSupplySettings.length; i++) {
            uint256 tokenId = placeableTokenIDMaxSupplySettings[i].tokenId;
            uint256 maxSupply = placeableTokenIDMaxSupplySettings[i].maxSupply;
            uint256 currentSupply = placeable.totalSupply(tokenId);

            assertEq(placeable.maxTokenSupply(tokenId), maxSupply, "Invalid maxTokenSupply for tokenId");
            assertEq(placeable.getMintAmountLeft(tokenId), maxSupply - currentSupply, "Invalid getMintAmountLeft for tokenId");
        }

        /// @notice verify wearables
        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            uint256 tokenId = wearableTokenIDMaxSupplySettings[i].tokenId;
            uint256 maxSupply = wearableTokenIDMaxSupplySettings[i].maxSupply;
            uint256 currentSupply = wearable.totalSupply(tokenId);

            assertEq(wearable.maxTokenSupply(tokenId), maxSupply, "Invalid maxTokenSupply for tokenId");
            assertEq(wearable.getMintAmountLeft(tokenId), maxSupply - currentSupply, "Invalid getMintAmountLeft for tokenId");
        }
    }
}
