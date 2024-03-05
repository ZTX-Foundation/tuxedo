// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {Script} from "@forge-std/Script.sol";
import {Addresses, EnvVar} from "@proposals/Addresses.sol";
import {BaseDeployCompleteSystem} from "@script/deploy/BaseDeployCompleteSystem.s.sol";

contract DeployCompleteSystem is Script, BaseDeployCompleteSystem {
    function setUp() public override {
        super.setUp();
    }

    function run() public {
        Addresses addresses = new Addresses(EnvVar.SandPitNet);
        addresses.resetRecordingAddresses();

        super.deployOnTestNet(addresses);

        // Print the recorded addresses
        addresses.printRecordedAddresses();
    }
}
