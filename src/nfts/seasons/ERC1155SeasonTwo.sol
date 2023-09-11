pragma solidity 0.8.18;

import {ERC1155, ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {SeasonsBase} from "@protocol/nfts/seasons/SeasonsBase.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";

contract ERC1155SeasonTwo is SeasonsBase {
    constructor(address _core, address _nftSeasonContract) SeasonsBase(_core, _nftSeasonContract) {}
}
