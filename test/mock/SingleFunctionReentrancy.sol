// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity 0.8.18;

import {MockMaliciousReceiver} from "@test/mock/MockMaliciousReceiver.sol";
import {ERC1155Sale} from "@protocol/sale/ERC1155Sale.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

contract SingleFunctionReentrancy is MockMaliciousReceiver {
    constructor(ERC1155Sale _sale, address token) MockMaliciousReceiver(_sale, token) {}

    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256 amount,
        bytes memory
    ) public override returns (bytes4) {
        /// try a single reentrant purchase call
        if (isBuying) {
            isBuying = false;
            bytes32[] memory userProof = new bytes32[](0);
            sale.buyToken(id, amount, amount, userProof, address(this));
        }

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory
    ) public virtual override returns (bytes4) {
        /// infinite reentrancy, will fail the first try
        ERC1155MaxSupplyMintable(msg.sender).mintBatch(
            address(this), tokenIds, amounts
        );
        return this.onERC1155BatchReceived.selector;
    }
}
