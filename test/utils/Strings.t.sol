pragma solidity 0.8.18;

import "@forge-std/Test.sol";
import "@protocol/utils/Strings.sol";

contract StringsUtils is Test {
    using StringUtils for string;

    function testToLowerCase() public {
        string memory input = "HELLO";
        string memory output = input.toLowerCase();
        string memory expected = "hello";
        assertEq(output, expected);
    }

    function testEquals() public {
        string memory input = "HELLO";
        string memory input2 = "hello";
        bool output = input.equals(input2);
        bool expected = false;
        assertEq(output, expected);
    }
}
