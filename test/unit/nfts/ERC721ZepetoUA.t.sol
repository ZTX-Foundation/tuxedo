pragma solidity 0.8.18;

import "@forge-std/Test.sol";

import {BaseTest} from "@test/BaseTest.sol";

import {ERC721ZepetoUA} from "@protocol/nfts/ERC721ZepetoUA.sol";

contract UnitTestERC721ZepetoUA is BaseTest {
    ERC721ZepetoUA erc721ZepetoUA;

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

        erc721ZepetoUA = new ERC721ZepetoUA("ERC721ZepetoUA", "ZUA", 1, minter);
    }

    function _createHashParams(
        uint256 tokenId,
        uint256 salt,
        uint256 expiryToken
    ) private pure returns (ERC721ZepetoUA.HashInputsParams memory) {
        ERC721ZepetoUA.HashInputsParams memory params = ERC721ZepetoUA.HashInputsParams(
            address(1),
            tokenId,
            salt,
            expiryToken
        );

        return params;
    }

    function _getHash(ERC721ZepetoUA.HashInputsParams memory params) private view returns (bytes32) {
        return erc721ZepetoUA.getHash(params);
    }

    function _generateHash(ERC721ZepetoUA.HashInputsParams memory params) private pure returns (bytes32) {
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
        ERC721ZepetoUA.HashInputsParams memory params,
        bytes32 hash,
        bytes memory signature,
        string memory _tokenURI
    ) private {
        erc721ZepetoUA.claim(
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
        ERC721ZepetoUA.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);
        assertEq(hash.length, 32);
    }

    function testRecoverSigner() public {
        ERC721ZepetoUA.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        address recover = erc721ZepetoUA.recoverSigner(hash, signature);
        assertEq(recover, minter);
    }

    function testCompareHash() public {
        ERC721ZepetoUA.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);

        bytes32 onchain = _getHash(params);
        assertEq(onchain.length, 32);

        bytes32 offchain = _generateHash(params);
        assertEq(offchain.length, 32);

        assertEq(onchain, offchain);
    }

    function testClaim() public {
        ERC721ZepetoUA.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        /// @dev skip ahead 30 minutes
        vm.warp(block.timestamp + 1800);
        vm.prank(minter);
        _claim(params, hash, signature, "https://example.com");
        assertEq(erc721ZepetoUA.balanceOf(params.recipient), 1);
    }

    function testClaimTokenExpired() public {
        ERC721ZepetoUA.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
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
        ERC721ZepetoUA.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        /// @dev adjust the hash
        ERC721ZepetoUA.HashInputsParams memory mismatch = _createHashParams(1, 124, block.timestamp);
        bytes32 hashMismatch = _getHash(mismatch);

        /// @dev skip ahead 30 minutes
        vm.warp(block.timestamp + 1800);
        vm.prank(address(1));
        vm.expectRevert("Hash mismatch");
        _claim(params, hashMismatch, signature, "https://example.com");
    }

    function testClaimHashUsed() public {
        ERC721ZepetoUA.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
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
        ERC721ZepetoUA.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
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
        ERC721ZepetoUA.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        /// @dev skip ahead 30 minutes
        vm.warp(block.timestamp + 1800);
        vm.prank(minter);
        _claim(params, hash, signature, "https://example.com");
        assertEq(erc721ZepetoUA.balanceOf(params.recipient), 1);

        vm.startPrank(params.recipient);
        erc721ZepetoUA.approve(address(2), params.tokenId);
        vm.expectRevert("Computer says no; token not transferable");
        erc721ZepetoUA.safeTransferFrom(params.recipient, address(2), params.tokenId);
        vm.stopPrank();
    }

    function testIsClaimable() public {
        assertEq(erc721ZepetoUA.isClaimable(), true);
    }

    function testSetClaimableFalse() public {
        assertEq(erc721ZepetoUA.isClaimable(), true);

        erc721ZepetoUA.setClaimable(false);
        assertEq(erc721ZepetoUA.isClaimable(), false);
    }

    function testSetClaimableFalseNonOwner() public {
        assertEq(erc721ZepetoUA.isClaimable(), true);

        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        erc721ZepetoUA.setClaimable(false);
    }

    function testClaimNotClaimable() public {
        ERC721ZepetoUA.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        erc721ZepetoUA.setClaimable(false);

        /// @dev skip ahead 30 minutes
        vm.warp(block.timestamp + 1800);
        vm.prank(minter);
        vm.expectRevert("Claiming is currently disabled.");
        _claim(params, hash, signature, "https://example.com");
    }

    function testClaimAndBurn() public {
        ERC721ZepetoUA.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        /// @dev skip ahead 30 minutes
        vm.warp(block.timestamp + 1800);
        vm.prank(minter);
        _claim(params, hash, signature, "https://example.com");

        /// @dev burn
        vm.startPrank(params.recipient);
        erc721ZepetoUA.burn(params.tokenId);
        assertEq(erc721ZepetoUA.balanceOf(params.recipient), 0);
    }

    function testClaimMultipleTokensFail() public {
        ERC721ZepetoUA.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        /// @dev skip ahead 30 minutes
        vm.warp(block.timestamp + 1800);
        vm.prank(minter);
        _claim(params, hash, signature, "https://example.com");

        /// @dev attempt another claim
        vm.warp(block.timestamp + 1 hours);
        ERC721ZepetoUA.HashInputsParams memory attemptTwoParams = _createHashParams(2, 456, block.timestamp);
        bytes32 attemptTwoHash = _getHash(attemptTwoParams);

        bytes memory attemptTwoSignature = _signature(attemptTwoHash, minterPK);
        assertEq(attemptTwoSignature.length, 65);

        vm.warp(block.timestamp + 1800);
        vm.prank(minter);
        vm.expectRevert("Only one NFT per address can be claimed");
        _claim(attemptTwoParams, attemptTwoHash, attemptTwoSignature, "https://example.com");
    }

    function testTokenURI() public {
        ERC721ZepetoUA.HashInputsParams memory params = _createHashParams(1, 123, block.timestamp);
        bytes32 hash = _getHash(params);

        bytes memory signature = _signature(hash, minterPK);
        assertEq(signature.length, 65);

        /// @dev skip ahead 30 minutes
        vm.warp(block.timestamp + 1800);
        vm.prank(minter);
        _claim(params, hash, signature, "https://example.com");
        assertEq(erc721ZepetoUA.balanceOf(params.recipient), 1);

        string memory _tokenURI = erc721ZepetoUA.tokenURI(params.tokenId);
        assertEq(_tokenURI, "https://example.com");
    }
}
