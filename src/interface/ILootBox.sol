pragma solidity 0.8.18;

// Interface for the Loot Box Contract
interface ILootBox {
    /**
     * @notice Buy a specified number of loot boxes.
     * @param numberOfBoxes The number of loot boxes to purchase.
     * @return An array of ERC1155 token IDs representing the purchased loot boxes.
     */
    function buyLootBoxes(uint256 numberOfBoxes) external returns (uint256[] memory);

    /**
     * @notice Claim a purchased loot box.
     * @param tokenId The ID of the ERC1155 token representing the loot box to claim.
     */
    function claimLootBox(uint256 tokenId) external;

    /**
     * @notice Bulk claim purchased loot boxes.
     * @param tokenIds An array of ERC1155 token IDs representing the loot boxes to claim.
     */
    function bulkClaimLootBoxes(uint256[] calldata tokenIds) external;

    /**
     * @notice Get the count of unclaimed loot boxes for a user.
     * @param user The address of the user.
     * @return The number of unclaimed loot boxes.
     */
    function getUnclaimedBoxCount(address user) external view returns (uint256);

    /**
     * @notice Get the items in a user's unclaimed loot box.
     * @param user The address of the user.
     * @return An array of ERC1155 token IDs representing the items in the user's unclaimed loot box.
     */
    function getUnclaimedBoxItems(address user) external view returns (uint256[] memory);
}
