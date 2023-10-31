pragma solidity 0.8.18;

import "@forge-std/Test.sol";

import {Token} from "@protocol/token/Token.sol";

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

    function testVotes() public {
        assertEq(token.getVotes(address(this)), MAX_SUPPLY);
    }

    function testDelegateVotesUndelegatesAfterReceiving() public {
        address to = address(2);
        uint256 transferAmount = 1000;

        assertEq(token.getVotes(address(this)), MAX_SUPPLY);
        token.transfer(to, transferAmount);

        assertEq(token.getVotes(address(this)), MAX_SUPPLY - transferAmount);
        assertEq(token.getVotes(to), transferAmount);

        vm.prank(to);
        token.delegate(address(this));

        assertEq(token.getVotes(address(this)), MAX_SUPPLY, "this should still have votes");
        assertEq(token.getVotes(to), 0, "to should not have votes");

        assertEq(token.delegates(to), address(this), "to delegate incorrect"); /// to delegates to this

        // this transfers to to from this, which undelegates to from this, and makes to delegate to itself
        token.transfer(to, 0); /// undelegate user

        assertEq(token.delegates(to), to); /// to delegates to itself

        assertEq(token.getVotes(address(this)), MAX_SUPPLY - transferAmount, "this vote incorrect");
        assertEq(token.getVotes(to), transferAmount, "to vote incorrect");
    }

    function testTransferVotes() public {
        token.approve(address(1), 1);
        token.transfer(address(1), 1);
        assertEq(token.getVotes(address(this)), MAX_SUPPLY - 1);

        vm.prank(address(1));
        assertEq(token.getVotes(address(1)), 1);
    }

    function testTransferVotesAgain() public {
        token.approve(address(1), 1);
        token.transfer(address(1), 1);
        assertEq(token.getVotes(address(this)), MAX_SUPPLY - 1);

        vm.startPrank(address(1));
        assertEq(token.getVotes(address(1)), 1);
        token.approve(address(2), 1);
        token.transfer(address(2), 1);
        assertEq(token.getVotes(address(1)), 0);
        vm.stopPrank();
    }
}
