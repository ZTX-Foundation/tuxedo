//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ZK-compatible imports
import {ZKMultisigProposal} from "@protocol/proposals/ZKMultisigProposal.sol";
import {ZKAddressRegistry} from "@protocol/addresses/ZKAddressRegistry.sol";

import {Token, MAX_SUPPLY} from "@protocol/token/Token.sol";
import {ERC20HoldingDeposit} from "@protocol/finance/ERC20HoldingDeposit.sol";

contract zip000 is ZKMultisigProposal {
    // ZK-safe hardcoded token parameters (replace with your values)
    string constant TOKEN_NAME = "ZTX";
    string constant TOKEN_SYMBOL = "ZTX";
    
    // Constructor for ZK-compatible implementation
    constructor(address multisig) ZKMultisigProposal(multisig, 0) {
        // Initialize ZK-compatible address registry with required addresses
        string[] memory names = new string[](2);
        address[] memory addrs = new address[](2);
        uint256[] memory chainIds = new uint256[](2);
        bool[] memory isContracts = new bool[](2);
        
        // Add multisig addresses - we need both ADMIN_MULTISIG and TREASURY_WALLET_MULTISIG
        names[0] = "ADMIN_MULTISIG";
        addrs[0] = multisig;
        chainIds[0] = block.chainid;
        isContracts[0] = true;
        
        names[1] = "TREASURY_WALLET_MULTISIG";
        // In production, you'd replace this with the actual treasury address
        // For demo purposes, using the same address
        addrs[1] = multisig; 
        chainIds[1] = block.chainid;
        isContracts[1] = true;
        
        ZKAddressRegistry registry = new ZKAddressRegistry(names, addrs, chainIds, isContracts);
        setAddressRegistry(registry);
    }

    // Returns the name of the proposal
    function name() public pure override returns (string memory) {
        return "ZIP000";
    }

    // Provides a brief description of the proposal
    function description() public pure override returns (string memory) {
        return "The ZTX Genesis Proposal";
    }

    function deploy() public override {
        /// Token deployment - using hardcoded values for ZK compatibility
        Token token = new Token(TOKEN_NAME, TOKEN_SYMBOL);
        
        // Add token to registry
        addressRegistry.addAddress("TOKEN", address(token), true);

        /// Token transfer to treasury
        IERC20(addressRegistry.getAddress("TOKEN")).transfer(
            addressRegistry.getAddress("TREASURY_WALLET_MULTISIG"), 
            MAX_SUPPLY
        );
    }

    function validate() public override {
        // In ZK-compatible environment, we use require statements instead of assertions
        uint256 treasuryBalance = IERC20(addressRegistry.getAddress("TOKEN")).balanceOf(
            addressRegistry.getAddress("TREASURY_WALLET_MULTISIG")
        );
        
        // Verify treasury balance
        require(
            treasuryBalance == 10_000_000_000e18,
            "Incorrect treasury balance"
        );
    }

    // Implementation of required buildMultisig function
    function buildMultisig(address multisig) internal override {
        // No actions to build in this proposal
    }
}
