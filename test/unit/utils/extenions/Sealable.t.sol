pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "@protocol/utils/extensions/Sealable.sol";

contract Dummy is Sealable {
    uint public x = 1;

    function sealMe() public sealAfter {
        x = 2;
    }
}

contract UnitTestSealable is Test {
    Dummy private _dummy;

    function setUp() public {
        _dummy = new Dummy();
    }

    function testSeal() public {
        assertEq(_dummy.x(), 1);
        _dummy.sealMe();
        assertEq(_dummy.x(), 2);
        vm.expectRevert("Sealable: Contract already Sealed");
        _dummy.sealMe();
    }
}
