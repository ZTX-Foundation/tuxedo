// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @notice Verify that a signature is valid so that a ZTX user can sign in.
contract Auth {
    /// @notice name
    string public name;

    /// @notice version
    string public version;

    /// @notice Constructor
    /// @param _name The name of the app
    /// @param _version The version of the app
    constructor(string memory _name, string memory _version) {
        name = _name;
        version = _version;
    }

    /// @notice get signer address
    /// @param sessionId The cognito session ID
    /// @param _signature The signature
    function getSigner(string memory sessionId, bytes memory _signature) public view returns (address) {
        /// @dev EIP721 domain type
        uint256 chainId = block.chainid;
        address verifyingContract = address(this);

        string memory domainType = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
        string memory messageType = "Message(string sessionId)";

        /// @dev hash to prevent signature collision
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256(abi.encodePacked(domainType)),
                keccak256(abi.encodePacked(name)),
                keccak256(abi.encodePacked(version)),
                chainId,
                verifyingContract
            )
        );

        /// @dev hash typed data
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        keccak256(abi.encodePacked(messageType)),
                        sessionId
                    )
                )
            )
        );

        /// @dev split signature
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_signature.length != 65) {
            return address(0);
        }
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return address(0);
        } else {
            // verify
            return ecrecover(hash, v, r, s);
        }
    }
}
