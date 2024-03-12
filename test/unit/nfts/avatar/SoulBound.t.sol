// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@forge-std/Test.sol";

import {BaseTest} from "@test/BaseTest.sol";
import {SoulBound} from "@protocol/nfts/avatar/SoulBound.sol";


contract SoulBoundTest is BaseTest {
    SoulBound soulBound;

    uint256 private minterPK;
    uint256 private userPK;

    address private minter;
    address private user;

    function setUp() public override {
        super.setUp();

        string memory mnemonic = "test test test test test test test test test test test junk";
        minterPK = vm.deriveKey(mnemonic, "m/44'/60'/0'/1/", 0);
        minter = vm.addr(minterPK);

        userPK = vm.deriveKey(mnemonic, "m/44'/60'/0'/2/", 0);
        user = vm.addr(userPK);

        soulBound = new SoulBound("SoulBoundToken", "SBT", 1, minter);
    }

    function _createHashParams(
        uint256 tokenId,
        uint256 salt,
        uint256 expiryToken
    ) private pure returns (SoulBound.HashInputsParams memory) {
        SoulBound.HashInputsParams memory params = SoulBound.HashInputsParams(
            address(1),
            tokenId,
            salt,
            expiryToken
        );

        return params;
    }

    function _getHash(SoulBound.HashInputsParams memory params) private view returns (bytes32) {
        return soulBound.getHash(params);
    }

    function _generateHash(SoulBound.HashInputsParams memory params) private pure returns (bytes32) {
        return
        keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(params.recipient, params.tokenId, params.salt, params.expiryToken))
            )
        );
    }

    function _signature(bytes32 hash, uint256 privateKey) private pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        return signature;
    }

    function _claim(
        SoulBound.HashInputsParams memory params,
        bytes32 hash,
        bytes memory signature,
        string memory _tokenURI
    ) private {
        soulBound.claim(
            params.recipient,
            params.tokenId,
            hash,
            params.salt,
            signature,
            params.expiryToken,
            _tokenURI
        );
    }

    function testGetHash() public {
        SoulBound.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);
        assertEq(hash.length, 32);
    }

    function testRecoverSigner() public {
        SoulBound.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        address recover = soulBound.recoverSigner(hash, signature);
        assertEq(recover, minter);
    }

    function testCompareHash() public {
        SoulBound.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);

        bytes32 onchain = _getHash(params);
        assertEq(onchain.length, 32);

        bytes32 offchain = _generateHash(params);
        assertEq(offchain.length, 32);

        assertEq(onchain, offchain);
    }

    function testClaim() public {
        SoulBound.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        /// @dev skip ahead 30 minutes
        vm.warp(block.timestamp + 1800);
        vm.prank(minter);
        _claim(params, hash, signature, "https://example.com");
        assertEq(soulBound.balanceOf(params.recipient), 1);
    }

    function testClaimTokenExpired() public {
        SoulBound.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        /// @dev skip ahead 2 hours
        vm.warp(block.timestamp + 7200);
        vm.prank(minter);
        vm.expectRevert("Expiry token has expired");
        _claim(params, hash, signature, "https://example.com");
    }

    function testClaimHashMismatch() public {
        SoulBound.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        /// @dev adjust the hash
        SoulBound.HashInputsParams memory mismatch = _createHashParams(1, 124, block.timestamp);
        bytes32 hashMismatch = _getHash(mismatch);

        /// @dev skip ahead 30 minutes
        vm.warp(block.timestamp + 1800);
        vm.prank(address(1));
        vm.expectRevert("Hash mismatch");
        _claim(params, hashMismatch, signature, "https://example.com");
    }

    function testClaimHashUsed() public {
        SoulBound.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        /// @dev skip ahead 30 minutes
        vm.warp(block.timestamp + 1800);
        vm.startPrank(minter);
        _claim(params, hash, signature, "https://example.com");

        /// @dev attempt to mint again
        vm.expectRevert("Hash has already been used");
        _claim(params, hash, signature, "https://example.com");
        vm.stopPrank();
    }

    function testClaimInvalidSigner() public {
        SoulBound.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, userPK);
        assertEq(signature.length, 65);

        /// @dev skip ahead 30 minutes
        vm.warp(block.timestamp + 1800);
        vm.prank(user);
        vm.expectRevert("Invalid signer");
        _claim(params, hash, signature, "https://example.com");
    }

    function testSafeTransferFrom() public {
        SoulBound.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        /// @dev skip ahead 30 minutes
        vm.warp(block.timestamp + 1800);
        vm.prank(minter);
        _claim(params, hash, signature, "https://example.com");
        assertEq(soulBound.balanceOf(params.recipient), 1);

        vm.startPrank(params.recipient);
        soulBound.approve(address(2), params.tokenId);
        vm.expectRevert("Computer says no; token not transferable");
        soulBound.safeTransferFrom(params.recipient, address(2), params.tokenId);
        vm.stopPrank();
    }

    function testIsClaimable() public {
        assertEq(soulBound.isClaimable(), true);
    }

    function testSetClaimableFalse() public {
        assertEq(soulBound.isClaimable(), true);

        soulBound.setClaimable(false);
        assertEq(soulBound.isClaimable(), false);
    }

    function testSetClaimableFalseNonOwner() public {
        assertEq(soulBound.isClaimable(), true);

        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        soulBound.setClaimable(false);
    }

    function testClaimNotClaimable() public {
        SoulBound.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        soulBound.setClaimable(false);

        /// @dev skip ahead 30 minutes
        vm.warp(block.timestamp + 1800);
        vm.prank(minter);
        vm.expectRevert("Claiming is currently disabled.");
        _claim(params, hash, signature, "https://example.com");
    }

    function testClaimAndBurn() public {
        SoulBound.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        /// @dev skip ahead 30 minutes
        vm.warp(block.timestamp + 1800);
        vm.prank(minter);
        _claim(params, hash, signature, "https://example.com");

        /// @dev burn
        vm.startPrank(params.recipient);
        soulBound.burn(params.tokenId);
        assertEq(soulBound.balanceOf(params.recipient), 0);
    }

    function testClaimMultipleTokensFail() public {
        SoulBound.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        /// @dev skip ahead 30 minutes
        vm.warp(block.timestamp + 1800);
        vm.prank(minter);
        _claim(params, hash, signature, "https://example.com");

        /// @dev attempt another claim
        vm.warp(block.timestamp + 1 hours);
        SoulBound.HashInputsParams memory attemptTwoParams = _createHashParams(2, 456, block.timestamp);
        bytes32 attemptTwoHash = _getHash(attemptTwoParams);

        bytes memory attemptTwoSignature = _signature(attemptTwoHash, minterPK);
        assertEq(attemptTwoSignature.length, 65);

        vm.warp(block.timestamp + 1800);
        vm.prank(minter);
        vm.expectRevert("Only one NFT per address can be claimed");
        _claim(attemptTwoParams, attemptTwoHash, attemptTwoSignature, "https://example.com");
    }

    function testTokenURI() public {
        SoulBound.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        /// @dev skip ahead 30 minutes
        vm.warp(block.timestamp + 1800);
        vm.prank(minter);
        _claim(params, hash, signature, "https://example.com");
        assertEq(soulBound.balanceOf(params.recipient), 1);

        string memory _tokenURI = soulBound.tokenURI(params.tokenId);
        assertEq(_tokenURI, "https://example.com");
    }
}
