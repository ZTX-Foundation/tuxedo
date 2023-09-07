pragma solidity 0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    constructor() ERC721("MockToken", "MCT") {}

    function mint(address account, uint256 tokenId) public {
        _mint(account, tokenId);
    }
}
