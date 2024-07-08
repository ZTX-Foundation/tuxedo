pragma solidity 0.8.18;

import "forge-std/Test.sol";
import {Auth} from "@protocol/user/Auth.sol";

contract UnitTestAuth is Test {
    Auth auth;

    string sessionId = "F16PsUweetVFb6MBkT3ytenN2NkReev9";

    uint256 private privateKey;
    address private user;

    function setUp() public {
        auth = new Auth();

        privateKey = vm.deriveKey("test test test test test test test test test test test junk", "m/44'/60'/0'/2", 0);
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

    function _domainSeparator() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(auth.name())),
                keccak256(bytes(auth.version())),
                block.chainid,
                address(auth)
            )
        );
    }

    function _structHash() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("LoginMessage(string session)"),
                keccak256(bytes(sessionId))
            )
        );
    }

    function _messageType() public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator(),
                _structHash()
            )
        );
    }

    function testGetSigner() public {
        bytes32 messageHash = _messageType();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        Auth.LoginMessage memory loginMessage = Auth.LoginMessage({session: sessionId});
        address signer = auth.getSigner(loginMessage, signature);
        assertEq(signer, user);
    }

    function testGetSignerFail() public {
        bytes32 messageHash = _messageType();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        Auth.LoginMessage memory loginMessage = Auth.LoginMessage({session: "iZIMeoCOdVD1c03CT2sbQO7n8kLPOQkG"});
        address signer = auth.getSigner(loginMessage, signature);
        assertTrue(signer != user);
    }
}
