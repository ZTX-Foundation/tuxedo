pragma solidity 0.8.18;

import {MockERC20} from "@test/mock/MockERC20.sol";
import {ERC1155AutoGraphMinterHelperLib as Helper} from "@test/helpers/ERC1155AutoGraphMinterHelper.sol";

import {ERC1155AutoGraphMinter} from "@protocol/nfts/ERC1155AutoGraphMinter.sol";
import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {BaseTest} from "@test/integration/BaseTest.sol";

contract IntegrationTestERC1155AutoGraphMinter is BaseTest {
    /// @notice Mock ERC20
    MockERC20 token;

    /// @notice NFT contract addresses
    address erc1155Consumables;
    address erc1155Placeables;
    address erc1155Wearables;

    /// @notice ERC1155AutoGraphMinter contract using test
    ERC1155AutoGraphMinter autoGraphMinter;

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

        token = new MockERC20();

        erc1155Consumables = addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES");
        erc1155Placeables = addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES");
        erc1155Wearables = addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES");

        nftContractAddresses = [erc1155Consumables, erc1155Placeables, erc1155Wearables];

        string memory mnemonic = "test test test test test test test test test test test junk";
        _privateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/1/", 0);
        _notary = vm.addr(_privateKey);

        /// @dev main contract under test
        autoGraphMinter = ERC1155AutoGraphMinter(addresses.getAddress("ERC1155_AUTO_GRAPH_MINTER"));

        /// @dev Set up contracts required roles
        vm.startPrank(addresses.getAddress("ADMIN_MULTISIG"));
        Core(addresses.getAddress("CORE")).grantRole(Roles.MINTER, address(autoGraphMinter));
        Core(addresses.getAddress("CORE")).grantRole(Roles.LOCKER, address(autoGraphMinter));
        vm.stopPrank();

        /// @dev Set up notary signing role
        vm.startPrank(addresses.getAddress("ADMIN_MULTISIG"));
        Core(addresses.getAddress("CORE")).grantRole(Roles.MINTER_NOTARY, _notary);
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

        autoGraphMinter.mintForFree(
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
        autoGraphMinter.mintForFree(
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
        autoGraphMinter.mintForFree(
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
        autoGraphMinter.mintForFree(
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
        autoGraphMinter.mintForFree(
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
        autoGraphMinter.mintForFree(
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

        autoGraphMinter.mintForFree(
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

        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintForFree(
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
        autoGraphMinter.mintForFree(
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
        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintForFree(
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
        autoGraphMinter.mintForFree(
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
        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintForFree(
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

        token.mint(address(this), paymentAmount);
        token.approve(address(autoGraphMinter), paymentAmount);

        ERC1155AutoGraphMinter.MintWithPaymentTokenAsFeeParams memory inputs = ERC1155AutoGraphMinter
            .MintWithPaymentTokenAsFeeParams(
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

        autoGraphMinter.mintWithPaymentTokenAsFee(inputs);

        assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(parts.recipient, parts.tokenId), parts.units);
        assertEq(token.balanceOf(autoGraphMinter.paymentRecipient()), paymentAmount);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        autoGraphMinter.mintWithPaymentTokenAsFee(inputs);

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

        token.mint(address(this), paymentAmount);
        token.approve(address(autoGraphMinter), paymentAmount);

        inputs = ERC1155AutoGraphMinter.MintWithPaymentTokenAsFeeParams(
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

        autoGraphMinter.mintWithPaymentTokenAsFee(inputs);

        assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(parts.recipient, parts.tokenId), parts.units);
        assertEq(token.balanceOf(autoGraphMinter.paymentRecipient()), paymentAmountTotal);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        autoGraphMinter.mintWithPaymentTokenAsFee(inputs);

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

        token.mint(address(this), paymentAmount);
        token.approve(address(autoGraphMinter), paymentAmount);

        inputs = ERC1155AutoGraphMinter.MintWithPaymentTokenAsFeeParams(
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

        autoGraphMinter.mintWithPaymentTokenAsFee(inputs);

        assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(parts.recipient, parts.tokenId), parts.units);
        assertEq(token.balanceOf(autoGraphMinter.paymentRecipient()), paymentAmountTotal);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        autoGraphMinter.mintWithPaymentTokenAsFee(inputs);
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

        token.mint(address(this), paymentAmount);
        token.approve(address(autoGraphMinter), paymentAmount);

        ERC1155AutoGraphMinter.MintWithPaymentTokenAsFeeParams memory inputs = ERC1155AutoGraphMinter
            .MintWithPaymentTokenAsFeeParams(
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

        autoGraphMinter.mintWithPaymentTokenAsFee(inputs);

        assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(parts.recipient, parts.tokenId), parts.units);
        assertEq(token.balanceOf(autoGraphMinter.paymentRecipient()), paymentAmount);

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
        inputs = ERC1155AutoGraphMinter.MintWithPaymentTokenAsFeeParams(
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

        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintWithPaymentTokenAsFee(inputs);

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

        token.mint(address(this), paymentAmount);
        token.approve(address(autoGraphMinter), paymentAmount);

        inputs = ERC1155AutoGraphMinter.MintWithPaymentTokenAsFeeParams(
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

        autoGraphMinter.mintWithPaymentTokenAsFee(inputs);

        assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(parts.recipient, parts.tokenId), parts.units);
        assertEq(token.balanceOf(autoGraphMinter.paymentRecipient()), paymentAmountTotal);

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
        inputs = ERC1155AutoGraphMinter.MintWithPaymentTokenAsFeeParams(
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

        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintWithPaymentTokenAsFee(inputs);

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

        token.mint(address(this), paymentAmount);
        token.approve(address(autoGraphMinter), paymentAmount);

        inputs = ERC1155AutoGraphMinter.MintWithPaymentTokenAsFeeParams(
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

        autoGraphMinter.mintWithPaymentTokenAsFee(inputs);

        assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(parts.recipient, parts.tokenId), parts.units);
        assertEq(token.balanceOf(autoGraphMinter.paymentRecipient()), paymentAmountTotal);

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
        inputs = ERC1155AutoGraphMinter.MintWithPaymentTokenAsFeeParams(
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

        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintWithPaymentTokenAsFee(inputs);
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

        ERC1155AutoGraphMinter.MintWithEthAsFeeParams memory inputs = ERC1155AutoGraphMinter.MintWithEthAsFeeParams(
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

        autoGraphMinter.mintWithEthAsFee{value: paymentAmount}(inputs);

        // assert nft balance
        assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        // assert payment Fee balance
        assertEq(autoGraphMinter.paymentRecipient().balance, paymentAmount);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        autoGraphMinter.mintWithEthAsFee{value: paymentAmount}(inputs);

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

        inputs = ERC1155AutoGraphMinter.MintWithEthAsFeeParams(
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

        autoGraphMinter.mintWithEthAsFee{value: paymentAmount}(inputs);

        // assert nft balance
        assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        // assert payment Fee balance
        assertEq(autoGraphMinter.paymentRecipient().balance, paymentAmountTotal);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        autoGraphMinter.mintWithEthAsFee{value: paymentAmount}(inputs);

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

        inputs = ERC1155AutoGraphMinter.MintWithEthAsFeeParams(
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

        autoGraphMinter.mintWithEthAsFee{value: paymentAmount}(inputs);

        // assert nft balance
        assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        // assert payment Fee balance
        assertEq(autoGraphMinter.paymentRecipient().balance, paymentAmountTotal);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        autoGraphMinter.mintWithEthAsFee{value: paymentAmount}(inputs);
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

        ERC1155AutoGraphMinter.MintWithEthAsFeeParams memory inputs = ERC1155AutoGraphMinter.MintWithEthAsFeeParams(
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

        autoGraphMinter.mintWithEthAsFee{value: paymentAmount}(inputs);

        // assert nft balance
        assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        // assert payment Fee balance
        assertEq(autoGraphMinter.paymentRecipient().balance, paymentAmount);

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
        inputs = ERC1155AutoGraphMinter.MintWithEthAsFeeParams(
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

        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintWithEthAsFee{value: paymentAmount}(inputs);

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

        inputs = ERC1155AutoGraphMinter.MintWithEthAsFeeParams(
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

        autoGraphMinter.mintWithEthAsFee{value: paymentAmount}(inputs);

        // assert nft balance
        assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        // assert payment Fee balance
        assertEq(autoGraphMinter.paymentRecipient().balance, paymentAmountTotal);

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
        inputs = ERC1155AutoGraphMinter.MintWithEthAsFeeParams(
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

        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintWithEthAsFee{value: paymentAmount}(inputs);

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

        inputs = ERC1155AutoGraphMinter.MintWithEthAsFeeParams(
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

        autoGraphMinter.mintWithEthAsFee{value: paymentAmount}(inputs);

        // assert nft balance
        assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(parts.recipient, parts.tokenId), parts.units);

        // assert payment Fee balance
        assertEq(autoGraphMinter.paymentRecipient().balance, paymentAmountTotal);

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
        inputs = ERC1155AutoGraphMinter.MintWithEthAsFeeParams(
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

        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintWithEthAsFee{value: paymentAmount}(inputs);
    }

    /// --------------------- test batch minting functions ---------------------

    function testMintBatchForFreeWithExpiredHash() public {
        ERC1155AutoGraphMinter.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Consumables),
            addresses.getAddress("ADMIN_MULTISIG")
        );

        // mint
        autoGraphMinter.mintBatchForFree(erc1155Consumables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(address(this), i), 10);
        }

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        autoGraphMinter.mintBatchForFree(erc1155Consumables, address(this), params);

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
        autoGraphMinter.mintBatchForFree(erc1155Placeables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(address(this), i), 10);
        }

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        autoGraphMinter.mintBatchForFree(erc1155Placeables, address(this), params);

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
        autoGraphMinter.mintBatchForFree(erc1155Wearables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(address(this), i), 10);
        }

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        autoGraphMinter.mintBatchForFree(erc1155Wearables, address(this), params);
    }

    function testMintBatchForFreeWithExpiredJob() public {
        ERC1155AutoGraphMinter.MintBatchParams[] memory params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Consumables),
            addresses.getAddress("ADMIN_MULTISIG")
        );

        // mint
        autoGraphMinter.mintBatchForFree(erc1155Consumables, address(this), params);

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

        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintBatchForFree(erc1155Consumables, address(this), params);

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
        autoGraphMinter.mintBatchForFree(erc1155Placeables, address(this), params);

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
        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintBatchForFree(erc1155Placeables, address(this), params);

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
        autoGraphMinter.mintBatchForFree(erc1155Wearables, address(this), params);

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
        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintBatchForFree(erc1155Wearables, address(this), params);
    }

    function testMintBatchWithPaymentTokenAsFeeWithExpiredHash() public {
        uint256 testItems = 10;
        uint256 paymentAmountPerMint = 10_000;
        uint256 totalCost = testItems * paymentAmountPerMint;
        ERC1155AutoGraphMinter.MintBatchParams[] memory params = Helper.setupTxs(
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

        token.mint(address(this), totalCost);
        token.approve(address(autoGraphMinter), totalCost);

        // mint
        autoGraphMinter.mintBatchWithPaymentTokenAsFee(erc1155Consumables, address(this), address(token), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(token.balanceOf(autoGraphMinter.paymentRecipient()), totalCost, "Payment token balance incorrect");

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        autoGraphMinter.mintBatchWithPaymentTokenAsFee(erc1155Consumables, address(this), address(token), params);

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

        token.mint(address(this), totalCost);
        token.approve(address(autoGraphMinter), totalCost);

        // mint
        autoGraphMinter.mintBatchWithPaymentTokenAsFee(erc1155Placeables, address(this), address(token), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(token.balanceOf(autoGraphMinter.paymentRecipient()), runningTotal, "Payment token balance incorrect");

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        autoGraphMinter.mintBatchWithPaymentTokenAsFee(erc1155Placeables, address(this), address(token), params);

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

        token.mint(address(this), totalCost);
        token.approve(address(autoGraphMinter), totalCost);

        // mint
        autoGraphMinter.mintBatchWithPaymentTokenAsFee(erc1155Wearables, address(this), address(token), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(token.balanceOf(autoGraphMinter.paymentRecipient()), runningTotal, "Payment token balance incorrect");

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        autoGraphMinter.mintBatchWithPaymentTokenAsFee(erc1155Wearables, address(this), address(token), params);
    }

    function testMintBatchWithPaymentTokenAsFeeWithExpiredJob() public {
        uint256 testItems = 10;
        uint256 paymentAmountPerMint = 10_000;
        uint256 totalCost = testItems * paymentAmountPerMint;
        ERC1155AutoGraphMinter.MintBatchParams[] memory params = Helper.setupTxs(
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

        token.mint(address(this), totalCost);
        token.approve(address(autoGraphMinter), totalCost);

        // mint
        autoGraphMinter.mintBatchWithPaymentTokenAsFee(erc1155Consumables, address(this), address(token), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(token.balanceOf(autoGraphMinter.paymentRecipient()), totalCost, "Payment token balance incorrect");

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
        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintBatchWithPaymentTokenAsFee(erc1155Consumables, address(this), address(token), params);

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

        token.mint(address(this), totalCost);
        token.approve(address(autoGraphMinter), totalCost);

        // mint
        autoGraphMinter.mintBatchWithPaymentTokenAsFee(erc1155Placeables, address(this), address(token), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(token.balanceOf(autoGraphMinter.paymentRecipient()), runningTotal, "Payment token balance incorrect");

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
        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintBatchWithPaymentTokenAsFee(erc1155Placeables, address(this), address(token), params);

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

        token.mint(address(this), totalCost);
        token.approve(address(autoGraphMinter), totalCost);

        // mint
        autoGraphMinter.mintBatchWithPaymentTokenAsFee(erc1155Wearables, address(this), address(token), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(token.balanceOf(autoGraphMinter.paymentRecipient()), runningTotal, "Payment token balance incorrect");

        params = Helper.setupTxs(
            vm,
            _privateKey,
            ERC1155MaxSupplyMintable(erc1155Wearables),
            10,
            addresses.getAddress("ADMIN_MULTISIG"),
            testItems,
            address(token),
            paymentAmountPerMint,
            block.timestamp - 100
        );
        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintBatchWithPaymentTokenAsFee(erc1155Wearables, address(this), address(token), params);
    }

    function testMintBatchWithEthAsFeeWithExpiredHash() public {
        uint256 testItems = 10;
        uint256 paymentAmountPerMint = 10_000;
        uint256 totalCost = testItems * paymentAmountPerMint;
        ERC1155AutoGraphMinter.MintBatchParams[] memory params = Helper.setupTxs(
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
        autoGraphMinter.mintBatchWithEthAsFee{value: totalCost}(erc1155Consumables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(autoGraphMinter.paymentRecipient().balance, totalCost);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        autoGraphMinter.mintBatchWithEthAsFee{value: totalCost}(erc1155Consumables, address(this), params);

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
        autoGraphMinter.mintBatchWithEthAsFee{value: totalCost}(erc1155Placeables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(autoGraphMinter.paymentRecipient().balance, runningTotal);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        autoGraphMinter.mintBatchWithEthAsFee{value: totalCost}(erc1155Placeables, address(this), params);

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
        autoGraphMinter.mintBatchWithEthAsFee{value: totalCost}(erc1155Wearables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(autoGraphMinter.paymentRecipient().balance, runningTotal);

        vm.expectRevert("ERC1155AutoGraphMinter: Hash expired");
        autoGraphMinter.mintBatchWithEthAsFee{value: totalCost}(erc1155Wearables, address(this), params);
    }

    function testMintBatchWithEthAsFeeWithExpiredJob() public {
        uint256 testItems = 10;
        uint256 paymentAmountPerMint = 10_000;
        uint256 totalCost = testItems * paymentAmountPerMint;
        ERC1155AutoGraphMinter.MintBatchParams[] memory params = Helper.setupTxs(
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
        autoGraphMinter.mintBatchWithEthAsFee{value: totalCost}(erc1155Consumables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Consumables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(autoGraphMinter.paymentRecipient().balance, totalCost);

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
        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintBatchWithEthAsFee{value: totalCost}(erc1155Consumables, address(this), params);

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
        autoGraphMinter.mintBatchWithEthAsFee{value: totalCost}(erc1155Placeables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Placeables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(autoGraphMinter.paymentRecipient().balance, runningTotal);

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
        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintBatchWithEthAsFee{value: totalCost}(erc1155Placeables, address(this), params);

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
        autoGraphMinter.mintBatchWithEthAsFee{value: totalCost}(erc1155Wearables, address(this), params);

        // assert balance
        for (uint256 i = 0; i < params.length; i++) {
            assertEq(ERC1155MaxSupplyMintable(erc1155Wearables).balanceOf(address(this), i), testItems);
        }

        // assert token balance payment
        assertEq(autoGraphMinter.paymentRecipient().balance, runningTotal);

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
        vm.expectRevert("ERC1155AutoGraphMinter: Job expired");
        autoGraphMinter.mintBatchWithEthAsFee{value: totalCost}(erc1155Wearables, address(this), params);
    }
}
