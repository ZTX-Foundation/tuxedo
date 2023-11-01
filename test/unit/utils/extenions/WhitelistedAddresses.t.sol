// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "@forge-std/Test.sol";
import "@protocol/utils/extensions/WhitelistedAddresses.sol";

contract TestContract is WhitelistedAddresses {
    constructor(address[] memory _addresses) WhitelistedAddresses(_addresses) {}

    function addWhitelistAddress(address _address) public {
        _addWhitelistAddress(_address);
    }

    function removeWhitelistAddress(address _address) public {
        _removeWhitelistAddress(_address);
    }

    function addWhitelistAddresses(address[] calldata _addresses) public {
        _addWhitelistAddresses(_addresses);
    }

    function removeWhitelistAddresses(address[] calldata _addresses) public {
        _removeWhitelistAddresses(_addresses);
    }
}

contract UnitTestWhitelistedAddressesTest is Test {
    TestContract public dummy;

    address[] public _defaultAddresses = [address(0x123), address(0x456), address(789)];
    address[] public _addAddresses = [address(0x987), address(0x654), address(0x321)];

    function setUp() public {
        dummy = new TestContract(_defaultAddresses);
    }

    function testGetWhitelistedAddresses() public {
        address[] memory addr = dummy.getWhitelistedAddresses();
        assertEq(addr, _defaultAddresses);
    }

    function testAddWhitelistAddress() public {
        dummy.addWhitelistAddress(address(0x1));
        assertTrue(dummy.isWhitelistedAddress(address(0x1)));
    }

    function testRemoveWhitelistAddress() public {
        dummy.removeWhitelistAddress(address(0x123));
        assertFalse(dummy.isWhitelistedAddress(address(0x123)));
    }

    function testAddWhitelistAddresses() public {
        dummy.addWhitelistAddresses(_addAddresses);
        assertTrue(dummy.isWhitelistedAddress(address(0x321)));
    }

    function testRemoveWhitelistAddresses() public {
        dummy.removeWhitelistAddresses(_defaultAddresses);
        assertFalse(dummy.isWhitelistedAddress(address(0x123)));
    }

    function testIsWhitelistedAddress() public {
        assertFalse(dummy.isWhitelistedAddress(address(0x1)));
        assertTrue(dummy.isWhitelistedAddress(address(0x123)));
    }
}
