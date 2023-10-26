pragma solidity 0.8.18;

import {DeployCompleteSystem} from "@script/deploy/common/DeployCompleteSystem.s.sol";
import {EnvVar} from "@proposals/Addresses.sol";

contract MainNetDeployCompleteSystem is DeployCompleteSystem {
    function run() public {
        super.run(EnvVar.MainNet);
    }
}
