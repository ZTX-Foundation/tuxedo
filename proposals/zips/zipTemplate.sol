//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Addresses} from "@proposals/Addresses.sol";
import {TimelockProposal} from "@proposals/proposalTypes/TimelockProposal.sol";

contract zipTemplate is TimelockProposal {
    constructor() Proposal("ADMIN_TIMELOCK_CONTROLLER") {}

    // Returns the name of the proposal.
    function name() public pure override returns (string memory) {
        return "ZIPTEMPLATE";
    }

    // Provides a brief description of the proposal.
    function description() public pure override returns (string memory) {
        return "Template proposal";
    }

    function _beforeDeploy() internal override {}

    function _deploy() internal override {}

    function _afterDeploy() internal override {}

    function _build() internal override {}

    function _run() internal override {}

    function _teardown() internal override {}

    function _validate() internal override {}
}
