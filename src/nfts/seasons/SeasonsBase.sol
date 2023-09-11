pragma solidity 0.8.18;

import {ERC1155, ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";

abstract contract SeasonsBase is CoreRef {
    ERC1155 public immutable nftSeaonContract;

    constructor(address _core, address _nftSeasonContract) CoreRef(_core) {
        nftSeaonContract = ERC1155(_nftSeasonContract);
    }
}
