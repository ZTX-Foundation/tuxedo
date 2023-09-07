pragma solidity 0.8.18;

import "@forge-std/Test.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {MockERC20} from "@test/mock/MockERC20.sol";
import {Constants} from "@protocol/Constants.sol";
import {ERC20Splitter} from "@protocol/finance/ERC20Splitter.sol";
import {FinanceGuardian} from "@protocol/finance/FinanceGuardian.sol";
import {MockERC20, IERC20} from "@test/mock/MockERC20.sol";
import {GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {ERC1155AutoGraphMinter} from "@protocol/nfts/ERC1155AutoGraphMinter.sol";
import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";
import {ERC1155AutoGraphMinterHelperLib as Helper} from "@test/helpers/ERC1155AutoGraphMinterHelper.sol";
import {BaseTest} from "@test/BaseTest.sol";

contract UnitTestERC1155AutoGraphMinterTest is BaseTest {
    ERC1155AutoGraphMinter private _autoGraphMinter;

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

        _autoGraphMinter = new ERC1155AutoGraphMinter(
            address(core),
            defaultWhitelistedAddresses,
            _REPLENISH_RATE_PER_SECOND,
            _BUFFER_CAP,
            _defaultPaymentRecipient,
            1
        );

        vm.startPrank(addresses.adminAddress);
        _autoGraphMinter.addWhitelistedContract(address(nft));
        nft.setSupplyCap(0, supplyCap);
        core.grantRole(Roles.MINTER, address(_autoGraphMinter));
        core.grantRole(Roles.LOCKER, address(_autoGraphMinter));
        core.grantRole(Roles.MINTER_NOTARY, _notary);
        vm.stopPrank();
    }

    /// --------------------- Testing Hash functions --------------------- ///

    function testHashEncoding() public {
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft));

        // setup hash manually
        bytes32 hashFirstPass = keccak256(
            abi.encode(
                parts.recipent,
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
        address signer = _autoGraphMinter.recoverSigner(parts.hash, parts.signature);

        // assert signer is the same as the signer of the hash
        assertEq(signer, vm.addr(_privateKey));
    }

    /// --------------------- Testing Mint for free functions --------------------- ///

    function testMintForFreeSuccessAndExpireHash() public {
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft));

        // mint
        _autoGraphMinter.mintForFree(
            parts.recipent,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(nft),
            block.timestamp
        );

        // assert balance
        assertEq(nft.balanceOf(parts.recipent, parts.tokenId), parts.units);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        _autoGraphMinter.mintForFree(
            parts.recipent,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(nft),
            block.timestamp
        );
    }

    function testMintForFreeMissingSigningRole() public {
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft));

        vm.prank(addresses.adminAddress);
        core.revokeRole(Roles.MINTER_NOTARY, _notary);

        vm.expectRevert("ERC1155AutoGraphMinter: Missing MINTER_NOTARY Role");
        _autoGraphMinter.mintForFree(
            parts.recipent,
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
        _autoGraphMinter.mintForFree(
            parts.recipent,
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
        _autoGraphMinter.mintForFree(
            parts.recipent,
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
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft));

        vm.expectRevert("WhitelistedAddress: Provided address is not whitelisted");
        _autoGraphMinter.mintForFree(
            parts.recipent,
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
        _autoGraphMinter.mintForFree(
            parts.recipent,
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
        _autoGraphMinter.mintForFree(
            address(0x123),
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

    function testMintWithPaymentTokenSuccessAndExpireHash() public {
        uint paymentAmount = 111;
        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            address(nft),
            address(token),
            paymentAmount,
            block.timestamp
        );

        token.mint(address(this), paymentAmount);
        token.approve(address(_autoGraphMinter), paymentAmount);

        ERC1155AutoGraphMinter.MintWithPaymentTokenAsFeeParams memory inputs = ERC1155AutoGraphMinter
            .MintWithPaymentTokenAsFeeParams(
                parts.recipent,
                parts.tokenId,
                parts.units,
                parts.hash,
                parts.salt,
                parts.signature,
                address(nft),
                address(token),
                111,
                block.timestamp
            );

        _autoGraphMinter.mintWithPaymentTokenAsFee(inputs);

        assertEq(nft.balanceOf(parts.recipent, parts.tokenId), parts.units);
        assertEq(token.balanceOf(address(_defaultPaymentRecipient)), paymentAmount);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        _autoGraphMinter.mintWithPaymentTokenAsFee(inputs);
    }

    function testMintWithPaymentTokenInvalidPaymentToken() public {
        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            address(nft),
            address(token),
            111,
            block.timestamp
        );

        ERC1155AutoGraphMinter.MintWithPaymentTokenAsFeeParams memory inputs = ERC1155AutoGraphMinter
            .MintWithPaymentTokenAsFeeParams(
                parts.recipent,
                parts.tokenId,
                parts.units,
                parts.hash,
                parts.salt,
                parts.signature,
                address(nft),
                address(0),
                111,
                block.timestamp
            );

        vm.expectRevert("ERC1155AutoGraphMinter: paymentToken must not be address(0)");
        _autoGraphMinter.mintWithPaymentTokenAsFee(inputs);
    }

    function testMintWithPaymentTokenInvalidPaymentAmount() public {
        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            address(nft),
            address(token),
            111,
            block.timestamp
        );

        ERC1155AutoGraphMinter.MintWithPaymentTokenAsFeeParams memory inputs = ERC1155AutoGraphMinter
            .MintWithPaymentTokenAsFeeParams(
                parts.recipent,
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
        _autoGraphMinter.mintWithPaymentTokenAsFee(inputs);
    }

    function testMintWithWithPaymentTokenIncorrectFeeAmount() public {
        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            address(nft),
            address(token),
            10_000,
            block.timestamp
        );

        ERC1155AutoGraphMinter.MintWithPaymentTokenAsFeeParams memory inputs = ERC1155AutoGraphMinter
            .MintWithPaymentTokenAsFeeParams(
                parts.recipent,
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
        _autoGraphMinter.mintWithPaymentTokenAsFee(inputs);
    }

    /// --------------------- Testing Mint for ETH Fee functions --------------------- ///

    function testMintWithEthAsFeeSuccessAndExpireHash() public {
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

        ERC1155AutoGraphMinter.MintWithEthAsFeeParams memory inputs = ERC1155AutoGraphMinter.MintWithEthAsFeeParams(
            parts.recipent,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(nft),
            paymentAmount,
            block.timestamp
        );

        _autoGraphMinter.mintWithEthAsFee{value: paymentAmount}(inputs);

        // assert nft balance
        assertEq(nft.balanceOf(parts.recipent, parts.tokenId), parts.units);

        // assert payment Fee balance
        assertEq(address(_defaultPaymentRecipient).balance, paymentAmount);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        _autoGraphMinter.mintWithEthAsFee{value: paymentAmount}(inputs);
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

        ERC1155AutoGraphMinter.MintWithEthAsFeeParams memory inputs = ERC1155AutoGraphMinter.MintWithEthAsFeeParams(
            parts.recipent,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(nft),
            paymentAmount,
            block.timestamp
        );

        vm.expectRevert("ERC1155AutoGraphMinter: Payment amount does not match msg.value");
        _autoGraphMinter.mintWithEthAsFee{value: paymentAmount / 2}(inputs);
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

        ERC1155AutoGraphMinter.MintWithEthAsFeeParams memory inputs = ERC1155AutoGraphMinter.MintWithEthAsFeeParams(
            parts.recipent,
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
        _autoGraphMinter.mintWithEthAsFee{value: paymentAmount / 2}(inputs);
    }

    /// --------------------- Testing Mint Batch for free functions --------------------- ///

    function testMintBatchForFreeSucessAndExpireHash() public {
        ERC1155AutoGraphMinter.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
            addresses.adminAddress
        );

        // mint
        _autoGraphMinter.mintBatchForFree(address(nft), address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(nft.balanceOf(address(this), i), 10);
        }

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        _autoGraphMinter.mintBatchForFree(address(nft), address(this), params);
    }

    function testMintBatchForFreeIncorrectSigningRole() public {
        ERC1155AutoGraphMinter.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
            addresses.adminAddress
        );

        vm.prank(addresses.adminAddress);
        core.revokeRole(Roles.MINTER_NOTARY, _notary);

        vm.expectRevert("ERC1155AutoGraphMinter: Missing MINTER_NOTARY Role");
        _autoGraphMinter.mintBatchForFree(address(nft), address(this), params);
    }

    function testMintBatchForFreeInvalidUnits() public {
        ERC1155AutoGraphMinter.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
            addresses.adminAddress
        );

        params[params.length - 1].units = 999;

        vm.expectRevert("ERC1155AutoGraphMinter: Hash mismatch");
        _autoGraphMinter.mintBatchForFree(address(nft), address(this), params);
    }

    /// --------------------- Testing Mint Batch With PaymentToken as fee functions --------------------- ///

    function testMintBatchWithPaymentTokenAsFeeSucessAndExpireHash() public {
        uint256 testItems = 10;
        uint256 paymentAmountPerMint = 10_000;
        uint256 totalCost = testItems * paymentAmountPerMint;
        ERC1155AutoGraphMinter.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
            addresses.adminAddress,
            testItems,
            address(token),
            paymentAmountPerMint,
            block.timestamp
        );

        token.mint(address(this), totalCost);
        token.approve(address(_autoGraphMinter), totalCost);

        // mint
        _autoGraphMinter.mintBatchWithPaymentTokenAsFee(address(nft), address(this), address(token), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(nft.balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(token.balanceOf(address(_defaultPaymentRecipient)), totalCost, "Payment token balance incorrect");

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        _autoGraphMinter.mintBatchWithPaymentTokenAsFee(address(nft), address(this), address(token), params);
    }

    /// --------------------- Testing Mint Batch With Eth as Fee functions --------------------- ///

    function testMintBatchWithEthAsFeeShouldSucessedAndExpireHash() public {
        uint256 testItems = 10;
        uint256 paymentAmountPerMint = 10_000;
        uint256 totalCost = testItems * paymentAmountPerMint;
        ERC1155AutoGraphMinter.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
            addresses.adminAddress,
            testItems,
            address(0),
            paymentAmountPerMint,
            block.timestamp
        );

        // mint
        _autoGraphMinter.mintBatchWithEthAsFee{value: totalCost}(address(nft), address(this), params);

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
        ERC1155AutoGraphMinter.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
            addresses.adminAddress,
            testItems,
            address(0),
            paymentAmountPerMint,
            block.timestamp
        );

        vm.expectRevert("ERC1155AutoGraphMinter: Payment amount does not match msg.value");
        _autoGraphMinter.mintBatchWithEthAsFee{value: totalCost / 2}(address(nft), address(this), params);
    }

    /// --------------------- Testing Update Payment Recipient functions  --------------------- ///

    function testUpdatePaymentRecipient() public {
        vm.prank(addresses.adminAddress);
        _autoGraphMinter.updatePaymentRecipient(address(0x123));
        assertEq(_autoGraphMinter.paymentRecipient(), address(0x123));
    }

    function testUpdatePaymentRecipientInvalidAddress() public {
        vm.prank(addresses.adminAddress);
        vm.expectRevert("ERC1155AutoGraphMinter: paymentRecipient must not be address(0)");
        _autoGraphMinter.updatePaymentRecipient(address(0));
    }

    function testUpdatePaymentRecipientFail() public {
        vm.expectRevert("CoreRef: no role on core");
        _autoGraphMinter.updatePaymentRecipient(address(0x123));
    }

    /// --------------------- Testing Whitelisting functions  --------------------- ///

    function testAddWhitelistedContractAdmin() public {
        assertFalse(_autoGraphMinter.isWhitelistedAddress(address(0x123)));
        vm.prank(addresses.adminAddress);
        _autoGraphMinter.addWhitelistedContract(address(0x123));
        assertTrue(_autoGraphMinter.isWhitelistedAddress(address(0x123)));
    }

    function testAddWhitelistedContractGoveror() public {
        assertFalse(_autoGraphMinter.isWhitelistedAddress(address(0x123)));
        vm.prank(addresses.tokenGovernorAddress);
        _autoGraphMinter.addWhitelistedContract(address(0x123));
        assertTrue(_autoGraphMinter.isWhitelistedAddress(address(0x123)));
    }

    function testAddWhitelistedContractFail() public {
        assertFalse(_autoGraphMinter.isWhitelistedAddress(address(0x123)));
        vm.expectRevert("UNAUTHORIZED");
        _autoGraphMinter.addWhitelistedContract(address(0x123));
    }

    function testAddWhitelistedContractsFail() public {
        vm.expectRevert("UNAUTHORIZED");
        _autoGraphMinter.addWhitelistedContracts(addressesToAdd);
    }

    function testAddWhitelistedContracts() public {
        vm.prank(addresses.adminAddress);
        _autoGraphMinter.addWhitelistedContracts(addressesToAdd);
        assertTrue(_autoGraphMinter.isWhitelistedAddress(address(0x123)));
        assertTrue(_autoGraphMinter.isWhitelistedAddress(address(0x456)));
        assertTrue(_autoGraphMinter.isWhitelistedAddress(address(0x789)));
    }

    function testRemoveWhitelistedContract() public {
        vm.prank(addresses.adminAddress);
        _autoGraphMinter.removeWhitelistedContract(address(0x321));
        assertFalse(_autoGraphMinter.isWhitelistedAddress(address(0x321)));
    }

    function testRemoveWhitelistedContractFail() public {
        vm.expectRevert("UNAUTHORIZED");
        _autoGraphMinter.removeWhitelistedContract(address(0x321));
    }

    function testRemoveWhitelistedContracts() public {
        vm.prank(addresses.adminAddress);
        _autoGraphMinter.removeWhitelistedContracts(defaultWhitelistedAddresses);
        assertFalse(_autoGraphMinter.isWhitelistedAddress(address(0x987)));
        assertFalse(_autoGraphMinter.isWhitelistedAddress(address(0x654)));
        assertFalse(_autoGraphMinter.isWhitelistedAddress(address(0x321)));
    }

    function testRemoveWhitelistedContractsFail() public {
        vm.expectRevert("UNAUTHORIZED");
        _autoGraphMinter.removeWhitelistedContracts(defaultWhitelistedAddresses);
    }

    /// --------------------- Testing Update ExpiryTokenHoursValid  --------------------- ///

    function testUpdateExpiryTokenHoursValid(uint8 _hour) public {
        uint256 h = _bound(_hour, 1, 24);
        vm.prank(addresses.adminAddress);
        _autoGraphMinter.updateExpiryTokenHoursValid(uint8(h));
        assertEq(_autoGraphMinter.expiryTokenHoursValid(), uint8(h));
    }

    function testUpdateExpiryTokenHoursInValid0() public {
        uint8 invalidHour = 0;
        vm.prank(addresses.adminAddress);
        vm.expectRevert("ERC1155AutoGraphMinter: Hours must be between 1 and 24");
        _autoGraphMinter.updateExpiryTokenHoursValid(invalidHour);
    }

    function testUpdateExpiryTokenHoursInValid25() public {
        uint8 invalidHour = 25;
        vm.prank(addresses.adminAddress);
        vm.expectRevert("ERC1155AutoGraphMinter: Hours must be between 1 and 24");
        _autoGraphMinter.updateExpiryTokenHoursValid(invalidHour);
    }

    /// --------------------- Testing ExpiryToken  --------------------- ///

    function testMintForFreeExpiryTokenExpired() public {
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft));

        /// warp 1 hour and 1.
        vm.warp(block.timestamp + 1 hours + 1);

        vm.expectRevert("ERC1155AutoGraphMinter: Expiry token is expired");
        _autoGraphMinter.mintForFree(
            parts.recipent,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(nft),
            parts.expiryToken
        );
    }

    function testMintWithEthAsFeeExpireTokenExpired() public {
        uint256 expiryToken = block.timestamp;
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft), address(0), 111, expiryToken);

        /// warp 1 hour and 1.
        vm.warp(block.timestamp + 1 hours + 1);

        ERC1155AutoGraphMinter.MintWithEthAsFeeParams memory inputs = ERC1155AutoGraphMinter.MintWithEthAsFeeParams(
            parts.recipent,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            address(nft),
            111,
            expiryToken
        );

        vm.expectRevert("ERC1155AutoGraphMinter: Expiry token is expired");
        _autoGraphMinter.mintWithEthAsFee{value: 111}(inputs);
    }

    function testMintWithPaymentTokenAsFeeExpiryTokenExpired() public {
        uint256 expiryToken = block.timestamp;
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, address(nft), address(token), 111, expiryToken);

        token.mint(address(this), 111);
        token.approve(address(_autoGraphMinter), 111);

        ERC1155AutoGraphMinter.MintWithPaymentTokenAsFeeParams memory inputs = ERC1155AutoGraphMinter
            .MintWithPaymentTokenAsFeeParams(
                parts.recipent,
                parts.tokenId,
                parts.units,
                parts.hash,
                parts.salt,
                parts.signature,
                address(nft),
                address(token),
                111,
                expiryToken
            );

        /// warp 1 hour and 1.
        vm.warp(block.timestamp + 1 hours + 1);

        vm.expectRevert("ERC1155AutoGraphMinter: Expiry token is expired");
        _autoGraphMinter.mintWithPaymentTokenAsFee(inputs);
    }

    /// --------------------- Testing ExpiryToken Batch Methods --------------------- ///

    function testMintBatchForFreeExpiryTokenExpired() public {
        ERC1155AutoGraphMinter.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
            addresses.adminAddress
        );

        /// warp 1 hour and 1.
        vm.warp(block.timestamp + 1 hours + 1);

        // mint
        vm.expectRevert("ERC1155AutoGraphMinter: Expiry token is expired");
        _autoGraphMinter.mintBatchForFree(address(nft), address(this), params);
    }

    function testMintBatchWithPaymentTokenAsFeeExpiryTokenExpired() public {
        uint256 testItems = 10;
        uint256 paymentAmountPerMint = 10_000;
        uint256 totalCost = testItems * paymentAmountPerMint;
        ERC1155AutoGraphMinter.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
            addresses.adminAddress,
            testItems,
            address(token),
            paymentAmountPerMint,
            block.timestamp
        );

        token.mint(address(this), totalCost);
        token.approve(address(_autoGraphMinter), totalCost);

        /// warp 1 hour and 1.
        vm.warp(block.timestamp + 1 hours + 1);

        // mint
        vm.expectRevert("ERC1155AutoGraphMinter: Expiry token is expired");
        _autoGraphMinter.mintBatchWithPaymentTokenAsFee(address(nft), address(this), address(token), params);
    }

    function testMintBatchWithEthAsFeeExpiryTokenExpired() public {
        uint256 testItems = 10;
        uint256 paymentAmountPerMint = 10_000;
        uint256 totalCost = testItems * paymentAmountPerMint;
        ERC1155AutoGraphMinter.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            nft,
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
        _autoGraphMinter.mintBatchWithEthAsFee{value: totalCost}(address(nft), address(this), params);
    }
}
