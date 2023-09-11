pragma solidity 0.8.18;

import {SeasonsBase} from "@protocol/nfts/seasons/SeasonsBase.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";

contract ERC1155SeasonOne is SeasonsBase {
    constructor(address _core, address _nftSeasonContract) SeasonsBase(_core, _nftSeasonContract) {}
}
