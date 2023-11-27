pragma solidity 0.8.18;

import "@forge-std/Test.sol";

import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {MockWeth} from "@test/mock/MockWeth.sol";
import {MockERC20} from "@test/mock/MockERC20.sol";
import {Constants} from "@protocol/Constants.sol";
import {ERC1155Sale} from "@protocol/sale/ERC1155Sale.sol";
import {ERC20Splitter} from "@protocol/finance/ERC20Splitter.sol";
import {MockERC20, IERC20} from "@test/mock/MockERC20.sol";
import {GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";
import {getSystem, configureSale, setSupplyCap} from "@test/fixtures/Fixtures.sol";

contract BaseTest is Test, ERC1155Holder {
    Core public core;
    GlobalReentrancyLock public lock;
    ERC1155Sale public sale;
    ERC1155MaxSupplyMintable public nft;
    ERC20Splitter public splitter;
    MockERC20 public token;
    MockWeth public weth;

    address constant proceedsRecipient = address(111_111);
    address constant feeRecipient = address(222_222);

    uint256 constant tokenId = 100;

    /// 100 DAI per ERC1155 token
    uint232 constant tokenPrice = 100e18;

    /// 3% fee
    uint16 constant fee = 300; /// 300 basis points

    uint256 constant supplyCap = 10_000;

    function setUp() public virtual {
        (core, lock, splitter, token, nft, sale) = getSystem(vm);
        weth = MockWeth(address(sale.weth()));

        configureSale(vm, tokenId, sale, proceedsRecipient, feeRecipient, address(token), tokenPrice, fee);
        setSupplyCap(vm, nft, tokenId, supplyCap);

        vm.warp(block.timestamp + 1); /// start the sale
    }
}
