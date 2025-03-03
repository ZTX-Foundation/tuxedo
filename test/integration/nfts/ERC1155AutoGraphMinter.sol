// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ERC1155AutoGraphMinterHelperLib as Helper} from "test/helpers/ERC1155AutoGraphMinterHelper.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {BaseTest} from "test/integration/BaseTest.sol";

import {Token} from "@protocol/token/Token.sol";
import {ERC1155AutoGraphMinterLogic} from "@protocol/nfts/ERC1155AutoGraphMinterLogic.sol";
import {ERC1155AutoGraphMinterProxy} from "@protocol/nfts/ERC1155AutoGraphMinterProxy.sol";
import {ERC1155AutoGraphMinterImpl} from "@protocol/nfts/ERC1155AutoGraphMinterImpl.sol";

contract IntegrationTestERC1155AutoGraphMinter is BaseTest {
    /// @notice ZTX ERC20
    Token token;

    /// @notice NFT contract addresses
    address erc1155Consumables;
    address erc1155Placeables;
    address erc1155Wearables;

    /// @notice ERC1155AutoGraphMinter contract using test
    address autoGraphMinter;

    /// @notice NFT whitelisted contract addresses
    address[] nftContractAddresses = new address[](3);

    /// @notice rate limit per second in RateLimitedV2
    uint128 private constant _REPLENISH_RATE_PER_SECOND = 100;

    /// @notice buffer cap in RateLimited
    uint128 private constant _BUFFER_CAP = 1_000;

    /// @notice private key for the offline notary hash signing
    uint256 private _privateKey;
    address private _notary;

    function setUp() public override {
        super.setUp();

        token = Token(addresses.getAddress("TOKEN")); /// use actual ZTX token

        erc1155Consumables = addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES");
        erc1155Placeables = addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES");
        erc1155Wearables = addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES");

        nftContractAddresses = [erc1155Consumables, erc1155Placeables, erc1155Wearables];

        string memory mnemonic = "test test test test test test test test test test test junk";
        _privateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/1/", 0);
        _notary = vm.addr(_privateKey);

        /// @dev main contract under test
        ERC1155AutoGraphMinterProxy proxy = new ERC1155AutoGraphMinterProxy(
            address(new ERC1155AutoGraphMinterImpl(addresses.getAddress("CORE"))),
            address(this) // Test contract as admin
        );
        
        // Initialize through proxy
        ERC1155AutoGraphMinterImpl(address(proxy)).initialize(
            addresses.getAddress("CORE"),
            nftContractAddresses,
            _REPLENISH_RATE_PER_SECOND,
            _BUFFER_CAP,
            address(this), // Assuming address(this) is the paymentRecipient
            1 // 1 hour expiry token timeout
        );
        
        // Store the proxy address
        autoGraphMinter = address(proxy);

        /// @dev Set up notary signing role
        vm.startPrank(addresses.getAddress("ADMIN_MULTISIG"));
        Core(addresses.getAddress("CORE")).grantRole(Roles.MINTER_NOTARY_PROTOCOL_ROLE, _notary);
        vm.stopPrank();

        /// @dev Setup supplyCaps
        vm.startPrank(addresses.getAddress("ADMIN_MULTISIG"));
        uint256 supplyCap = 10_000;
        ERC1155MaxSupplyMintable(erc1155Consumables).setSupplyCap(0, supplyCap);
        ERC1155MaxSupplyMintable(erc1155Consumables).setSupplyCap(1, supplyCap);
        ERC1155MaxSupplyMintable(erc1155Placeables).setSupplyCap(0, supplyCap);
        ERC1155MaxSupplyMintable(erc1155Placeables).setSupplyCap(1, supplyCap);
        ERC1155MaxSupplyMintable(erc1155Wearables).setSupplyCap(0, supplyCap);
        ERC1155MaxSupplyMintable(erc1155Wearables).setSupplyCap(1, supplyCap);
        vm.stopPrank();
    }

    /// --------------------- test minting functions Happy path ---------------------

    function testMintForFreeWithExpiredHash() public {
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, erc1155Consumables);

        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Consumables,
            block.timestamp
        );

        assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Consumables,
            block.timestamp
        );

        /// ------- erc1155Placeables -------

        parts = Helper.setupTx(
            Helper.SetupTxParams(vm, _privateKey, erc1155Placeables, 100, 0, 1, address(0), 0, block.timestamp)
        );
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Placeables,
            block.timestamp
        );

        assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Placeables,
            block.timestamp
        );

        /// ------- erc1155Wearables -------

        parts = Helper.setupTx(
            Helper.SetupTxParams(vm, _privateKey, erc1155Wearables, 101, 0, 1, address(0), 0, block.timestamp)
        );
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Wearables,
            block.timestamp
        );

        assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Wearables,
            block.timestamp
        );
    }

    function testMintForFreeWithExpiredJob() public {
        Helper.TxParts memory parts = Helper.setupTx(vm, _privateKey, erc1155Consumables);

        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Consumables,
            block.timestamp
        );

        assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        parts = Helper.setupTx(
            Helper.SetupTxParams(vm, _privateKey, erc1155Consumables, 99, 1, 1, address(0), 0, block.timestamp)
        );

        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Consumables,
            block.timestamp
        );

        /// ------- erc1155Placeables -------

        parts = Helper.setupTx(
            Helper.SetupTxParams(vm, _privateKey, erc1155Placeables, 100, 0, 1, address(0), 0, block.timestamp)
        );
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Placeables,
            block.timestamp
        );

        assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        parts = Helper.setupTx(
            Helper.SetupTxParams(vm, _privateKey, erc1155Placeables, 100, 1, 1, address(0), 0, block.timestamp)
        );
        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Placeables,
            block.timestamp
        );

        /// ------- erc1155Wearables -------

        parts = Helper.setupTx(
            Helper.SetupTxParams(vm, _privateKey, erc1155Wearables, 101, 0, 1, address(0), 0, block.timestamp)
        );
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Wearables,
            block.timestamp
        );

        assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        parts = Helper.setupTx(
            Helper.SetupTxParams(vm, _privateKey, erc1155Wearables, 101, 1, 1, address(0), 0, block.timestamp)
        );
        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintForFree(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Wearables,
            block.timestamp
        );
    }

    function testMintWithPaymentTokenSucceedsAndExpiresHash() public {
        uint paymentAmount = 111;
        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            erc1155Consumables,
            address(token),
            paymentAmount,
            block.timestamp
        );

        deal(address(token), address(this), paymentAmount, true);
        token.approve(address(autoGraphMinter), paymentAmount);

        ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams memory inputs = ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Consumables,
            address(token),
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithPaymentTokenAsFee(inputs);

        assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(parts.recipient, parts.tokenId), parts.units);
        assertEq(address(this).balance, paymentAmount);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithPaymentTokenAsFee(inputs);

        /// ------- erc1155Placeables -------

        uint256 paymentAmountTotal = paymentAmount;
        paymentAmount = 222;
        paymentAmountTotal += paymentAmount;

        parts = Helper.setupTx(
            Helper.SetupTxParams(
                vm,
                _privateKey,
                erc1155Placeables,
                100,
                0,
                1,
                address(token),
                paymentAmount,
                block.timestamp
            )
        );

        deal(address(token), address(this), paymentAmount, true);
        token.approve(address(autoGraphMinter), paymentAmount);

        inputs = ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Placeables,
            address(token),
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithPaymentTokenAsFee(inputs);

        assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(parts.recipient, parts.tokenId), parts.units);
        assertEq(address(this).balance, paymentAmountTotal);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithPaymentTokenAsFee(inputs);

        /// ------- erc1155Wearables -------

        paymentAmount = 333;
        paymentAmountTotal += paymentAmount;

        parts = Helper.setupTx(
            Helper.SetupTxParams(
                vm,
                _privateKey,
                erc1155Wearables,
                101,
                0,
                1,
                address(token),
                paymentAmount,
                block.timestamp
            )
        );

        deal(address(token), address(this), paymentAmount, true);
        token.approve(address(autoGraphMinter), paymentAmount);

        inputs = ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Wearables,
            address(token),
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithPaymentTokenAsFee(inputs);

        assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(parts.recipient, parts.tokenId), parts.units);
        assertEq(address(this).balance, paymentAmountTotal);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithPaymentTokenAsFee(inputs);
    }

    function testMintWithPaymentTokenSucceedsAndExpiresJob() public {
        uint paymentAmount = 111;
        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            erc1155Consumables,
            address(token),
            paymentAmount,
            block.timestamp
        );

        deal(address(token), address(this), paymentAmount, true);
        token.approve(address(autoGraphMinter), paymentAmount);

        ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams memory inputs = ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Consumables,
            address(token),
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithPaymentTokenAsFee(inputs);

        assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(parts.recipient, parts.tokenId), parts.units);
        assertEq(address(this).balance, paymentAmount);

        parts = Helper.setupTx(
            Helper.SetupTxParams(
                vm,
                _privateKey,
                erc1155Consumables,
                99,
                1,
                1,
                address(token),
                paymentAmount,
                block.timestamp
            )
        );
        inputs = ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Consumables,
            address(token),
            paymentAmount,
            block.timestamp
        );

        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithPaymentTokenAsFee(inputs);

        /// ------- erc1155Placeables -------

        uint256 paymentAmountTotal = paymentAmount;
        paymentAmount = 222;
        paymentAmountTotal += paymentAmount;

        parts = Helper.setupTx(
            Helper.SetupTxParams(
                vm,
                _privateKey,
                erc1155Placeables,
                100,
                0,
                1,
                address(token),
                paymentAmount,
                block.timestamp
            )
        );

        deal(address(token), address(this), paymentAmount, true);
        token.approve(address(autoGraphMinter), paymentAmount);

        inputs = ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Placeables,
            address(token),
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithPaymentTokenAsFee(inputs);

        assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(parts.recipient, parts.tokenId), parts.units);
        assertEq(address(this).balance, paymentAmountTotal);

        parts = Helper.setupTx(
            Helper.SetupTxParams(
                vm,
                _privateKey,
                erc1155Placeables,
                100,
                1,
                1,
                address(token),
                paymentAmount,
                block.timestamp
            )
        );
        inputs = ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Placeables,
            address(token),
            paymentAmount,
            block.timestamp
        );

        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithPaymentTokenAsFee(inputs);

        /// ------- erc1155Wearables -------

        paymentAmount = 333;
        paymentAmountTotal += paymentAmount;

        parts = Helper.setupTx(
            Helper.SetupTxParams(
                vm,
                _privateKey,
                erc1155Wearables,
                101,
                0,
                1,
                address(token),
                paymentAmount,
                block.timestamp
            )
        );

        deal(address(token), address(this), paymentAmount, true);
        token.approve(address(autoGraphMinter), paymentAmount);

        inputs = ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Wearables,
            address(token),
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithPaymentTokenAsFee(inputs);

        assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(parts.recipient, parts.tokenId), parts.units);
        assertEq(address(this).balance, paymentAmountTotal);

        parts = Helper.setupTx(
            Helper.SetupTxParams(
                vm,
                _privateKey,
                erc1155Wearables,
                101,
                1,
                1,
                address(token),
                paymentAmount,
                block.timestamp
            )
        );
        inputs = ERC1155AutoGraphMinterLogic.MintWithPaymentTokenAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Wearables,
            address(token),
            paymentAmount,
            block.timestamp
        );

        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithPaymentTokenAsFee(inputs);
    }

    function testMintWithEthAsFeeWithExpiredHash() public {
        uint256 paymentAmount = 10_000;

        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            erc1155Consumables,
            address(0),
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams memory inputs = ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Consumables,
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithEthAsFee{value: paymentAmount}(inputs);

        // assert nft balance
        assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        // assert payment Fee balance
        assertEq(address(this).balance, paymentAmount);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithEthAsFee{value: paymentAmount}(inputs);

        /// ------- erc1155Placeables -------
        uint paymentAmountTotal = paymentAmount;
        paymentAmount = 20_000;
        paymentAmountTotal += paymentAmount;

        parts = Helper.setupTx(
            Helper.SetupTxParams(
                vm,
                _privateKey,
                erc1155Placeables,
                100,
                0,
                1,
                address(0),
                paymentAmount,
                block.timestamp
            )
        );

        inputs = ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Placeables,
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithEthAsFee{value: paymentAmount}(inputs);

        // assert nft balance
        assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        // assert payment Fee balance
        assertEq(address(this).balance, paymentAmountTotal);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithEthAsFee{value: paymentAmount}(inputs);

        /// ------- erc11Wearable -------
        paymentAmount = 30_000;
        paymentAmountTotal += paymentAmount;

        parts = Helper.setupTx(
            Helper.SetupTxParams(
                vm,
                _privateKey,
                erc1155Wearables,
                101,
                0,
                1,
                address(0),
                paymentAmount,
                block.timestamp
            )
        );

        inputs = ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Wearables,
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithEthAsFee{value: paymentAmount}(inputs);

        // assert nft balance
        assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        // assert payment Fee balance
        assertEq(address(this).balance, paymentAmountTotal);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithEthAsFee{value: paymentAmount}(inputs);
    }

    function testMintWithEthAsFeeWithExpiredJob() public {
        uint256 paymentAmount = 10_000;

        Helper.TxParts memory parts = Helper.setupTx(
            vm,
            _privateKey,
            erc1155Consumables,
            address(0),
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams memory inputs = ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Consumables,
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithEthAsFee{value: paymentAmount}(inputs);

        // assert nft balance
        assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        // assert payment Fee balance
        assertEq(address(this).balance, paymentAmount);

        parts = Helper.setupTx(
            Helper.SetupTxParams(
                vm,
                _privateKey,
                erc1155Consumables,
                99,
                1,
                1,
                address(0),
                paymentAmount,
                block.timestamp
            )
        );
        inputs = ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Consumables,
            paymentAmount,
            block.timestamp
        );

        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithEthAsFee{value: paymentAmount}(inputs);

        /// ------- erc1155Placeables -------
        uint paymentAmountTotal = paymentAmount;
        paymentAmount = 20_000;
        paymentAmountTotal += paymentAmount;

        parts = Helper.setupTx(
            Helper.SetupTxParams(
                vm,
                _privateKey,
                erc1155Placeables,
                100,
                0,
                1,
                address(0),
                paymentAmount,
                block.timestamp
            )
        );

        inputs = ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Placeables,
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithEthAsFee{value: paymentAmount}(inputs);

        // assert nft balance
        assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        // assert payment Fee balance
        assertEq(address(this).balance, paymentAmountTotal);

        parts = Helper.setupTx(
            Helper.SetupTxParams(
                vm,
                _privateKey,
                erc1155Placeables,
                99,
                1,
                1,
                address(0),
                paymentAmount,
                block.timestamp
            )
        );
        inputs = ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Placeables,
            paymentAmount,
            block.timestamp
        );

        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithEthAsFee{value: paymentAmount}(inputs);

        /// ------- erc1155Wearables -------
        paymentAmount = 30_000;
        paymentAmountTotal += paymentAmount;

        parts = Helper.setupTx(
            Helper.SetupTxParams(
                vm,
                _privateKey,
                erc1155Wearables,
                101,
                0,
                1,
                address(0),
                paymentAmount,
                block.timestamp
            )
        );

        inputs = ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Wearables,
            paymentAmount,
            block.timestamp
        );

        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithEthAsFee{value: paymentAmount}(inputs);

        // assert nft balance
        assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        // assert payment Fee balance
        assertEq(address(this).balance, paymentAmountTotal);

        parts = Helper.setupTx(
            Helper.SetupTxParams(
                vm,
                _privateKey,
                erc1155Wearables,
                99,
                1,
                1,
                address(0),
                paymentAmount,
                block.timestamp
            )
        );
        inputs = ERC1155AutoGraphMinterLogic.MintWithEthAsFeeParams(
            parts.recipient,
            parts.jobId,
            parts.tokenId,
            parts.units,
            parts.hash,
            parts.salt,
            parts.signature,
            erc1155Wearables,
            paymentAmount,
            block.timestamp
        );

        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintWithEthAsFee{value: paymentAmount}(inputs);
    }

    /// --------------------- test batch minting functions ---------------------

    function testMintBatchForFreeWithExpiredHash() public {
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Consumables),
            addresses.getAddress("ADMIN_MULTISIG")
        );

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchForFree(erc1155Consumables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(address(this), i), 10);
        }

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchForFree(erc1155Consumables, address(this), params);

        /// ------- erc1155Placeables -------

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Placeables),
            10,
            addresses.getAddress("ADMIN_MULTISIG"),
            10,
            address(0),
            0,
            block.timestamp
        );

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchForFree(erc1155Placeables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(address(this), i), 10);
        }

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchForFree(erc1155Placeables, address(this), params);

        /// ------- erc1155Wearables -------

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Wearables),
            20,
            addresses.getAddress("ADMIN_MULTISIG"),
            10,
            address(0),
            0,
            block.timestamp
        );

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchForFree(erc1155Wearables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(address(this), i), 10);
        }

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchForFree(erc1155Wearables, address(this), params);
    }

    function testMintBatchForFreeWithExpiredJob() public {
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Consumables),
            addresses.getAddress("ADMIN_MULTISIG")
        );

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchForFree(erc1155Consumables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(address(this), i), 10);
        }

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Consumables),
            0,
            addresses.getAddress("ADMIN_MULTISIG"),
            10,
            address(0),
            0,
            block.timestamp - 100
        );

        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchForFree(erc1155Consumables, address(this), params);

        /// ------- erc1155Placeables -------

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Placeables),
            10,
            addresses.getAddress("ADMIN_MULTISIG"),
            10,
            address(0),
            0,
            block.timestamp
        );

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchForFree(erc1155Placeables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(address(this), i), 10);
        }

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Placeables),
            10,
            addresses.getAddress("ADMIN_MULTISIG"),
            10,
            address(0),
            0,
            block.timestamp - 100
        );
        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchForFree(erc1155Placeables, address(this), params);

        /// ------- erc1155Wearables -------

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Wearables),
            20,
            addresses.getAddress("ADMIN_MULTISIG"),
            10,
            address(0),
            0,
            block.timestamp
        );

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchForFree(erc1155Wearables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(address(this), i), 10);
        }

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Wearables),
            20,
            addresses.getAddress("ADMIN_MULTISIG"),
            10,
            address(0),
            0,
            block.timestamp - 100
        );
        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchForFree(erc1155Wearables, address(this), params);
    }

    function testMintBatchWithPaymentTokenAsFeeWithExpiredHash() public {
        uint256 testItems = 10;
        uint256 paymentAmountPerMint = 10_000;
        uint256 totalCost = testItems * paymentAmountPerMint;
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Consumables),
            0,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(token),
            paymentAmountPerMint,
            block.timestamp
        );

        deal(address(token), address(this), totalCost, true);
        token.approve(address(autoGraphMinter), totalCost);

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithPaymentTokenAsFee(erc1155Consumables, address(this), address(token), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(address(this).balance, totalCost);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithPaymentTokenAsFee(erc1155Consumables, address(this), address(token), params);

        /// ------- erc1155Placeables -------

        uint runningTotal = totalCost;

        testItems = 10;
        paymentAmountPerMint = 10_000;
        totalCost = testItems * paymentAmountPerMint;
        runningTotal += totalCost;

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Placeables),
            10,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(token),
            paymentAmountPerMint,
            block.timestamp
        );

        deal(address(token), address(this), totalCost, true);
        token.approve(address(autoGraphMinter), totalCost);

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithPaymentTokenAsFee(erc1155Placeables, address(this), address(token), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(address(this).balance, runningTotal);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithPaymentTokenAsFee(erc1155Placeables, address(this), address(token), params);

        /// ------- erc1155Wearables -------

        testItems = 10;
        paymentAmountPerMint = 10_000;
        totalCost = testItems * paymentAmountPerMint;
        runningTotal += totalCost;

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Wearables),
            20,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(token),
            paymentAmountPerMint,
            block.timestamp
        );

        deal(address(token), address(this), totalCost, true);
        token.approve(address(autoGraphMinter), totalCost);

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithPaymentTokenAsFee(erc1155Wearables, address(this), address(token), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(address(this).balance, runningTotal);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithPaymentTokenAsFee(erc1155Wearables, address(this), address(token), params);
    }

    function testMintBatchWithPaymentTokenAsFeeWithExpiredJob() public {
        uint256 testItems = 10;
        uint256 paymentAmountPerMint = 10_000;
        uint256 totalCost = testItems * paymentAmountPerMint;
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Consumables),
            0,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(token),
            paymentAmountPerMint,
            block.timestamp
        );

        deal(address(token), address(this), totalCost, true);
        token.approve(address(autoGraphMinter), totalCost);

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithPaymentTokenAsFee(erc1155Consumables, address(this), address(token), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(address(this).balance, totalCost);

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Consumables),
            0,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(token),
            paymentAmountPerMint,
            block.timestamp - 100
        );
        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithPaymentTokenAsFee(erc1155Consumables, address(this), address(token), params);

        /// ------- erc1155Placeables -------

        uint runningTotal = totalCost;

        testItems = 10;
        paymentAmountPerMint = 10_000;
        totalCost = testItems * paymentAmountPerMint;
        runningTotal += totalCost;

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Placeables),
            10,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(token),
            paymentAmountPerMint,
            block.timestamp
        );

        deal(address(token), address(this), totalCost, true);
        token.approve(address(autoGraphMinter), totalCost);

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithPaymentTokenAsFee(erc1155Placeables, address(this), address(token), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(address(this).balance, runningTotal);

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Placeables),
            10,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(token),
            paymentAmountPerMint,
            block.timestamp - 100
        );
        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithPaymentTokenAsFee(erc1155Placeables, address(this), address(token), params);

        /// ------- erc1155Wearables -------

        testItems = 10;
        paymentAmountPerMint = 10_000;
        totalCost = testItems * paymentAmountPerMint;
        runningTotal += totalCost;

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Wearables),
            20,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(token),
            paymentAmountPerMint,
            block.timestamp
        );

        deal(address(token), address(this), totalCost, true);
        token.approve(address(autoGraphMinter), totalCost);

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithPaymentTokenAsFee(erc1155Wearables, address(this), address(token), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(address(this).balance, runningTotal);

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Wearables),
            20,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(token),
            paymentAmountPerMint,
            block.timestamp - 100
        );
        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithPaymentTokenAsFee(erc1155Wearables, address(this), address(token), params);
    }

    function testMintBatchWithEthAsFeeWithExpiredHash() public {
        uint256 testItems = 10;
        uint256 paymentAmountPerMint = 10_000;
        uint256 totalCost = testItems * paymentAmountPerMint;
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Consumables),
            0,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(0),
            paymentAmountPerMint,
            block.timestamp
        );

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithEthAsFee{value: totalCost}(erc1155Consumables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(address(this).balance, totalCost);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithEthAsFee{value: totalCost}(erc1155Consumables, address(this), params);

        /// ------- erc1155Placeables -------
        uint runningTotal = totalCost;

        testItems = 10;
        paymentAmountPerMint = 10_000;
        totalCost = testItems * paymentAmountPerMint;
        runningTotal += totalCost;

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Placeables),
            10,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(0),
            paymentAmountPerMint,
            block.timestamp
        );

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithEthAsFee{value: totalCost}(erc1155Placeables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(address(this).balance, runningTotal);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithEthAsFee{value: totalCost}(erc1155Placeables, address(this), params);

        /// ------- erc1155Wearables -------
        testItems = 10;
        paymentAmountPerMint = 10_000;
        totalCost = testItems * paymentAmountPerMint;
        runningTotal += totalCost;

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Wearables),
            20,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(0),
            paymentAmountPerMint,
            block.timestamp
        );

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithEthAsFee{value: totalCost}(erc1155Wearables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(address(this).balance, runningTotal);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithEthAsFee{value: totalCost}(erc1155Wearables, address(this), params);
    }

    function testMintBatchWithEthAsFeeWithExpiredJob() public {
        uint256 testItems = 10;
        uint256 paymentAmountPerMint = 10_000;
        uint256 totalCost = testItems * paymentAmountPerMint;
        ERC1155AutoGraphMinterLogic.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Consumables),
            0,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(0),
            paymentAmountPerMint,
            block.timestamp
        );

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithEthAsFee{value: totalCost}(erc1155Consumables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(address(this).balance, totalCost);

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Consumables),
            0,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(0),
            paymentAmountPerMint,
            block.timestamp - 100
        );
        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithEthAsFee{value: totalCost}(erc1155Consumables, address(this), params);

        /// ------- erc1155Placeables -------
        uint runningTotal = totalCost;

        testItems = 10;
        paymentAmountPerMint = 10_000;
        totalCost = testItems * paymentAmountPerMint;
        runningTotal += totalCost;

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Placeables),
            10,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(0),
            paymentAmountPerMint,
            block.timestamp
        );

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithEthAsFee{value: totalCost}(erc1155Placeables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(address(this).balance, runningTotal);

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Placeables),
            10,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(0),
            paymentAmountPerMint,
            block.timestamp - 100
        );
        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithEthAsFee{value: totalCost}(erc1155Placeables, address(this), params);

        /// ------- erc1155Wearables -------
        testItems = 10;
        paymentAmountPerMint = 10_000;
        totalCost = testItems * paymentAmountPerMint;
        runningTotal += totalCost;

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Wearables),
            20,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(0),
            paymentAmountPerMint,
            block.timestamp
        );

        // mint
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithEthAsFee{value: totalCost}(erc1155Wearables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(address(this).balance, runningTotal);

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Wearables),
            20,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(0),
            paymentAmountPerMint,
            block.timestamp - 100
        );
        vm.expectRevert("ERC1155AutoGraphMinter: Job already completed");
        ERC1155AutoGraphMinterImpl(autoGraphMinter).mintBatchWithEthAsFee{value: totalCost}(erc1155Wearables, address(this), params);
    }
}
