pragma solidity 0.8.18;

import "@forge-std/Test.sol";

import {Auth} from "@protocol/user/Auth.sol";

contract UnitTestAuth is Test {
    Auth auth;

    string sessionId = "F16PsUweetVFb6MBkT3ytenN2NkReev9";

    uint256 private privateKey;
    address private user;

    function setUp() public {
        auth = new Auth("ZTX", "1");

        privateKey = vm.deriveKey("test test test test test test test test test test test junk", "m/44'/60'/0'/2/", 0);
        user = vm.addr(privateKey);
    }

    function testGetName() public {
        string memory name = auth.name();
        assertEq(name, "ZTX");
    }

    function testGetVersion() public {
        string memory version = auth.version();
        assertEq(version, "1");
    }

    function _domainSeparator() public returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256(abi.encodePacked("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")),
                keccak256(abi.encodePacked(auth.name())),
                keccak256(abi.encodePacked(auth.version())),
                block.chainid,
                address(auth)
            )
        );
    }

    function _messageType() public returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator(),
                keccak256(
                    abi.encode(
                        keccak256(abi.encodePacked("Message(string sessionId)")),
                        sessionId
                    )
                )
            )
        );
    }

    function testGetSigner() public {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, _messageType());
        bytes memory signature = abi.encodePacked(r, s, v);

        address signer = auth.getSigner(sessionId, signature);
        assertEq(signer, user);
    }

    function testGetSignerFail() public {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, _messageType());
        bytes memory signature = abi.encodePacked(r, s, v);

        address signer = auth.getSigner("iZIMeoCOdVD1c03CT2sbQO7n8kLPOQkG", signature);
        assertTrue(signer != user);
    }
}
