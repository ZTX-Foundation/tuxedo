pragma solidity 0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/// Not burnable
contract Token is ERC20Permit, ERC20Votes {
    /// 10 billion (10^10) tokens max supply with 10^18 decimals
    uint256 public constant MAX_SUPPLY = 10_000_000_000e18;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) ERC20Permit(name) {
        _mint(msg.sender, MAX_SUPPLY);
    }

    /// TODO this should be reviewed as it is probably not necessary
    function maxSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    /// required for ERC20Snapshot
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /// require for ERC20Votes
    /// TODO confirm both erc20 and erc20votes _afterTokenTransfer hooks are called
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _burn(address account, uint256 amount) internal virtual override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Votes) {
        super._mint(account, amount);
    }
}
