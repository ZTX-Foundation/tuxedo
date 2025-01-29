//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {TimelockProposal} from "@forge-proposal-simulator/src/proposals/TimelockProposal.sol";

import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

contract zip019 is TimelockProposal {

    struct TokenIDMaxSupplySettings {
        uint256 maxSupply;
        uint256 tokenId;
    }

    TokenIDMaxSupplySettings[] private wearableTokenIDMaxSupplySettings;

    // Returns the name of the proposal.
    function name() public pure override returns (string memory) {
        return "ZIP019";
    }

    // Provides a brief description of the proposal.
    function description() public pure override returns (string memory) {
        return "ZTX CGv1.4 MaxSupply updates";
    }

    function setAndConfirmWearableData() private {
        // Wearable data
        string memory wearableData = string(
            abi.encodePacked(vm.readFile("./proposals/zips/zip019.json"))
        );

        bytes memory parsedJson = vm.parseJson(wearableData);

        TokenIDMaxSupplySettings[] memory wearablesDecoded = abi.decode(
            parsedJson,
            (TokenIDMaxSupplySettings[])
        );

        for (uint256 i = 0; i < wearablesDecoded.length; i++) {
            wearableTokenIDMaxSupplySettings.push(
                TokenIDMaxSupplySettings(
                    wearablesDecoded[i].maxSupply,
                    wearablesDecoded[i].tokenId
                )
            );
        }

        // sanity checks
        assertEq(wearableTokenIDMaxSupplySettings.length, 27, "Invalid wearableTokenIDMaxSupplySettings length");

        uint maxSupplyTotal = 0;

        // sum numbers from requrements sheet
        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            maxSupplyTotal += wearableTokenIDMaxSupplySettings[i].maxSupply;
        }

        assertEq(maxSupplyTotal, 4780700, "Invalid maxSupplyTotal");
    }

    function build() public override buildModifier(addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER")) {
        /// Wearable config
        ERC1155MaxSupplyMintable wearable = ERC1155MaxSupplyMintable(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")
        );
        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            wearable.setSupplyCap(wearableTokenIDMaxSupplySettings[i].tokenId, wearableTokenIDMaxSupplySettings[i].maxSupply);
        }
    }

    function run() public override {
        setTimelock(addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"));

        setAndConfirmWearableData();

        super.run();
    }

    function simulate() public override {
        address multisig = addresses.getAddress("ADMIN_MULTISIG");

        /// Multisig is proposer and executor
        _simulateActions(multisig, multisig);
    }

    function validate() public override {
        ERC1155MaxSupplyMintable wearable = ERC1155MaxSupplyMintable(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")
        );

        /// Verfiy Wearable
        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            uint256 tokenId = wearableTokenIDMaxSupplySettings[i].tokenId;
            uint256 maxSupply = wearableTokenIDMaxSupplySettings[i].maxSupply;
            uint256 currentSupply = wearable.totalSupply(tokenId);

            assertEq(wearable.maxTokenSupply(tokenId), maxSupply, "Invalid maxTokenSupply for tokenId");
            assertEq(wearable.getMintAmountLeft(tokenId), maxSupply - currentSupply, "Invalid getMintAmountLeft for tokenId");
        }
    }
}
