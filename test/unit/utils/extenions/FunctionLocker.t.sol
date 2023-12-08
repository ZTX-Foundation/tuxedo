pragma solidity 0.8.18;

import "@forge-std/Test.sol";
import {FunctionLocker} from "@protocol/utils/extensions/FunctionLocker.sol";

contract dummy is FunctionLocker {
    uint256 public Singleton;

    function doStuff() public lockFunction("doStuff") {
        Singleton = 1;
    }
}

contract UnitTestFunctionLocker is Test {
    dummy public dummyContract;

    function setUp() public {
        dummyContract = new dummy();
    }

    function testLockFunction() public {
        assertEq(dummyContract.Singleton(), 0);
        dummyContract.doStuff();
        assertEq(dummyContract.Singleton(), 1);
        vm.expectRevert("FunctionLocker: function locked");
        dummyContract.doStuff();
    }
}
