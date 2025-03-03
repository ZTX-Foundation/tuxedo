// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/**
 * @title ERC1155AutoGraphMinterLib
 * @notice This file is deprecated and kept as a compatibility layer
 * @dev Use ERC1155AutoGraphMinterLogic instead
 */

import {ERC1155AutoGraphMinterLogic} from "./ERC1155AutoGraphMinterLogic.sol";

library ERC1155AutoGraphMinterLib {
    // Structs are aliased to the new library's structs
    struct MintBatchParams { uint256 _dummy; }
    struct HashInputsParams { uint256 _dummy; }
    struct VerifyInputParams { uint256 _dummy; }
    struct MintWithPaymentTokenAsFeeParams { uint256 _dummy; }
    struct MintWithEthAsFeeParams { uint256 _dummy; }
    
    // This library is no longer in use - all functions redirect to the new library
    function getHash(ERC1155AutoGraphMinterLogic.HashInputsParams memory input) internal pure returns (bytes32) {
        return ERC1155AutoGraphMinterLogic.getHash(input);
    }
    
    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        return ERC1155AutoGraphMinterLogic.recoverSigner(hash, signature);
    }
    
    function isExpiryTokenValid(uint256 expiryToken, uint8 expiryHours) internal view returns (bool) {
        return ERC1155AutoGraphMinterLogic.isExpiryTokenValid(expiryToken, expiryHours);
    }
    
    function validatePaymentTokenFee(address paymentToken, uint256 paymentAmount) internal pure {
        ERC1155AutoGraphMinterLogic.validatePaymentTokenFee(paymentToken, paymentAmount);
    }
    
    function validateEthFee(uint256 paymentAmount) internal view {
        ERC1155AutoGraphMinterLogic.validateEthFee(paymentAmount);
    }
} 