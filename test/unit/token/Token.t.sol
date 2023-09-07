pragma solidity 0.8.18;

import "@forge-std/Test.sol";

import {Token} from "@protocol/token/Token.sol";

/// TODO this test suite needs to be much more comprehensive to prove the overrides work and use the ERC20Votes functionality
contract UnitTestToken is Test {
    /// 10 billion (10^10) tokens max supply with 10^18 decimals
    uint256 constant MAX_SUPPLY = 10_000_000_000e18;

    Token public token;

    function setUp() public {
        token = new Token("TKN Token", "TKN");
    }

    function testTokenName() public {
        assertEq(token.name(), "TKN Token");
    }

    function testTokenSymbol() public {
        assertEq(token.symbol(), "TKN");
    }

    function testPreMint() public {
        assertEq(token.balanceOf(address(this)), MAX_SUPPLY);
    }

    function testMaxSupply() public {
        assertEq(token.maxSupply(), MAX_SUPPLY);
    }

    function testTotalSupply() public {
        assertEq(token.totalSupply(), MAX_SUPPLY);
    }
}
