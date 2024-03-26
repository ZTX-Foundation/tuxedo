// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import {Roles} from "@protocol/core/Roles.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {IAccount} from "@protocol/nfts/avatar/account/IAccount.sol";
import {IExecutable} from "@protocol/nfts/avatar/executable/IExecutable.sol";

/// @title Account contract
contract Account is CoreRef, IERC165, IERC1271, IAccount, IExecutable {
    uint256 public state;

    receive() external payable {}

    constructor(address _core) CoreRef(_core) {}

    /// @notice execute a low-level operation
    /// @param to The target address of the operation
    /// @param value The ETH value to be sent to the target
    /// @param data The encoded operation calldata
    /// @param operation A value indicating the type of operation to perform
    /// @return result The result of the operation
    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 operation
    ) external payable returns (bytes memory result) {
        require(_isValidSigner(msg.sender), "Invalid signer");
        require(operation == 0, "Only call operations are supported");

        ++state;

        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /// @notice check if signer is valid
    /// @param signer The address to check signing authorization for
    /// @return magicValue Magic value indicating whether the signer is valid
    function isValidSigner(address signer, bytes calldata) external view returns (bytes4) {
        if (_isValidSigner(signer)) {
            return IAccount.isValidSigner.selector;
        }

        return bytes4(0);
    }

    /// @notice check if the signature is valid
    /// @param hash The hash of the data to be signed
    /// @param signature The signature to be checked
    /// @return magicValue Magic value indicating whether the signature is valid
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue)
    {
        bool isValid = SignatureChecker.isValidSignatureNow(owner(), hash, signature);

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return (interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IAccount).interfaceId ||
            interfaceId == type(IExecutable).interfaceId);
    }

    /// @notice get the token information
    function token()
        public
        view
        returns (
            uint256,
            address,
            uint256
        )
    {
        bytes memory footer = new bytes(0x60);

        assembly {
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
        }

        return abi.decode(footer, (uint256, address, uint256));
    }

    /// @notice get the account state
    /// @return state The account state
    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    /// @notice check if the signer is valid
    /// @param signer The address to check signing authorization for
    /// @return true if the signer is valid
    function _isValidSigner(address signer) internal view returns (bool) {
        return signer == owner();
    }
}
