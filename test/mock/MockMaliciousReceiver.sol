// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ERC1155Sale} from "@protocol/sale/ERC1155Sale.sol";

contract MockMaliciousReceiver is ERC1155Holder {
    ERC1155Sale public sale;
    bool public isBuying;

    constructor(ERC1155Sale _sale, address token) {
        sale = _sale;
        IERC20(token).approve(address(_sale), type(uint256).max);
    }

    /// kick off purchase to gain control flow back
    function purchaseTokens(uint256 tokenId, uint256 amountToPurchase) external {
        isBuying = true;
        bytes32[] memory userProof = new bytes32[](0);

        sale.buyToken(
            tokenId,
            amountToPurchase,
            amountToPurchase,
            userProof,
            address(this)
        );
    }
}
