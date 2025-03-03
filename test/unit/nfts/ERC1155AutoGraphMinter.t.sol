// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "@forge-std/Test.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {MockERC20} from "test/mock/MockERC20.sol";
import {Constants} from "@protocol/Constants.sol";
import {ERC20Splitter} from "@protocol/finance/ERC20Splitter.sol";
import {MockERC20, IERC20} from "test/mock/MockERC20.sol";
import {GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {ERC1155AutoGraphMinterProxy} from "@protocol/nfts/ERC1155AutoGraphMinterProxy.sol";
import {ERC1155AutoGraphMinterImpl} from "@protocol/nfts/ERC1155AutoGraphMinterImpl.sol";
import {ERC1155AutoGraphMinterLogic} from "@protocol/nfts/ERC1155AutoGraphMinterLogic.sol";
import {TestAddresses as addresses} from "test/fixtures/TestAddresses.sol";
import {ERC1155AutoGraphMinterHelperLib as Helper} from "test/helpers/ERC1155AutoGraphMinterHelper.sol";
import {BaseTest} from "test/BaseTest.sol";

contract UnitTestERC1155AutoGraphMinter is BaseTest {
    ERC1155AutoGraphMinterProxy private _autoGraphMinterProxy;
    ERC1155AutoGraphMinterImpl private _autoGraphMinterImpl;

    uint256 private _privateKey;
    address private _notary;

    /// ------ Whitelist setting ---------- ///

    address[] public defaultWhitelistedAddresses = [address(0x987), address(0x654), address(0x321)];
    address[] public addressesToAdd = [address(0x123), address(0x456), address(0x789)];

    /// ------ Rate limiting setting ------ ///

    /// @notice rate limit per second in RateLimitedV2
    uint128 private constant _REPLENISH_RATE_PER_SECOND = 100;

    /// @notice buffer cap in RateLimited
    uint128 private constant _BUFFER_CAP = 1_000;

    address private _defaultPaymentRecipient = address(0x123);

    function setUp() public override {
        super.setUp();

        string memory mnemonic = "test test test test test test test test test test test junk";
        _privateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/1/", 0);
        _notary = vm.addr(_privateKey);

        // Deploy implementation
        _autoGraphMinterImpl = new ERC1155AutoGraphMinterImpl(address(core));
        
        // Deploy proxy pointing to the implementation
        _autoGraphMinterProxy = new ERC1155AutoGraphMinterProxy(
            address(_autoGraphMinterImpl),
            address(this) // This test contract is the admin
        );
        
        // Initialize through the proxy
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).initialize(
            address(core),
            defaultWhitelistedAddresses,
            _REPLENISH_RATE_PER_SECOND,
            _BUFFER_CAP,
            _defaultPaymentRecipient,
            1
        );

        vm.startPrank(addresses.adminAddress);
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).addWhitelistedContract(address(nft));
        nft.setSupplyCap(0, supplyCap);
        core.grantRole(Roles.MINTER_PROTOCOL_ROLE, address(_autoGraphMinterProxy));
        core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, address(_autoGraphMinterProxy));
        core.grantRole(Roles.MINTER_NOTARY_PROTOCOL_ROLE, _notary);
        vm.stopPrank();
    }

    /// --------------------- Testing Hash functions --------------------- ///

    function testHashEncoding() public {
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft));

        // setup hash manually
        bytes32 hashFirstPass = keccak256(
            abi.encode(
                parts.recipient,
                parts.jobId,
                parts.tokenId,
                parts.units,
                parts.salt,
                address(nft),
                address(0),
                0,
                block.timestamp
            )
        );
        bytes32 expectedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashFirstPass));

        assertEq(parts.hash, expectedHash);
    }

    function testRecoverSigner() public {
        // hash'ed messages parameters
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft));

        // recover signer
        address signer = ERC1155AutoGraphMinterLogic.recoverSigner(parts.hash, parts.signature);

        // assert signer is the same as the signer of the hash
        assertEq(signer, vm.addr(_privateKey));
    }

    /// --------------------- Testing Mint for free functions --------------------- ///

    function testMintForFreeWithExpiredHash() public {
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft));

        // mint
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(nft),
            block.timestamp
        );

        // assert balance
        assertEq(nft.balanceOf(parts.recipient, parts.tokenId), parts.units);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(nft),
            block.timestamp
        );
    }

    function testMintForFreeWithExpiredJob() public {
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft));

        // mint
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(nft),
            parts.expiryToken
        );

        // assert balance
        assertEq(nft.balanceOf(parts.recipient, parts.tokenId), parts.units);

        // expired job with valid hash
        parts = Helper.setupTx(
            Helper.SetupTxParams(vm, _privateKey, address(nft), 99, 1, 1, address(0), 0, block.timestamp)
        );
        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(nft),
            parts.expiryToken
        );
    }

    function testMintForFreeMissingSigningRole() public {
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft));

        vm.prank(addresses.adminAddress);
        core.revokeRole(Roles.MINTER_NOTARY_PROTOCOL_ROLE, _notary);

        vm.expectRevert("ERC1155AutoGraphMinter: Missing MINTER_NOTARY Role");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(nft),
            block.timestamp
        );
    }

    function testMintForFreeInvalidTokenIdHashMismatch() public {
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft));

        uint256 _tokenId = 999;

        vm.expectRevert("ERC1155AutoGraphMinter: Hash mismatch");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintForFree(
            parts.recipient,
            parts.jobId,
            _tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(nft),
            block.timestamp
        );
    }

    function testMintForFreeInvalidUnitstHashMismatch() public {
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft));

        uint256 units = 999;

        vm.expectRevert("ERC1155AutoGraphMinter: Hash mismatch");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(nft),
            block.timestamp
        );
    }

    function testMintForFreeInvalidNftContractAddress() public {
        uint256 paymentAmount = 111;
        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            address(nft),
            address(token),
            paymentAmount,
            block.timestamp
        );

        vm.expectRevert("WhitelistedAddress: Provided address is not whitelisted");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(0x123),
            block.timestamp
        );
    }

    function testMintForFreeInvalidSalt() public {
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft));

        vm.expectRevert("ERC1155AutoGraphMinter: Hash mismatch");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            block.timestamp + 1,
            parts.signature,
            address(nft),
            block.timestamp
        );
    }

    function testMintForFreeInvalidRecipient() public {
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft));

        vm.expectRevert("ERC1155AutoGraphMinter: Hash mismatch");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintForFree(
            address(0x123),
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(nft),
            block.timestamp
        );
    }

    /// --------------------- Testing Mint With paymentToken Fee functions --------------------- ///

    function testMintWithPaymentTokenSuccessAndExpiredHash() public {
        uint256 paymentAmount = 111;
        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            address(nft),
            address(token),
            paymentAmount,
            block.timestamp
        );

        token.mint(address(this), paymentAmount);
        token.approve(address(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy))), paymentAmount);

        ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams memory inputs = ERC1155AutoGraphMinterLogic
            .MintWithPaymentTokenAsFeeParams(
                parts.recipient,
                parts.jobId,
                parts.tokenId,
                parts.units,
                parts.hash,
                parts.salt,
                parts.signature,
                address(nft),
                address(token),
                parts.paymentAmount,
                block.timestamp
            );

        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintWithPaymentTokenAsFee(inputs);

        assertEq(nft.balanceOf(parts.recipient, parts.tokenId), parts.units);
        assertEq(token.balanceOf(address(_defaultPaymentRecipient)), paymentAmount);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintWithPaymentTokenAsFee(inputs);
    }

    function testMintWithPaymentTokenInvalidPaymentToken() public {
        uint256 paymentAmount = 111;
        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            address(nft),
            address(token),
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams memory inputs = ERC1155AutoGraphMinterLogic
            .MintWithPaymentTokenAsFeeParams(
                parts.recipient,
                parts.jobId,
                parts.tokenId,
                parts.units,
                parts.hash,
                parts.salt,
                parts.signature,
                address(nft),
                address(0),
                parts.paymentAmount,
                block.timestamp
            );

        vm.expectRevert("ERC1155AutoGraphMinter: paymentToken must not be address(0)");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintWithPaymentTokenAsFee(inputs);
    }

    function testMintWithPaymentTokenInvalidPaymentAmount() public {
        uint256 paymentAmount = 111;
        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            address(nft),
            address(token),
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams memory inputs = ERC1155AutoGraphMinterLogic
            .MintWithPaymentTokenAsFeeParams(
                parts.recipient,
                parts.jobId,
                parts.tokenId,
                parts.units,
                parts.hash,
                parts.salt,
                parts.signature,
                address(nft),
                address(token),
                0,
                block.timestamp
            );

        vm.expectRevert("ERC1155AutoGraphMinter: paymentAmount must be greater than 0");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintWithPaymentTokenAsFee(inputs);
    }

    function testMintWithWithPaymentTokenIncorrectFeeAmount() public {
        uint256 paymentAmount = 111;
        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            address(nft),
            address(token),
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams memory inputs = ERC1155AutoGraphMinterLogic
            .MintWithPaymentTokenAsFeeParams(
                parts.recipient,
                parts.jobId,
                parts.tokenId,
                parts.units,
                parts.hash,
                parts.salt,
                parts.signature,
                address(nft),
                address(token),
                1000,
                block.timestamp
            );

        // mint
        vm.expectRevert("ERC1155AutoGraphMinter: Hash mismatch");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintWithPaymentTokenAsFee(inputs);
    }

    /// --------------------- Testing Mint for ETH Fee functions --------------------- ///

    function testMintWithEthAsFeeWithExpiredHash() public {
        emit log_named_decimal_uint("balance", address(this).balance, 18);
        uint256 paymentAmount = 10_000;

        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            address(nft),
            address(0),
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams memory inputs = ERC1155AutoGraphMinterLogic
            .MintWithEthAsFeeParams(
                parts.recipient,
                parts.jobId,
                parts.tokenId,
                parts.units,
                parts.hash,
                parts.salt,
                parts.signature,
                address(nft),
                parts.paymentAmount,
                block.timestamp
            );

        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintWithEthAsFee{value: parts.paymentAmount}(inputs);

        // assert nft balance
        assertEq(nft.balanceOf(parts.recipient, parts.tokenId), parts.units);

        // assert payment Fee balance
        assertEq(address(_defaultPaymentRecipient).balance, parts.paymentAmount);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintWithEthAsFee{value: parts.paymentAmount}(inputs);
    }

    function testMintWithEthAsFeeWithExpiredJob() public {
        emit log_named_decimal_uint("balance", address(this).balance, 18);
        uint256 paymentAmount = 10_000;

        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            address(nft),
            address(0),
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams memory inputs = ERC1155AutoGraphMinterLogic
            .MintWithEthAsFeeParams(
                parts.recipient,
                parts.jobId,
                parts.tokenId,
                parts.units,
                parts.hash,
                parts.salt,
                parts.signature,
                address(nft),
                parts.paymentAmount,
                block.timestamp
            );

        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintWithEthAsFee{value: parts.paymentAmount}(inputs);

        // assert nft balance
        assertEq(nft.balanceOf(parts.recipient, parts.tokenId), parts.units);

        // assert payment Fee balance
        assertEq(address(_defaultPaymentRecipient).balance, parts.paymentAmount);

        // expired job with valid hash
        parts = Helper.setupTx(
            Helper.SetupTxParams(vm, _privateKey, address(nft), 99, 1, 1, address(0), parts.paymentAmount, block.timestamp)
        );
        inputs = ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(nft),
            parts.paymentAmount,
            block.timestamp
        );

        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintWithEthAsFee{value: parts.paymentAmount}(inputs);
    }

    function testMintWithEthAsFeeIncorrectEthAmount() public {
        uint256 paymentAmount = 10_000;

        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            address(nft),
            address(0),
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams memory inputs = ERC1155AutoGraphMinterLogic
            .MintWithEthAsFeeParams(
                parts.recipient,
                parts.jobId,
                parts.tokenId,
                parts.units,
                parts.hash,
                parts.salt,
                parts.signature,
                address(nft),
                parts.paymentAmount,
                block.timestamp
            );

        vm.expectRevert("ERC1155AutoGraphMinter: msg.value must match paymentAmount");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintWithEthAsFee{value: parts.paymentAmount / 2}(inputs);
    }

    function testMintWithEthAsFeeIncorrectEthAmount0() public {
        uint256 paymentAmount = 10_000;

        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            address(nft),
            address(0),
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams memory inputs = ERC1155AutoGraphMinterLogic
            .MintWithEthAsFeeParams(
                parts.recipient,
                parts.jobId,
                parts.tokenId,
                parts.units,
                parts.hash,
                parts.salt,
                parts.signature,
                address(nft),
                0,
                block.timestamp
            );

        vm.expectRevert("ERC1155AutoGraphMinter: paymentAmount must be greater than 0");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintWithEthAsFee{value: parts.paymentAmount / 2}(inputs);
    }

    /// --------------------- Testing Mint Batch for free functions --------------------- ///

    function testMintBatchForFreeSucessAndExpireHash() public {
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
            addresses.adminAddress
        );

        // mint
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintBatchForFree(address(nft), address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(nft.balanceOf(address(this), i), 10);
        }

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintBatchForFree(address(nft), address(this), params);
    }

    function testMintBatchForFreeIncorrectSigningRole() public {
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
            addresses.adminAddress
        );

        vm.prank(addresses.adminAddress);
        core.revokeRole(Roles.MINTER_NOTARY_PROTOCOL_ROLE, _notary);

        vm.expectRevert("ERC1155AutoGraphMinter: Missing MINTER_NOTARY Role");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintBatchForFree(address(nft), address(this), params);
    }

    function testMintBatchForFreeInvalidUnits() public {
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
            addresses.adminAddress
        );

        params[params.length - 1].units = 999;

        vm.expectRevert("ERC1155AutoGraphMinter: Hash mismatch");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintBatchForFree(address(nft), address(this), params);
    }

    /// --------------------- Testing Mint Batch With PaymentToken as fee functions --------------------- ///

    function testMintBatchWithPaymentTokenAsFeeSucceedsAndExpiresHash() public {
        uint256 testItems = 10;
        uint256 paymentAmountPerMint = 10_000;
        uint256 totalCost = testItems * paymentAmountPerMint;
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
            0,
            addresses.adminAddress,
            testItems,
            address(token),
            paymentAmountPerMint,
            block.timestamp
        );

        token.mint(address(this), totalCost);
        token.approve(address(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy))), totalCost);

        // mint
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintBatchWithPaymentTokenAsFee(address(nft), address(this), address(token), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(nft.balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(token.balanceOf(address(_defaultPaymentRecipient)), totalCost, "Payment token balance incorrect");

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintBatchWithPaymentTokenAsFee(address(nft), address(this), address(token), params);
    }

    /// --------------------- Testing Mint Batch With Eth as Fee functions --------------------- ///

    function testMintBatchWithEthAsFeeShouldSucceedsAndExpiresHash() public {
        uint256 testItems = 10;
        uint256 paymentAmountPerMint = 10_000;
        uint256 totalCost = testItems * paymentAmountPerMint;
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
            0,
            addresses.adminAddress,
            testItems,
            address(0),
            paymentAmountPerMint,
            block.timestamp
        );

        // mint
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintBatchWithEthAsFee{value: totalCost}(address(nft), address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(nft.balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(address(_defaultPaymentRecipient).balance, totalCost);
    }

    function testMintBatchWithEthAsFeeIncorrectAmount() public {
        uint256 testItems = 10;
        uint256 paymentAmountPerMint = 10_000;
        uint256 totalCost = testItems * paymentAmountPerMint;
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
            0,
            addresses.adminAddress,
            testItems,
            address(0),
            paymentAmountPerMint,
            block.timestamp
        );

        vm.expectRevert("ERC1155AutoGraphMinter: msg.value must match total payment");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintBatchWithEthAsFee{value: totalCost / 2}(address(nft), address(this), params);
    }

    /// --------------------- Testing Update Payment Recipient functions  --------------------- ///

    function testUpdatePaymentRecipient() public {
        vm.prank(addresses.adminAddress);
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).updatePaymentRecipient(address(0x123));
        assertEq(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).paymentRecipient(), address(0x123));
    }

    function testUpdatePaymentRecipientInvalidAddress() public {
        vm.prank(addresses.adminAddress);
        vm.expectRevert("ERC1155AutoGraphMinter: paymentRecipient must not be address(0)");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).updatePaymentRecipient(address(0));
    }

    function testUpdatePaymentRecipientFail() public {
        vm.expectRevert("CoreRef: no role on core");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).updatePaymentRecipient(address(0x123));
    }

    /// --------------------- Testing Whitelisting functions  --------------------- ///

    function testAddWhitelistedContractAdmin() public {
        assertFalse(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).whitelistedAddresses(address(0x123)));
        vm.prank(addresses.adminAddress);
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).addWhitelistedContract(address(0x123));
        assertTrue(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).whitelistedAddresses(address(0x123)));
    }

    function testAddWhitelistedContractGoveror() public {
        assertFalse(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).whitelistedAddresses(address(0x123)));
        vm.prank(addresses.tokenGovernorAddress);
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).addWhitelistedContract(address(0x123));
        assertTrue(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).whitelistedAddresses(address(0x123)));
    }

    function testAddWhitelistedContractFail() public {
        assertFalse(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).whitelistedAddresses(address(0x123)));
        vm.expectRevert("CoreRef: no role on core");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).addWhitelistedContract(address(0x123));
    }

    function testAddWhitelistedContractsFail() public {
        vm.expectRevert("CoreRef: no role on core");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).addWhitelistedContracts(addressesToAdd);
    }

    function testAddWhitelistedContracts() public {
        vm.prank(addresses.adminAddress);
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).addWhitelistedContracts(addressesToAdd);
        assertTrue(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).whitelistedAddresses(address(0x123)));
        assertTrue(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).whitelistedAddresses(address(0x456)));
        assertTrue(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).whitelistedAddresses(address(0x789)));
    }

    function testRemoveWhitelistedContract() public {
        vm.prank(addresses.adminAddress);
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).removeWhitelistedContract(address(0x321));
        assertFalse(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).whitelistedAddresses(address(0x321)));
    }

    function testRemoveWhitelistedContractFail() public {
        vm.expectRevert("CoreRef: no role on core");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).removeWhitelistedContract(address(0x321));
    }

    function testRemoveWhitelistedContracts() public {
        vm.prank(addresses.adminAddress);
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).removeWhitelistedContracts(defaultWhitelistedAddresses);
        assertFalse(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).whitelistedAddresses(address(0x987)));
        assertFalse(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).whitelistedAddresses(address(0x654)));
        assertFalse(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).whitelistedAddresses(address(0x321)));
    }

    function testRemoveWhitelistedContractsFail() public {
        vm.expectRevert("CoreRef: no role on core");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).removeWhitelistedContracts(defaultWhitelistedAddresses);
    }

    /// --------------------- Testing Update ExpiryTokenHoursValid  --------------------- ///

    function testUpdateExpiryTokenHoursValid(uint8 _hour) public {
        uint256 h = _bound(_hour, 1, 24);
        vm.prank(addresses.adminAddress);
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).updateExpiryTokenHoursValid(uint8(h));
        assertEq(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).expiryTokenHoursValid(), uint8(h));
    }

    function testUpdateExpiryTokenHoursInValid0() public {
        uint8 invalidHour = 0;
        vm.prank(addresses.adminAddress);
        vm.expectRevert("ERC1155AutoGraphMinter: Hours must be between 1 and 24");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).updateExpiryTokenHoursValid(invalidHour);
    }

    function testUpdateExpiryTokenHoursInValid25() public {
        uint8 invalidHour = 25;
        vm.prank(addresses.adminAddress);
        vm.expectRevert("ERC1155AutoGraphMinter: Hours must be between 1 and 24");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).updateExpiryTokenHoursValid(invalidHour);
    }

    /// --------------------- Testing ExpiryToken  --------------------- ///

    function testMintForFreeExpiryTokenExpired() public {
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft));

        /// warp 1 hour and 1.
        vm.warp(block.timestamp + 1 hours + 1);

        vm.expectRevert("ERC1155AutoGraphMinter: Expiry token is expired");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(nft),
            parts.expiryToken
        );
    }

    function testMintForFreeExpiryTokenInTheFuture() public {
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft));

        vm.expectRevert("ERC1155AutoGraphMinter: Expiry token must be in the past");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(nft),
            parts.expiryToken + 1 seconds
        );
    }

    function testMintWithEthAsFeeExpireTokenExpired() public {
        uint256 expiryToken = block.timestamp;
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft), address(0), 111, expiryToken);

        /// warp 1 hour and 1.
        vm.warp(block.timestamp + 1 hours + 1);

        ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams memory inputs = ERC1155AutoGraphMinterLogic
            .MintWithEthAsFeeParams(
                parts.recipient,
                parts.jobId,
                parts.tokenId,
                parts.units,
                parts.hash,
                parts.salt,
                parts.signature,
                address(nft),
                parts.paymentAmount,
                block.timestamp
            );

        vm.expectRevert("ERC1155AutoGraphMinter: Expiry token is expired");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintWithEthAsFee{value: 111}(inputs);
    }

    function testMintWithEthAsFeeExpiryTokenInTheFuture() public {
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft), address(0), 111, block.timestamp);

        ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams memory inputs = ERC1155AutoGraphMinterLogic
            .MintWithEthAsFeeParams(
                parts.recipient,
                parts.jobId,
                parts.tokenId,
                parts.units,
                parts.hash,
                parts.salt,
                parts.signature,
                address(nft),
                parts.paymentAmount,
                parts.expiryToken + 1 seconds
            );

        vm.expectRevert("ERC1155AutoGraphMinter: Expiry token must be in the past");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintWithEthAsFee{value: 111}(inputs);
    }

    function testMintWithPaymentTokenAsFeeExpiryTokenExpired() public {
        uint256 expiryToken = block.timestamp;
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft), address(token), 111, expiryToken);

        token.mint(address(this), 111);
        token.approve(address(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy))), 111);

        ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams memory inputs = ERC1155AutoGraphMinterLogic
            .MintWithPaymentTokenAsFeeParams(
                parts.recipient,
                parts.jobId,
                parts.tokenId,
                parts.units,
                parts.hash,
                parts.salt,
                parts.signature,
                address(nft),
                address(token),
                parts.paymentAmount,
                expiryToken
            );

        /// warp 1 hour and 1.
        vm.warp(block.timestamp + 1 hours + 1);

        vm.expectRevert("ERC1155AutoGraphMinter: Expiry token is expired");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintWithPaymentTokenAsFee(inputs);
    }

    function testMintWithPaymentTokenAsFeeExpiryTokenInTheFuture() public {
        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            address(nft),
            address(token),
            111,
            block.timestamp
        );

        token.mint(address(this), 111);
        token.approve(address(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy))), 111);

        ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams memory inputs = ERC1155AutoGraphMinterLogic
            .MintWithPaymentTokenAsFeeParams(
                parts.recipient,
                parts.jobId,
                parts.tokenId,
                parts.units,
                parts.hash,
                parts.salt,
                parts.signature,
                address(nft),
                address(token),
                parts.paymentAmount,
                parts.expiryToken + 1 seconds
            );

        vm.expectRevert("ERC1155AutoGraphMinter: Expiry token must be in the past");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintWithPaymentTokenAsFee(inputs);
    }

    /// --------------------- Testing ExpiryToken Batch Methods --------------------- ///

    function testMintBatchForFreeExpiryTokenExpired() public {
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
            addresses.adminAddress
        );

        /// warp 1 hour and 1.
        vm.warp(block.timestamp + 1 hours + 1);

        // mint
        vm.expectRevert("ERC1155AutoGraphMinter: Expiry token is expired");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintBatchForFree(address(nft), address(this), params);
    }

    function testMintBatchWithPaymentTokenAsFeeExpiryTokenExpired() public {
        uint256 testItems = 10;
        uint256 paymentAmountPerMint = 10_000;
        uint256 totalCost = testItems * paymentAmountPerMint;
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
            0,
            addresses.adminAddress,
            testItems,
            address(token),
            paymentAmountPerMint,
            block.timestamp
        );

        token.mint(address(this), totalCost);
        token.approve(address(ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy))), totalCost);

        /// warp 1 hour and 1.
        vm.warp(block.timestamp + 1 hours + 1);

        // mint
        vm.expectRevert("ERC1155AutoGraphMinter: Expiry token is expired");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintBatchWithPaymentTokenAsFee(address(nft), address(this), address(token), params);
    }

    function testMintBatchWithEthAsFeeExpiryTokenExpired() public {
        uint256 testItems = 10;
        uint256 paymentAmountPerMint = 10_000;
        uint256 totalCost = testItems * paymentAmountPerMint;
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
            0,
            addresses.adminAddress,
            testItems,
            address(0),
            paymentAmountPerMint,
            block.timestamp
        );

        /// warp 1 hour and 1.
        vm.warp(block.timestamp + 1 hours + 1);

        // mint
        vm.expectRevert("ERC1155AutoGraphMinter: Expiry token is expired");
        ERC1155AutoGraphMinterImpl(address(_autoGraphMinterProxy)).mintBatchWithEthAsFee{value: totalCost}(address(nft), address(this), params);
    }

    /// --------------------- Testing Proxy functions --------------------- ///

    function testProxyUpgrade() public {
        // Deploy a new implementation (with core parameter)
        ERC1155AutoGraphMinterImpl newImpl = new ERC1155AutoGraphMinterImpl(address(core));
        
        // Use payable cast for proxy
        ERC1155AutoGraphMinterProxy(payable(address(_autoGraphMinterProxy))).upgradeTo(address(newImpl));
        
        // Check implementation
        assertEq(ERC1155AutoGraphMinterProxy(payable(address(_autoGraphMinterProxy))).implementation(), address(newImpl));
    }
    
    function testProxyAdmin() public {
        // Test contract is the admin
        assertEq(ERC1155AutoGraphMinterProxy(payable(address(_autoGraphMinterProxy))).admin(), address(this));
        
        // Change admin (with payable cast)
        address newAdmin = address(0x999);
        ERC1155AutoGraphMinterProxy(payable(address(_autoGraphMinterProxy))).changeAdmin(newAdmin);
        
        // Check that admin was updated
        assertEq(ERC1155AutoGraphMinterProxy(payable(address(_autoGraphMinterProxy))).admin(), newAdmin);
    }
    
    function testProxyAdminProtection() public {
        // Change admin first (with payable cast)
        address newAdmin = address(0x999);
        ERC1155AutoGraphMinterProxy(payable(address(_autoGraphMinterProxy))).changeAdmin(newAdmin);
        
        // Try to call admin function from non-admin account
        vm.expectRevert("Proxy: caller is not admin");
        ERC1155AutoGraphMinterProxy(payable(address(_autoGraphMinterProxy))).upgradeTo(address(0x888));
    }
}
