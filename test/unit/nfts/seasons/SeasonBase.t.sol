pragma solidity 0.8.18;

import {BaseTest} from "@test/BaseTest.sol";

// TODO is this needed or over kill?
contract SeasonBase is BaseTest {
    function setUp() public virtual override {
        super.setUp();
    }
}
