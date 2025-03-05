//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import {TimelockProposal} from "@forge-proposal-simulator/src/proposals/TimelockProposal.sol";

import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

contract zip010 is TimelockProposal {

    struct TokenIDMaxSupplySettings {
        uint256 maxSupply;
        uint256 tokenId;
    }

    TokenIDMaxSupplySettings[] private placeableTokenIDMaxSupplySettings;

    // Returns the name of the proposal.
    function name() public pure override returns (string memory) {
        return "ZIP010";
    }

    // Provides a brief description of the proposal.
    function description() public pure override returns (string memory) {
        return "ZTX CGv1.3 MaxSupply updates";
    }

    function _setAndConfirmPaceableData() private {
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

    function build()
        public
        override
        buildModifier(addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER")) 
    {
        /// Paceable config
        ERC1155MaxSupplyMintable placeables = ERC1155MaxSupplyMintable(addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES"));
        placeables.setSupplyCap(placeableTokenIDMaxSupplySettings[0].tokenId, placeableTokenIDMaxSupplySettings[0].maxSupply);
    }

    function run() public override {
        setTimelock(addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"));

        _setAndConfirmPaceableData();
        
        super.run();
    }

    function simulate() public override {
        address multisig = addresses.getAddress("ADMIN_MULTISIG");

        /// Multisig is proposer and executor
        _simulateActions(multisig, multisig);
    }

    function validate() public override {
        ERC1155MaxSupplyMintable placeable = ERC1155MaxSupplyMintable(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")
        );

        /// Verify Paceable
        uint256 tokenId = placeableTokenIDMaxSupplySettings[0].tokenId;
        uint256 maxSupply = placeableTokenIDMaxSupplySettings[0].maxSupply;
        uint256 currentSupply = placeable.totalSupply(tokenId);

        assertEq(placeable.maxTokenSupply(tokenId), maxSupply, "Invalid maxTokenSupply for tokenId");
        assertEq(placeable.getMintAmountLeft(tokenId), maxSupply - currentSupply, "Invalid getMintAmountLeft for tokenId");
    }
}
