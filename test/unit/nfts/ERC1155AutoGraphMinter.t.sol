// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import "@forge-std/Test.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {MockERC20} from "test/mock/MockERC20.sol";
import {Constants} from "@protocol/Constants.sol";
import {ERC20Splitter} from "@protocol/finance/ERC20Splitter.sol";
import {MockERC20, IERC20} from "test/mock/MockERC20.sol";
import {GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {ERC1155AutoGraphMinterImpl} from "@protocol/nfts/ERC1155AutoGraphMinterImpl.sol";
import {ERC1155AutoGraphMinterProxy} from "@protocol/nfts/ERC1155AutoGraphMinterProxy.sol";
import {TestAddresses as addresses} from "test/fixtures/TestAddresses.sol";
import {BatchMinting} from "@protocol/nfts/BatchMinting.sol";
import {BaseTest} from "test/BaseTest.sol";

/// @title ERC1155AutoGraphMinterTest
/// @notice Unit tests for ERC1155AutoGraphMinter
contract ERC1155AutoGraphMinterTest is BaseTest {
    /// @notice Test constants
    uint128 private constant _REPLENISH_RATE_PER_SECOND = 100;
    uint128 private constant _BUFFER_CAP = 10_000;
    uint8 private constant _EXPIRY_TOKEN_HOURS_VALID = 1;

    /// @notice Core contracts
    Core private _core;
    GlobalReentrancyLock private _globalLock;

    /// @notice Test contracts
    MockERC20 private _token;
    ERC1155MaxSupplyMintable private _erc1155;

    /// @notice Main contract being tested (through proxy)
    ERC1155AutoGraphMinterImpl private _implementation;
    ERC1155AutoGraphMinterProxy private _proxy;
    ERC1155AutoGraphMinterImpl private _autoGraphMinter; /// @dev Points to proxy address but typed as implementation

    /// @notice Test data
    address private _paymentRecipient = address(0x999);
    uint256 private _privateKey = 0x1234; /// @dev Test private key for signing

    /// @notice Set up test environment before each test
    function setUp() public override {
        vm.warp(1_000_000); /// @dev Set block timestamp

        /// @dev Deploy core contracts
        _core = new Core();
        _globalLock = new GlobalReentrancyLock(address(_core));
        _core.setGlobalLock(address(_globalLock));

        /// @dev Deploy test contracts
        _token = new MockERC20();
        _erc1155 = new ERC1155MaxSupplyMintable(
            address(_core),
            "https://api.example.com/metadata/",
            "Test NFT",
            "TNFT"
        );

        /// @dev Deploy implementation
        _implementation = new ERC1155AutoGraphMinterImpl(address(_core), address(_globalLock));

        /// @dev Deploy proxy
        _proxy = new ERC1155AutoGraphMinterProxy(
            address(_implementation),
            address(this) /// @dev Admin is the test contract
        );

        /// @dev Cast proxy to implementation type for easier interaction
        _autoGraphMinter = ERC1155AutoGraphMinterImpl(address(_proxy));

        /// @dev Initialize system
        address[] memory nftContracts = new address[](1);
        nftContracts[0] = address(_erc1155);

        _autoGraphMinter.initialize(
            address(_core),
            address(_globalLock),
            nftContracts,
            _REPLENISH_RATE_PER_SECOND,
            _BUFFER_CAP,
            _paymentRecipient,
            _EXPIRY_TOKEN_HOURS_VALID
        );

        /// @dev Set up roles
        _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, address(_autoGraphMinter));
        _core.grantRole(Roles.MINTER_NOTARY_PROTOCOL_ROLE, vm.addr(_privateKey));
        _core.grantRole(Roles.GUARDIAN, address(this));
        _core.grantRole(Roles.ADMIN, address(this));

        /// @dev Set up NFT contract
        _erc1155.setSupplyCap(1, 100);

        /// @dev Fund test contract with tokens
        _token.mint(address(this), 1000 ether);
        _token.approve(address(_autoGraphMinter), type(uint256).max);
    }

    /// @notice Test that batch minting for free works correctly
    function testMintBatchForFree() public {
        /// @dev Create batch params
        uint256 jobId = 1;
        uint256 tokenId = 1;
        uint256 units = 5;

        /// @dev Create params directly
        BatchMinting.MintBatchParams[] memory params = new BatchMinting.MintBatchParams[](1);

        /// @dev Fill in parameters for the mint
        params[0] = BatchMinting.MintBatchParams({
            jobId: jobId,
            tokenId: tokenId,
            units: units,
            hash: bytes32(0), /// @dev Will be filled
            salt: 123456,
            signature: bytes(""), /// @dev Will be filled
            paymentAmount: 0,
            expiryToken: block.timestamp - 1
        });

        /// @dev Generate hash
        bytes32 hash = keccak256(
            abi.encode(
                address(this), /// @dev recipient
                params[0].jobId,
                params[0].tokenId,
                params[0].units,
                params[0].salt,
                address(_erc1155), /// @dev nftContract
                address(0), /// @dev paymentToken
                params[0].paymentAmount,
                params[0].expiryToken
            )
        );

        /// @dev Sign the hash with our private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        /// @dev Update the params with hash and signature
        params[0].hash = hash;
        params[0].signature = signature;

        /// @dev Mint through the proxy
        _autoGraphMinter.mintBatchForFree(address(_erc1155), address(this), params);

        /// @dev Verify balance
        assertEq(_erc1155.balanceOf(address(this), tokenId), units);
    }
}
