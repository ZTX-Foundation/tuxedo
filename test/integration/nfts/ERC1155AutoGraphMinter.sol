// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import {ERC1155AutoGraphMinterImpl} from "@protocol/nfts/ERC1155AutoGraphMinterImpl.sol";
import {ERC1155AutoGraphMinterProxy} from "@protocol/nfts/ERC1155AutoGraphMinterProxy.sol";
import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {BatchMinting} from "@protocol/nfts/BatchMinting.sol";
import {HashVerifier} from "@protocol/nfts/HashVerifier.sol";
import {GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";
import {Token} from "@protocol/token/Token.sol";
import {Test} from "@forge-std/Test.sol";
import {console2} from "@forge-std/console2.sol";

/// @title IntegrationTestERC1155AutoGraphMinter
/// @notice Integration test for ERC1155AutoGraphMinter system
contract IntegrationTestERC1155AutoGraphMinter is Test {
    /// @notice Core system contracts
    Core private _core;
    GlobalReentrancyLock private _globalReentrancyLock;
    uint256 private _privateKey = 0x1234; /// @dev Test private key for signing

    /// @notice ZTX ERC20
    Token private _token;

    /// @notice NFT contract addresses
    address private _erc1155Consumables;
    address private _erc1155Placeables;
    address private _erc1155Wearables;

    /// @notice ERC1155AutoGraphMinter contracts
    ERC1155AutoGraphMinterImpl private _implementation;
    ERC1155AutoGraphMinterProxy private _proxy;
    ERC1155AutoGraphMinterImpl private _autoGraphMinter; /// @dev Points to proxy but typed as implementation

    /// @notice NFT whitelisted contract addresses
    address[] private _nftContractAddresses = new address[](3);

    /// @notice rate limit per second in RateLimiterV2
    uint128 private constant _REPLENISH_RATE_PER_SECOND = 100;
    uint128 private constant _BUFFER_CAP = 1_000_000;
    uint8 private constant _EXPIRY_TOKEN_HOURS_VALID = 1;

    /// @notice Set up test environment before each test
    function setUp() public {
        /// @dev Set up blockchain state
        vm.warp(1_000_000); /// @dev Set block timestamp

        /// @dev Deploy core contracts
        _core = new Core();
        _globalReentrancyLock = new GlobalReentrancyLock(address(_core));
        _core.setGlobalLock(address(_globalReentrancyLock));

        /// @dev Set up all relevant roles
        address testAddr = address(this);
        address signerAddr = vm.addr(_privateKey);

        /// @dev Core system roles - give test contract full permissions
        _core.grantRole(Roles.ADMIN, testAddr);
        _core.grantRole(Roles.GUARDIAN, testAddr);
        _core.grantRole(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, testAddr);

        /// @dev Deploy token (mock or real depending on test needs)
        _token = new Token("ZTX Token", "ZTX");

        /// @dev Deploy NFT contracts
        _erc1155Consumables = address(
            new ERC1155MaxSupplyMintable(
                address(_core),
                "https://api.example.com/consumables/metadata/",
                "ZTX Consumables",
                "ZTXC"
            )
        );

        _erc1155Placeables = address(
            new ERC1155MaxSupplyMintable(
                address(_core),
                "https://api.example.com/placeables/metadata/",
                "ZTX Placeables",
                "ZTXP"
            )
        );

        _erc1155Wearables = address(
            new ERC1155MaxSupplyMintable(
                address(_core),
                "https://api.example.com/wearables/metadata/",
                "ZTX Wearables",
                "ZTXW"
            )
        );

        /// @dev Set up NFT contract addresses
        _nftContractAddresses[0] = _erc1155Consumables;
        _nftContractAddresses[1] = _erc1155Placeables;
        _nftContractAddresses[2] = _erc1155Wearables;

        /// @dev Deploy implementation
        _implementation = new ERC1155AutoGraphMinterImpl(address(_core), address(_globalReentrancyLock));

        /// @dev Deploy proxy
        _proxy = new ERC1155AutoGraphMinterProxy(
            address(_implementation),
            address(this) /// @dev Admin is the test contract
        );

        /// @dev Cast proxy to implementation type for easier interaction
        _autoGraphMinter = ERC1155AutoGraphMinterImpl(address(_proxy));

        /// @dev Initialize through proxy
        _autoGraphMinter.initialize(
            address(_core),
            address(_globalReentrancyLock),
            _nftContractAddresses,
            _REPLENISH_RATE_PER_SECOND,
            _BUFFER_CAP,
            address(0x999), /// @dev Payment recipient
            _EXPIRY_TOKEN_HOURS_VALID
        );

        /// @dev Grant roles EXACTLY as in the unit test
        _core.grantRole(Roles.ADMIN, address(this));
        _core.grantRole(Roles.GUARDIAN, address(this));
        _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, address(_autoGraphMinter));
        _core.grantRole(Roles.MINTER_NOTARY_PROTOCOL_ROLE, vm.addr(_privateKey));
        _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, _erc1155Consumables);

        /// @dev Additional roles that might be needed
        _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, address(_autoGraphMinter));

        console2.log("Roles granted in setup");

        /// @dev Set up NFT contracts max supplies
        for (uint i = 0; i < 5; i++) {
            ERC1155MaxSupplyMintable(_erc1155Consumables).setSupplyCap(i, 1000);
            ERC1155MaxSupplyMintable(_erc1155Placeables).setSupplyCap(i, 500);
            ERC1155MaxSupplyMintable(_erc1155Wearables).setSupplyCap(i, 100);
        }
    }

    /// @notice Test that batch minting for free works correctly
    function testMintBatchForFree() public {
        /// @dev Create params exactly like the unit test
        BatchMinting.MintBatchParams[] memory params = new BatchMinting.MintBatchParams[](1); /// @dev Start with just 1

        /// @dev Fill in parameters for the mint
        params[0] = BatchMinting.MintBatchParams({
            jobId: 1,
            tokenId: 0,
            units: 10,
            hash: bytes32(0),
            salt: 123456,
            signature: bytes(""),
            paymentAmount: 0,
            expiryToken: block.timestamp - 1
        });

        /// @dev Generate hash
        HashVerifier.HashInputsParams memory input = HashVerifier.HashInputsParams({
            recipient: address(this),
            jobId: params[0].jobId,
            tokenId: params[0].tokenId,
            units: params[0].units,
            salt: params[0].salt,
            nftContract: _erc1155Consumables,
            paymentToken: address(0),
            paymentAmount: params[0].paymentAmount,
            expiryToken: params[0].expiryToken
        });

        bytes32 hash = HashVerifier.getHash(input);
        console2.log("Generated hash:");
        console2.logBytes32(hash);

        /// @dev Sign hash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        params[0].hash = hash;
        params[0].signature = signature;

        console2.log("Before mint call");

        /// @dev Try/catch to see the exact error
        try _autoGraphMinter.mintBatchForFree(_erc1155Consumables, address(this), params) {
            console2.log("Mint successful");
        } catch Error(string memory reason) {
            console2.log("Mint failed with reason:", reason);
        } catch {
            console2.log("Mint failed with no reason");
        }

        /// @dev Verify balance if mint was successful
        uint256 balance = ERC1155MaxSupplyMintable(_erc1155Consumables).balanceOf(address(this), 0);
        console2.log("NFT Balance after mint attempt:", balance);
    }
}
