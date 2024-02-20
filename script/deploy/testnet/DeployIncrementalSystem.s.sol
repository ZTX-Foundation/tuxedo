// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {zip000 as zip} from "@proposals/zips/zip000.sol";
import {Script} from "@forge-std/Script.sol";
import {Addresses, EnvVar} from "@proposals/Addresses.sol";
import {BaseIncrementalSystem} from "@script/deploy/BaseIncrementalSystem.s.sol";

contract DeployIncrementalSystem is Script, BaseIncrementalSystem, zip {
    function setUp() public override {
        super.setUp();
    }

    function run() public {
        Addresses addresses = new Addresses(EnvVar.TestNet);
        addresses.resetRecordingAddresses();

        /// Run the deploy OnChain workflow
        deployOnTestNet(addresses, privateKey);

        // Print the recorded addresses
        addresses.printRecordedAddresses();
    }
}
