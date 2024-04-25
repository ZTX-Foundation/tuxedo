//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "@forge-std/console.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";
import {TimelockProposal} from "@proposals/proposalTypes/TimelockProposal.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

contract zip012 is Proposal, TimelockProposal {
    string public name = "ZIP012";
    string public description = "ZTX CGv1.4 MaxSupply updates";

    struct TokenIDMaxSupplySettings {
        uint256 maxSupply;
        uint256 tokenId;
    }

    TokenIDMaxSupplySettings[] private wearableTokenIDMaxSupplySettings;

    function setAndConfirmWearableData() private {
        // Wearable data
        string memory wearableData = string(
            abi.encodePacked(vm.readFile("./proposals/zips/zip012.json"))
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
        assertEq(wearableTokenIDMaxSupplySettings[0].maxSupply, 120, "Invalid maxSupplyTotal");
    }

    function _beforeDeploy(Addresses, address deployer) internal override {
        setAndConfirmWearableData();
    }

    function _deploy(Addresses addresses, address) internal override {}

    function _afterDeploy(Addresses addresses, address) internal override {}

    function _afterDeployOnChain(Addresses, address deployer) internal virtual override {}

    function _aferDeployForTestingOnly(Addresses, address deployer) internal virtual override {}

    function _teardown(Addresses addresses, address deployer) internal override {}

    function _build(Addresses addresses, address) internal override {
        /// Wearable config
        address wearables = addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES");
        _pushTimelockAction(
            wearables,
            abi.encodeWithSignature(
                "setSupplyCap(uint256,uint256)",
                wearableTokenIDMaxSupplySettings[0].tokenId,
                wearableTokenIDMaxSupplySettings[0].maxSupply
            ),
            string(
                abi.encodePacked(
                    "Set wearable tokenId ",
                    wearableTokenIDMaxSupplySettings[0].tokenId,
                    " to max supply ",
                    wearableTokenIDMaxSupplySettings[0].maxSupply
                )
            )
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

    function _validateOnChain(Addresses, address deployer) internal virtual override {}

    function _validateForTestingOnly(Addresses, address deployer) internal virtual override {}
}
