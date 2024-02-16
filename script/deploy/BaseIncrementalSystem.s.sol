
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {Script} from "@forge-std/Script.sol";
import {Addresses,EnvVar} from "@proposals/Addresses.sol";
import {Config} from "@config/Config.sol";

contract BaseIncrementalSystem is Config, Script {

    function setUp() public virtual {
        // Default behavior: do debug prints
        // DEBUG = vm.envOr("DEBUG", true);
        privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        // Default behavior: do deploy
        doDeploy = vm.envOr("DO_DEPLOY", true);
        // Default behavior: do after-deploy
        doAfterdeploy = vm.envOr("DO_AFTERDEPLOY", true);
        // Default behavior: do validate
        doValidate = vm.envOr("DO_VALIDATE", true);
        // Default behavior: don't do teardown
        doTeardown = vm.envOr("DO_TEARDOWN", false);
    }
}
