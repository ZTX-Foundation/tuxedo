//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {TimelockProposal} from "proposals/proposalTypes/TimelockProposal.sol";

contract zipTemplate is TimelockProposal {

    // Returns the name of the proposal.
    function name() public pure override returns (string memory) {
        return "ZIPTEMPLATE";
    }

    // Provides a brief description of the proposal.
    function description() public pure override returns (string memory) {
        return "Template proposal";
    }

    function deploy() public override {}

    function build()
        public
        override
        buildModifier(addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER")) 
    {}

    function run() public override {
        setTimelock(addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"));

        super.run();
    }

    function simulate() public override {
        address multisig = addresses.getAddress("ADMIN_MULTISIG");

        /// Multisig is proposer and executor
        _simulateActions(multisig, multisig);
    }

    function teardown() public override {}

    function validate() public override {}
}
