//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "@forge-std/console.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";
import {TimelockProposal} from "@proposals/proposalTypes/TimelockProposal.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

contract zip006 is Proposal, TimelockProposal {
    string public name = "ZIP006";
    string public description = "ZTX CGv1.2.4 MaxSupply updates ";

    struct TokenIDMaxSupplySettings {
        uint256 maxSupply;
        uint256 tokenId;
    }

    TokenIDMaxSupplySettings[] private wearableTokenIDMaxSupplySettings;

    function setAndConfirmWearableData() private {
        // Wearable data
        string memory wearableData = string(
            abi.encodePacked(vm.readFile("./proposals/zips/zip006.json"))
        );

        bytes memory parsedJson = vm.parseJson(wearableData);

        TokenIDMaxSupplySettings[] memory wearablesDecoded = abi.decode(
            parsedJson,
            (TokenIDMaxSupplySettings[])
        );

        for (uint256 i = 0; i < wearablesDecoded.length; i++) {
            wearableTokenIDMaxSupplySettings.push(TokenIDMaxSupplySettings(wearablesDecoded[i].maxSupply, wearablesDecoded[i].tokenId));
        }

        // sanity checks
        assertEq(wearableTokenIDMaxSupplySettings.length, 25, "Invalid wearableTokenIDMaxSupplySettings length");

        uint maxSupplyTotal = 0;

        // sum numbers from requrements sheet
        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            maxSupplyTotal += wearableTokenIDMaxSupplySettings[i].maxSupply;
        }

        assertEq(maxSupplyTotal, 2_306_069, "Invalid maxSupplyTotal");
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
        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            _pushTimelockAction(
                wearables,
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
        /// Verfiy Wearable
        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            uint256 tokenId = wearableTokenIDMaxSupplySettings[i].tokenId;
            uint256 maxSupply = wearableTokenIDMaxSupplySettings[i].maxSupply;

            ERC1155MaxSupplyMintable wearable = ERC1155MaxSupplyMintable(
                addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")
            );

            assertEq(wearable.maxTokenSupply(tokenId), maxSupply, "Invalid maxTokenSupply for tokenId");
            assertEq(wearable.getMintAmountLeft(tokenId), maxSupply, "Invalid getMintAmountLeft for tokenId");
        }
    }

    function _validateOnChain(Addresses, address deployer) internal virtual override {}

    function _validateForTestingOnly(Addresses, address deployer) internal virtual override {}
}
