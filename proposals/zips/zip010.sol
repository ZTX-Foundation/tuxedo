//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "@forge-std/console.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";
import {TimelockProposal} from "@proposals/proposalTypes/TimelockProposal.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

contract zip010 is Proposal, TimelockProposal {
    string public name = "ZIP010";
    string public description = "ZTX CGv1.3 MaxSupply updates";

    struct TokenIDMaxSupplySettings {
        uint256 maxSupply;
        uint256 tokenId;
    }

    TokenIDMaxSupplySettings[] private placeableTokenIDMaxSupplySettings;

    function setAndConfirmPaceableData() private {
        // Paceable data
        string memory placeableData = string(
            abi.encodePacked(vm.readFile("./proposals/zips/zip010.json"))
        );

        bytes memory parsedJson = vm.parseJson(placeableData);

        TokenIDMaxSupplySettings[] memory placeablesDecoded = abi.decode(
            parsedJson,
            (TokenIDMaxSupplySettings[])
        );

        placeableTokenIDMaxSupplySettings.push(
            TokenIDMaxSupplySettings(
                placeablesDecoded[0].maxSupply,
                placeablesDecoded[0].tokenId
            )
        );

        // sanity checks
        assertEq(placeableTokenIDMaxSupplySettings.length, 1, "Invalid placeableTokenIDMaxSupplySettings length");

        uint maxSupplyTotal = placeableTokenIDMaxSupplySettings[0].maxSupply;
        assertEq(maxSupplyTotal, 100_000, "Invalid maxSupplyTotal");
    }

    function _beforeDeploy(Addresses, address deployer) internal override {
        setAndConfirmPaceableData();
    }

    function _deploy(Addresses addresses, address) internal override {}

    function _afterDeploy(Addresses addresses, address) internal override {}

    function _afterDeployOnChain(Addresses, address deployer) internal virtual override {}

    function _aferDeployForTestingOnly(Addresses, address deployer) internal virtual override {}

    function _teardown(Addresses addresses, address deployer) internal override {}

    function _build(Addresses addresses, address) internal override {
        /// Paceable config
        address placeables = addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES");
        _pushTimelockAction(
            placeables,
            abi.encodeWithSignature(
                "setSupplyCap(uint256,uint256)",
                placeableTokenIDMaxSupplySettings[0].tokenId,
                placeableTokenIDMaxSupplySettings[0].maxSupply
            ),
            string(
                abi.encodePacked(
                    "Set placeable tokenId ",
                    placeableTokenIDMaxSupplySettings[0].tokenId,
                    " to max supply ",
                    placeableTokenIDMaxSupplySettings[0].maxSupply
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
        ERC1155MaxSupplyMintable placeable = ERC1155MaxSupplyMintable(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")
        );

        /// Verfiy Paceable
        uint256 tokenId = placeableTokenIDMaxSupplySettings[0].tokenId;
        uint256 maxSupply = placeableTokenIDMaxSupplySettings[0].maxSupply;
        uint256 currentSupply = placeable.totalSupply(tokenId);

        assertEq(placeable.maxTokenSupply(tokenId), maxSupply, "Invalid maxTokenSupply for tokenId");
        assertEq(placeable.getMintAmountLeft(tokenId), maxSupply - currentSupply, "Invalid getMintAmountLeft for tokenId");
    }

    function _validateOnChain(Addresses, address deployer) internal virtual override {}

    function _validateForTestingOnly(Addresses, address deployer) internal virtual override {}
}
