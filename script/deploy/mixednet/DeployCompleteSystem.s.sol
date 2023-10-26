// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {DeployCompleteSystem} from "@script/deploy/common/DeployCompleteSystem.s.sol";
import {EnvVar} from "@proposals/Addresses.sol";

contract MixedNetDeployCompleteSystem is DeployCompleteSystem {
    function run() public {
        super.run(EnvVar.MixedNet);
    }
}
