// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity 0.8.18;

import {ERC1155, ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

import {ERC1155Sale} from "@protocol/sale/ERC1155Sale.sol";
import {MockMaliciousReceiver} from "@test/mock/MockMaliciousReceiver.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

contract CrossFunctionReentrancy is MockMaliciousReceiver {
    ERC1155 public erc1155;

    constructor(ERC1155Sale _sale, address token, address _erc1155) MockMaliciousReceiver(_sale, token) {
        erc1155 = ERC1155(_erc1155);
    }

    /// cross function reentrancy is allowed
    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256 amount,
        bytes memory
    ) public override returns (bytes4) {
        /// transfer on receive
        if (erc1155.balanceOf(address(this), id) > 0) {
            erc1155.safeTransferFrom(
                address(this),
                address(1),
                id,
                amount,
                ""
            );
        }

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) public virtual override returns (bytes4) {
        ERC1155MaxSupplyMintable(msg.sender).safeBatchTransferFrom(
            address(this),
            address(1),
            ids,
            amounts,
            ""
        );
        return this.onERC1155BatchReceived.selector;
    }
}