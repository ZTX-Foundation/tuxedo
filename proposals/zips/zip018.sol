import "@forge-std/console.sol";

import {Addresses} from "@proposals/Addresses.sol";
import {Proposal} from "@proposals/proposalTypes/Proposal.sol";
import {TimelockProposal} from "@proposals/proposalTypes/TimelockProposal.sol";
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

    constructor() Proposal("ADMIN_TIMELOCK_CONTROLLER") {}

    // Returns the name of the proposal.
    function name() public pure override returns (string memory) {
        return "ZIP018";
    }

    // Provides a brief description of the proposal.
    function description() public pure override returns (string memory) {
        return "ZTX CGv1.4 MaxSupply updates";
    }

    function setAndConfirmData() private {
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

        // Sanity checks for placeables
        assertEq(placeableTokenIDMaxSupplySettings.length, 24, "Invalid placeableTokenIDMaxSupplySettings length");

        uint placeableMaxSupplyTotal = 0;

        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            placeableMaxSupplyTotal += wearableTokenIDMaxSupplySettings[i].maxSupply;
        }

        assertEq(placeableMaxSupplyTotal, 1366000, "Invalid maxSupplyTotal for placeables");

        // Sanity checks for wearables
        assertEq(wearableTokenIDMaxSupplySettings.length, 5, "Invalid wearableTokenIDMaxSupplySettings length");

        uint wearableMaxSupplyTotal = 0;

        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            wearableMaxSupplyTotal += wearableTokenIDMaxSupplySettings[i].maxSupply;
        }

        assertEq(wearableMaxSupplyTotal, 268, "Invalid maxSupplyTotal for wearables");
    }

    function _beforeDeploy() internal override {
        setAndConfirmData();
    }

    function _build() internal override {
        /// Wearable config
        ERC1155MaxSupplyMintable wearable = ERC1155MaxSupplyMintable(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")
        );
        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            wearable.setSupplyCap(wearableTokenIDMaxSupplySettings[i].tokenId, wearableTokenIDMaxSupplySettings[i].maxSupply);
        }
        
        // Placeable config
        ERC1155MaxSupplyMintable placeable = ERC1155MaxSupplyMintable(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")
        );
        for (uint256 i = 0; i < placeableTokenIDMaxSupplySettings.length; i++) {
            placeable.setSupplyCap(placeableTokenIDMaxSupplySettings[i].tokenId, placeableTokenIDMaxSupplySettings[i].maxSupply);
        }
    }

    function _validate() internal override {
        ERC1155MaxSupplyMintable wearable = ERC1155MaxSupplyMintable(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")
        );

        /// Verify Wearable
        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            uint256 tokenId = wearableTokenIDMaxSupplySettings[i].tokenId;
            uint256 maxSupply = wearableTokenIDMaxSupplySettings[i].maxSupply;
            uint256 currentSupply = wearable.totalSupply(tokenId);

            assertEq(wearable.maxTokenSupply(tokenId), maxSupply, "Invalid maxTokenSupply for tokenId");
            assertEq(wearable.getMintAmountLeft(tokenId), maxSupply - currentSupply, "Invalid getMintAmountLeft for tokenId");
        }

        // Verify Placeable
        ERC1155MaxSupplyMintable placeable = ERC1155MaxSupplyMintable(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")
        );
        for (uint256 i = 0; i < placeableTokenIDMaxSupplySettings.length; i++) {
            uint256 tokenId = placeableTokenIDMaxSupplySettings[i].tokenId;
            uint256 maxSupply = placeableTokenIDMaxSupplySettings[i].maxSupply;
            uint256 currentSupply = placeable.totalSupply(tokenId);

            assertEq(placeable.maxTokenSupply(tokenId), maxSupply, "Invalid maxTokenSupply for tokenId");
            assertEq(placeable.getMintAmountLeft(tokenId), maxSupply - currentSupply, "Invalid getMintAmountLeft for tokenId");
        }
    }
}
