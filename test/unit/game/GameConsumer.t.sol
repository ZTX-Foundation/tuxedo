pragma solidity 0.8.18;

import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {BaseTest} from "@test/BaseTest.sol";
import {GameConsumer} from "@protocol/game/GameConsumer.sol";

contract GameConsumerUnitTest is BaseTest {
    GameConsumer public gameConsumer;

    uint256 public privateKey;
    uint256 public nonOraclePrivateKey;
    address public notary;

    /// @notice event emitted when in payment is taken
    event TakePayment(uint256 indexed jobId, uint256 amount);

    function setUp() public override {
        super.setUp();

        string memory mnemonic = "test test test test test test test test test test test junk";
        privateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/1/", 0);
        nonOraclePrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/1/", 1);
        notary = vm.addr(privateKey);

        vm.prank(addresses.adminAddress);
        core.grantRole(Roles.GAME_CONSUMER_NOTARY, notary);

        gameConsumer = new GameConsumer(address(core), address(token), address(this), address(weth));
    }

    function testSetup() public {
        assertEq(address(gameConsumer.core()), address(core));
        assertEq(address(gameConsumer.token()), address(token));
        assertEq(address(gameConsumer.weth()), address(weth));
        assertEq(address(gameConsumer.proceedsRecipient()), address(this));
    }

    struct CraftTxBuilder {
        address payer;
        uint256 jobFee;
        uint256 tokenAmount;
        address paymentToken;
    }

    function setupTakePaymentTx(
        address paymentToken
    ) public view returns (address, uint256, uint256, uint256, bytes32, bytes memory) {
        CraftTxBuilder memory builder = CraftTxBuilder({payer: address(this), jobFee: 1e18, tokenAmount: 100, paymentToken: paymentToken});

        return setupTakePaymentTx(builder);
    }

    function setupTakePaymentTx(
        CraftTxBuilder memory builder
    ) public view returns (address payer, uint256 jobId, uint256 quoteExpiry, uint256 salt, bytes32 hash, bytes memory sig) {
        payer = address(this);
        quoteExpiry = block.timestamp + 5 minutes;
        salt = uint256(keccak256(abi.encode(block.timestamp)));
        jobId = uint256(keccak256(abi.encode(keccak256(abi.encode(salt)))));

        hash = gameConsumer.getHash(jobId, builder.paymentToken, builder.jobFee, quoteExpiry, salt);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);
        sig = abi.encodePacked(r, s, v);
    }

    function testTakePayment() public {
        (address payer, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(token)
        );
        token.mint(address(this), 1e18);
        token.approve(address(gameConsumer), 1e18);

        vm.expectEmit(true, true, false, true, address(gameConsumer));
        emit TakePayment(jobId, 1e18);

        gameConsumer.takePayment(payer, jobId, 1e18, address(token), expiryTimestamp, hash, salt, sig);

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(gameConsumer)), 1e18);
        assertTrue(gameConsumer.usedHashes(hash));
    }

    function testTakePaymentFailsHashReplay() public {
        (address payer, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(token)
        );
        token.mint(address(this), 1e18);
        token.approve(address(gameConsumer), 1e18);

        vm.expectEmit(true, true, false, true, address(gameConsumer));
        emit TakePayment(jobId, 1e18);

        gameConsumer.takePayment(payer, jobId, 1e18, address(token), expiryTimestamp, hash, salt, sig);

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(gameConsumer)), 1e18);

        vm.expectRevert("GameConsumer: hash already used");
        gameConsumer.takePayment(payer, jobId, 1e18, address(token), expiryTimestamp, hash, salt, sig);
    }

    function testTakePaymentFailsInvalidInputs0() public {
        (address payer, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(token)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.takePayment(payer, jobId + 1, 1e18, address(token), expiryTimestamp, hash, salt, sig);
    }

    function testTakePaymentFailsInvalidInputs1() public {
        (address payer, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(token)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.takePayment(payer, jobId, 2e18, address(token), expiryTimestamp, hash, salt, sig);
    }

    function testTakePaymentFailsInvalidInputs2() public {
        (address payer, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(token)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.takePayment(payer, jobId, 1e18, address(weth), expiryTimestamp, hash, salt, sig);
    }

    function testTakePaymentFailsInvalidInputs3() public {
        (address payer, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(token)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.takePayment(payer, jobId, 1e18, address(token), expiryTimestamp + 1 hours, hash, salt, sig);
    }

    function testTakePaymentFailsInvalidInputs4() public {
        (address payer, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(token)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.takePayment(payer, jobId, 1e18, address(token), expiryTimestamp, keccak256(abi.encode(hash)), salt, sig);
    }

    function testTakePaymentFailsInvalidInputs5() public {
        (address payer, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(token)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.takePayment(payer, jobId, 1e18, address(token), expiryTimestamp, hash, salt + 1, sig);
    }

    function testTakePaymentFailsQuoteExpired() public {
        (address payer, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(token)
        );

        vm.warp(expiryTimestamp + 1);
        vm.expectRevert("GameConsumer: timestamp expired");
        gameConsumer.takePayment(payer, jobId, 1e18, address(token), expiryTimestamp, hash, salt, sig);
    }

    function testTakePaymentFailsSignerNotOracle() public {
        vm.prank(addresses.adminAddress);
        core.revokeRole(Roles.GAME_CONSUMER_NOTARY, notary);

        (address payer, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(token)
        );

        vm.expectRevert("GameConsumer: Missing GAME_CONSUMER_NOTARY Role");
        gameConsumer.takePayment(payer, jobId, 1e18, address(token), expiryTimestamp, hash, salt, sig);
    }

    function testTakePaymentWithEth() public {
        vm.deal(address(this), 1e18);
        (, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(weth)
        );

        vm.expectEmit(true, true, false, true, address(gameConsumer));
        emit TakePayment(jobId, 1e18);

        gameConsumer.takePaymentWithEth{value: 1e18}(jobId, 1e18, expiryTimestamp, hash, salt, sig);

        assertEq(address(this).balance, 0);
        assertEq(address(gameConsumer).balance, 1e18);
    }

    function testTakePaymentWithEthFailsHashReplay() public {
        (, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(weth)
        );

        vm.expectEmit(true, true, false, true, address(gameConsumer));
        emit TakePayment(jobId, 1e18);
        vm.deal(address(this), 1e18);

        gameConsumer.takePaymentWithEth{value: 1e18}(jobId, 1e18, expiryTimestamp, hash, salt, sig);

        assertEq(address(this).balance, 0);
        assertEq(address(gameConsumer).balance, 1e18);
        vm.deal(address(this), 1e18);

        vm.expectRevert("GameConsumer: hash already used");
        gameConsumer.takePaymentWithEth{value: 1e18}(jobId, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testTakePaymentWithEthFailsInvalidInputs0() public {
        (, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(weth)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.takePaymentWithEth{value: 1e18}(jobId + 1, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testTakePaymentWithEthFailsInvalidInputs1() public {
        (, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(weth)
        );

        vm.expectRevert("GameConsumer: incorrect job fee");
        gameConsumer.takePaymentWithEth{value: 1e18}(jobId, 1e18 + 1, expiryTimestamp, hash, salt, sig);
    }

    function testTakePaymentWithEthFailsInvalidInputs2() public {
        (, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(weth)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.takePaymentWithEth{value: 1e18}(jobId, 1e18, expiryTimestamp + 1 hours, hash, salt, sig);
    }

    function testTakePaymentWithEthFailsInvalidInputs3() public {
        (, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(weth)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.takePaymentWithEth{value: 1e18}(jobId, 1e18, expiryTimestamp, keccak256(abi.encode(hash)), salt, sig);
    }

    function testTakePaymentWithEthFailsInvalidInputs4() public {
        (, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(weth)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.takePaymentWithEth{value: 1e18}(jobId, 1e18, expiryTimestamp, hash, salt + 1, sig);
    }

    function testTakePaymentWithEthFailsQuoteExpired() public {
        vm.deal(address(this), 1e18);
        (, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(weth)
        );

        vm.warp(expiryTimestamp + 1);
        vm.expectRevert("GameConsumer: timestamp expired");
        gameConsumer.takePaymentWithEth{value: 1e18}(jobId, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testTakePaymentWithEthFailsSignerNotOracle() public {
        vm.deal(address(this), 1e18);
        vm.prank(addresses.adminAddress);
        core.revokeRole(Roles.GAME_CONSUMER_NOTARY, notary);

        (, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(weth)
        );

        vm.expectRevert("GameConsumer: Missing GAME_CONSUMER_NOTARY Role");
        gameConsumer.takePaymentWithEth{value: 1e18}(jobId, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testTakePaymentWithEthFailsIncorrectEthAmount() public {
        vm.deal(address(this), 1e18);

        (, uint256 jobId, uint256 expiryTimestamp, uint256 salt, bytes32 hash, bytes memory sig) = setupTakePaymentTx(
            address(weth)
        );

        vm.expectRevert("GameConsumer: incorrect job fee");
        gameConsumer.takePaymentWithEth{value: 1e18 - 1}(jobId, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testWrapEth() public {
        vm.deal(address(gameConsumer), 1e18);

        gameConsumer.wrapEth();

        assertEq(address(weth).balance, 1e18);
        assertEq(address(gameConsumer).balance, 0);
    }

    function testSweepWeth() public {
        testWrapEth();
        uint256 wethBalance = weth.balanceOf(address(gameConsumer));

        gameConsumer.sweepUnclaimedWeth();

        assertEq(weth.balanceOf(address(gameConsumer)), 0);
        assertEq(weth.balanceOf(gameConsumer.proceedsRecipient()), wethBalance);
    }

    function testSweepToken() public {
        testTakePayment();
        uint256 wethBalance = token.balanceOf(address(gameConsumer));

        gameConsumer.sweepUnclaimed();

        assertEq(token.balanceOf(address(gameConsumer)), 0);
        assertEq(token.balanceOf(gameConsumer.proceedsRecipient()), wethBalance);
    }

    function testSweepEth() public {
        testTakePaymentWithEth();
        uint256 wethBalance = token.balanceOf(address(gameConsumer));

        gameConsumer.sweepUnclaimed();

        assertEq(token.balanceOf(address(gameConsumer)), 0);
        assertEq(token.balanceOf(gameConsumer.proceedsRecipient()), wethBalance);
    }

    /// ACL tests

    function testSetProceedsCollectorNonAdminFails() public {
        vm.expectRevert("CoreRef: no role on core");
        gameConsumer.setProceedsCollector(address(this));
    }

    function testSetProceedsCollectorAdminSucceeds() public {
        vm.prank(addresses.adminAddress);
        gameConsumer.setProceedsCollector(address(1));

        assertEq(address(gameConsumer.proceedsRecipient()), address(1));
    }
}
