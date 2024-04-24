// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {MaxSupplyEnforcer} from "./MaxSupplyEnforcer.sol";

contract MaxSupplyEnforcerDeploy {
    function deployMaxSupplyEnforcer(
        address proxyAdmin
    ) public returns (address proxy, address maxSupplyEnforcerImpl) {
        maxSupplyEnforcerImpl = address(new MaxSupplyEnforcer());

        proxy = address(
            new TransparentUpgradeableProxy(maxSupplyEnforcerImpl, proxyAdmin, "")
        );
    }

    function initializeMaxSupplyEnforcer(
        address maxSupplyEnforcerProxy,
        address core
    ) public {
        MaxSupplyEnforcer(maxSupplyEnforcerProxy).initialize(
            core
        );
    }
}