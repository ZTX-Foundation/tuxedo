pragma solidity 0.8.18;

import {Addresses} from "@proposals/Addresses.sol";

interface IProposal {
    // Proposal name, e.g. "ZIP16"
    function name() external view returns (string memory);

    // Proposal description, e.g. "Add a new capsule"
    function description() external view returns (string memory);
}
