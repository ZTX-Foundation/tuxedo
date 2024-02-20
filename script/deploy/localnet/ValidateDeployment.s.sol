// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {zip000 as zip} from "@proposals/zips/zip000.sol";
import {Script} from "@forge-std/Script.sol";
import {Addresses, EnvVar} from "@proposals/Addresses.sol";
import {BaseValidProposal} from "@script/deploy/BaseValidProposal.s.sol";

contract DeployProposal is Script, BaseValidProposal,zip {

    function setUp() public override {
        super.setUp();
    }

    function run() public {
        Addresses addresses = new Addresses(EnvVar.LocalNet);
        addresses.resetRecordingAddresses();

        // /// Run the deploy OnChain workflow
        validOnChain(addresses, privateKey);

        addresses.printRecordedAddresses();
    }
}
