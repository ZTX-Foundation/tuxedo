// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ERC1155AutoGraphMinterProxy} from "./ERC1155AutoGraphMinterProxy.sol";
import {ERC1155AutoGraphMinterImpl} from "./ERC1155AutoGraphMinterImpl.sol";
import {ERC1155AutoGraphMinterLogic} from "./ERC1155AutoGraphMinterLogic.sol";

/**
 * @title ERC1155AutoGraphMinter
 * @notice Compatibility layer for the old contract 
 * @dev Use ERC1155AutoGraphMinterProxy and ERC1155AutoGraphMinterImpl instead
 */
contract ERC1155AutoGraphMinter {
    // This contract is deprecated
    constructor(
        address _core,
        address[] memory _nftContracts,
        uint128 _replenishRatePerSecond,
        uint128 _bufferCap,
        address _paymentRecipient,
        uint8 _expiryTokenHoursValid
    ) {
        revert("ERC1155AutoGraphMinter is deprecated. Use ERC1155AutoGraphMinterProxy instead.");
    }
} 