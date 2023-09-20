pragma solidity 0.8.18;

import {CoreRef} from "@protocol/refs/CoreRef.sol";

contract SeasonsTokenIdRegistry is CoreRef {
    mapping(uint256 tokenId => address seasonContract) public tokenIdSeasonContract;

    constructor(address _core) CoreRef(_core) {}

    //TODO permission with a Role
    /// @notice Register a tokenId to a seasonContract
    function register(uint256 tokenId, address seasonContract) public {
        _register(tokenId, seasonContract);
    }

    function _register(uint256 tokenId, address seasonContract) internal {
        require(
            tokenIdSeasonContract[tokenId] == address(0),
            "SeasonsTokenIdRegistry: tokenId already registered to a Season Contract"
        );
        tokenIdSeasonContract[tokenId] = seasonContract;
    }

    // TODO permission with a Role
    function registerBatch(uint256[] memory tokenIds, address seasonContract) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _register(tokenIds[i], seasonContract);
        }
    }
}
