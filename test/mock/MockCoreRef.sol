// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {Roles} from "@protocol/core/Roles.sol";

contract MockCoreRef is CoreRef {
    constructor(address core) CoreRef(core) {}

    function testAdmin() public onlyRole(Roles.ADMIN) {}

    function testTokenGovernor() public onlyRole(Roles.GOVERNOR_DAO_PROTOCOL_ROLE) {}

    function testMinter() public onlyRole(Roles.MINTER_PROTOCOL_ROLE) {}

    function testFinancialController() public onlyRole(Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE) {}

    function testGuardian() public onlyRole(Roles.GUARDIAN) {}

    function testLocker() public onlyRole(Roles.LOCKER_PROTOCOL_ROLE) {}
}
