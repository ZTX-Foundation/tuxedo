// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {zip001 as zip} from "@proposals/zips/zip001.sol";
import {Script} from "@forge-std/Script.sol";
import {Addresses, EnvVar} from "@proposals/Addresses.sol";

/*
How to use:

* Updated the zip pointer in the import statments to the zip file you want to deploy
* use the npm tasks to test and deploy the script 
* Testing `npm run deploy:incremental`


*/

contract DeployIncrementalSystem is Script, zip {
    uint256 public privateKey;

    function setUp() public {
        privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
    }

    function run() public {
        Addresses addresses = new Addresses(EnvVar.TestNet);
        addresses.resetRecordingAddresses();

        /// Run the deploy OnChain workflow
        deployOnChain(addresses, privateKey);

        (string[] memory recordedNames, address[] memory recordedAddresses) = addresses.getRecordedAddresses();
        for (uint256 i = 0; i < recordedNames.length; i++) {
            // solhint-disable-next-line
            console.log("Deployed", recordedAddresses[i], recordedNames[i]);
        }
    }
}
