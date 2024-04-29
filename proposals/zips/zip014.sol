//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "@forge-std/console.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";
import {TimelockProposal} from "@proposals/proposalTypes/TimelockProposal.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

contract zip014 is TimelockProposal {

    struct TokenIDMaxSupplySettings {
        uint256 maxSupply;
        uint256 tokenId;
    }

    TokenIDMaxSupplySettings[] private wearableTokenIDMaxSupplySettings;

    constructor() Proposal("ADMIN_TIMELOCK_CONTROLLER") {}

    // Returns the name of the proposal.
    function name() public pure override returns (string memory) {
        return "ZIP014";
    }

    // Provides a brief description of the proposal.
    function description() public pure override returns (string memory) {
        return "ZTX CGv1.4 MaxSupply updates";
    }

    function setAndConfirmWearableData() private {
        // Wearable data
        string memory wearableData = string(
            abi.encodePacked(vm.readFile("./proposals/zips/zip014.json"))
        );

        bytes memory parsedJson = vm.parseJson(wearableData);

        TokenIDMaxSupplySettings[] memory wearablesDecoded = abi.decode(
            parsedJson,
            (TokenIDMaxSupplySettings[])
        );

       wearableTokenIDMaxSupplySettings.push(
            TokenIDMaxSupplySettings(
                wearablesDecoded[0].maxSupply,
                wearablesDecoded[0].tokenId
            )
        );

        // sanity checks
        assertEq(wearableTokenIDMaxSupplySettings.length, 1, "Invalid wearableTokenIDMaxSupplySettings length");
        assertEq(wearableTokenIDMaxSupplySettings[0].maxSupply, 420, "Invalid maxSupplyTotal");
    }

    function _beforeDeploy() internal override {
        setAndConfirmWearableData();
    }

    function _build() internal override {
        /// Wearable config
        ERC1155MaxSupplyMintable wearables = ERC1155MaxSupplyMintable(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")
        );
        wearables.setSupplyCap(wearableTokenIDMaxSupplySettings[0].tokenId, wearableTokenIDMaxSupplySettings[0].maxSupply);
    }

    function _run() internal override {
        _simulateActions(
            addresses.getAddress("ADMIN_MULTISIG"),
            addresses.getAddress("ADMIN_MULTISIG")
        );
    }

    function _validate() internal override {
        ERC1155MaxSupplyMintable wearable = ERC1155MaxSupplyMintable(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")
        );

        /// Verfiy Wearable
        uint256 tokenId = wearableTokenIDMaxSupplySettings[0].tokenId;
        uint256 maxSupply = wearableTokenIDMaxSupplySettings[0].maxSupply;
        uint256 currentSupply = wearable.totalSupply(tokenId);

        assertEq(wearable.maxTokenSupply(tokenId), maxSupply, "Invalid maxTokenSupply for tokenId");
        assertEq(wearable.getMintAmountLeft(tokenId), maxSupply - currentSupply, "Invalid getMintAmountLeft for tokenId");
    }
}
