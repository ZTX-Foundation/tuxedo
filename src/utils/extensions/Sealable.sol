// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @notice This sealable contract extenions can be used to create a single use function that is only callable once and then locked.
/// @dev note that this can only be used on a single function call per contract due to the single seal variable.
abstract contract Sealable {
    bool public seal = false;

    modifier sealAfter() {
        require(!seal, "Sealable: Contract already Sealed");
        _;
        seal = true;
    }
}
