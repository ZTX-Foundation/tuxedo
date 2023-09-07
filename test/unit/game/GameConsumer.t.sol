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

    /// @notice event emitted when fast crafting happens
    event FastCraft(uint256 indexed tokenId, uint256 indexed jobId, uint256 amountPaid, uint256 amountToMint);

    /// @notice event emitted when in game boost happens
    event InGameBoost(uint256 indexed jobId, uint256 amount);

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
        uint256 jobFee;
        uint256 tokenAmount;
        address paymentToken;
    }

    function setupTx(address paymentToken) public view returns (uint256, uint256, uint256, bytes32, bytes memory) {
        CraftTxBuilder memory builder = CraftTxBuilder({jobFee: 1e18, tokenAmount: 100, paymentToken: paymentToken});

        return setupFastCraftTx(builder);
    }

    /// @dev setup a happy path tx for fastCraft
    function setupFastCraftTx(
        CraftTxBuilder memory builder
    ) public view virtual returns (uint256, uint256, uint256, bytes32, bytes memory) {
        uint256 expireTimestamp = block.timestamp + 5 minutes;
        uint256 salt = uint256(keccak256(abi.encode(block.timestamp)));
        uint256 jobId = uint256(keccak256(abi.encode(keccak256(abi.encode(salt)))));

        // hash message
        bytes32 hash = gameConsumer.getHashFastCraft(
            tokenId,
            builder.paymentToken,
            builder.tokenAmount,
            jobId,
            builder.jobFee,
            expireTimestamp,
            salt
        );

        // sign hash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);

        // encode signature
        bytes memory sig = abi.encodePacked(r, s, v);

        return (expireTimestamp, salt, jobId, hash, sig);
    }

    function setupInGameBoostTx(
        address paymentToken
    ) public view returns (uint256, uint256, uint256, bytes32, bytes memory) {
        CraftTxBuilder memory builder = CraftTxBuilder({jobFee: 1e18, tokenAmount: 100, paymentToken: paymentToken});

        return setupInGameBoostTx(builder);
    }

    function setupInGameBoostTx(
        CraftTxBuilder memory builder
    ) public view returns (uint256 jobId, uint256 quoteExpiry, uint256 salt, bytes32 hash, bytes memory sig) {
        quoteExpiry = block.timestamp + 5 minutes;
        salt = uint256(keccak256(abi.encode(block.timestamp)));
        jobId = uint256(keccak256(abi.encode(keccak256(abi.encode(salt)))));

        hash = gameConsumer.getHashInGameBoost(jobId, builder.paymentToken, builder.jobFee, quoteExpiry, salt);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);
        sig = abi.encodePacked(r, s, v);
    }

    function testFastCraft() public {
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(
            address(token)
        );
        token.mint(address(this), 1e18);
        token.approve(address(gameConsumer), 1e18);

        vm.expectEmit(true, true, false, true, address(gameConsumer));
        emit FastCraft(tokenId, jobId, 1e18, 100);

        gameConsumer.fastCraft(tokenId, 100, address(token), jobId, 1e18, expiryTimestamp, hash, salt, sig);

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(gameConsumer)), 1e18);
        assertTrue(gameConsumer.usedHashes(hash));
    }

    function testFastCraftFailsHashReplay() public {
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(
            address(token)
        );
        token.mint(address(this), 1e18);
        token.approve(address(gameConsumer), 1e18);

        vm.expectEmit(true, true, false, true, address(gameConsumer));
        emit FastCraft(tokenId, jobId, 1e18, 100);

        gameConsumer.fastCraft(tokenId, 100, address(token), jobId, 1e18, expiryTimestamp, hash, salt, sig);

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(gameConsumer)), 1e18);

        vm.expectRevert("GameConsumer: hash already used");
        gameConsumer.fastCraft(tokenId, 100, address(token), jobId, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testFastCraftFailsInvalidInputs0() public {
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(
            address(token)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.fastCraft(tokenId + 1, 100, address(token), jobId, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testFastCraftFailsInvalidInputs1() public {
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(
            address(token)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.fastCraft(tokenId, 101, address(token), jobId, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testFastCraftFailsInvalidInputs2() public {
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(
            address(token)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.fastCraft(tokenId, 100, address(weth), jobId, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testFastCraftFailsInvalidInputs3() public {
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(
            address(token)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.fastCraft(tokenId, 100, address(token), jobId + 1, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testFastCraftFailsInvalidInputs4() public {
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(
            address(token)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.fastCraft(tokenId, 100, address(token), jobId, 1e18 + 1, expiryTimestamp, hash, salt, sig);
    }

    function testFastCraftFailsInvalidInputs5() public {
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(
            address(token)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.fastCraft(tokenId, 100, address(token), jobId, 1e18, expiryTimestamp + 1, hash, salt, sig);
    }

    function testFastCraftFailsInvalidInputs6() public {
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(
            address(token)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.fastCraft(
            tokenId,
            100,
            address(token),
            jobId,
            1e18,
            expiryTimestamp,
            keccak256(abi.encode(hash)),
            salt,
            sig
        );
    }

    function testFastCraftFailsInvalidInputs7() public {
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(
            address(token)
        );

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.fastCraft(tokenId, 100, address(token), jobId, 1e18, expiryTimestamp, hash, salt + 1, sig);
    }

    function testFastCraftFailsQuoteExpired() public {
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(
            address(token)
        );

        vm.warp(expiryTimestamp + 1);
        vm.expectRevert("GameConsumer: timestamp expired");
        gameConsumer.fastCraft(tokenId, 100, address(token), jobId, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testFastCraftFailsSignerNotOracle() public {
        vm.prank(addresses.adminAddress);
        core.revokeRole(Roles.GAME_CONSUMER_NOTARY, notary);

        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(
            address(token)
        );

        vm.expectRevert("GameConsumer: Missing GAME_CONSUMER_NOTARY Role");
        gameConsumer.fastCraft(tokenId, 100, address(token), jobId, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testFastCraftWithEth() public {
        vm.deal(address(this), 1e18);
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(address(weth));

        vm.expectEmit(true, true, false, true, address(gameConsumer));
        emit FastCraft(tokenId, jobId, 1e18, 100);

        gameConsumer.fastCraftWithEth{value: 1e18}(tokenId, 100, jobId, 1e18, expiryTimestamp, hash, salt, sig);

        assertEq(address(this).balance, 0);
        assertEq(address(gameConsumer).balance, 1e18);
    }

    function testFastCraftWithEthFailsHashReplay() public {
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(address(weth));

        vm.expectEmit(true, true, false, true, address(gameConsumer));
        emit FastCraft(tokenId, jobId, 1e18, 100);
        vm.deal(address(this), 1e18);

        gameConsumer.fastCraftWithEth{value: 1e18}(tokenId, 100, jobId, 1e18, expiryTimestamp, hash, salt, sig);

        assertEq(address(this).balance, 0);
        assertEq(address(gameConsumer).balance, 1e18);
        vm.deal(address(this), 1e18);

        vm.expectRevert("GameConsumer: hash already used");
        gameConsumer.fastCraftWithEth{value: 1e18}(tokenId, 100, jobId, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testFastCraftWithEthFailsInvalidInputs0() public {
        vm.deal(address(this), 1e18);
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(address(weth));

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.fastCraftWithEth{value: 1e18}(tokenId + 1, 100, jobId, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testFastCraftWithEthFailsInvalidInputs1() public {
        vm.deal(address(this), 1e18);
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(address(weth));

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.fastCraftWithEth{value: 1e18}(tokenId, 101, jobId, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testFastCraftWithEthFailsInvalidInputs3() public {
        vm.deal(address(this), 1e18);
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(address(weth));

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.fastCraftWithEth{value: 1e18}(tokenId, 100, jobId + 1, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testFastCraftWithEthFailsInvalidInputs4() public {
        vm.deal(address(this), 1e18 + 1);
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(address(weth));

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.fastCraftWithEth{value: 1e18 + 1}(tokenId, 100, jobId, 1e18 + 1, expiryTimestamp, hash, salt, sig);
    }

    function testFastCraftWithEthFailsInvalidInputs5() public {
        vm.deal(address(this), 1e18);
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(address(weth));

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.fastCraftWithEth{value: 1e18}(tokenId, 100, jobId, 1e18, expiryTimestamp + 1, hash, salt, sig);
    }

    function testFastCraftWithEthFailsInvalidInputs6() public {
        vm.deal(address(this), 1e18);
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(address(weth));

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.fastCraftWithEth{value: 1e18}(
            tokenId,
            100,
            jobId,
            1e18,
            expiryTimestamp,
            keccak256(abi.encode(hash)),
            salt,
            sig
        );
    }

    function testFastCraftWithEthFailsInvalidInputs7() public {
        vm.deal(address(this), 1e18);
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(address(weth));

        vm.expectRevert("GameConsumer: hash mismatch");
        gameConsumer.fastCraftWithEth{value: 1e18}(tokenId, 100, jobId, 1e18, expiryTimestamp, hash, salt + 1, sig);
    }

    function testFastCraftWithEthFailsQuoteExpired() public {
        vm.deal(address(this), 1e18);
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(address(weth));

        vm.warp(expiryTimestamp + 1);
        vm.expectRevert("GameConsumer: timestamp expired");
        gameConsumer.fastCraftWithEth{value: 1e18}(tokenId, 100, jobId, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testFastCraftWithEthFailsSignerNotOracle() public {
        vm.deal(address(this), 1e18);
        vm.prank(addresses.adminAddress);
        core.revokeRole(Roles.GAME_CONSUMER_NOTARY, notary);

        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(address(weth));

        vm.expectRevert("GameConsumer: Missing GAME_CONSUMER_NOTARY Role");
        gameConsumer.fastCraftWithEth{value: 1e18}(tokenId, 100, jobId, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testFastCraftWithEthFailsIncorrectEthAmount() public {
        vm.deal(address(this), 1e18);

        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(address(weth));

        vm.expectRevert("GameConsumer: incorrect job fee");
        gameConsumer.fastCraftWithEth{value: 1e18 - 1}(tokenId, 100, jobId, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testInGameBoostWithEth() public {
        (uint256 jobId, uint256 quoteExpiry, uint256 salt, bytes32 hash, bytes memory sig) = setupInGameBoostTx(
            address(weth)
        );
        vm.deal(address(this), 1e18);

        vm.expectEmit(true, true, false, true, address(gameConsumer));
        emit InGameBoost(jobId, 1e18);

        gameConsumer.inGameBoostWithEth{value: 1e18}(jobId, 1e18, quoteExpiry, hash, salt, sig);

        assertEq(address(this).balance, 0);
        assertEq(address(gameConsumer).balance, 1e18);
        assertTrue(gameConsumer.usedHashes(hash));
    }

    function testInGameBoostWithEthFailsAmountMismatch() public {
        (uint256 jobId, uint256 quoteExpiry, uint256 salt, bytes32 hash, bytes memory sig) = setupInGameBoostTx(
            address(weth)
        );
        vm.deal(address(this), 1e18 + 1);

        vm.expectRevert("GameConsumer: incorrect job fee");

        gameConsumer.inGameBoostWithEth{value: 1e18 + 1}(jobId, 1e18, quoteExpiry, hash, salt, sig);
    }

    function testInGameBoostWithTokens() public {
        (uint256 jobId, uint256 quoteExpiry, uint256 salt, bytes32 hash, bytes memory sig) = setupInGameBoostTx(
            address(token)
        );

        token.mint(address(this), 1e18);
        token.approve(address(gameConsumer), 1e18);

        vm.expectEmit(true, true, false, true, address(gameConsumer));
        emit InGameBoost(jobId, 1e18);

        gameConsumer.inGameBoost(jobId, 1e18, address(token), quoteExpiry, hash, salt, sig);

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(gameConsumer)), 1e18);
        assertTrue(gameConsumer.usedHashes(hash));
    }

    function testAllBoostActionsFailPaused() public {
        (uint256 jobId, uint256 quoteExpiry, uint256 salt, bytes32 hash, bytes memory sig) = setupInGameBoostTx(
            address(weth)
        );
        vm.deal(address(this), 1e18);

        vm.prank(addresses.adminAddress);
        gameConsumer.pause();

        vm.expectRevert("Pausable: paused");
        gameConsumer.inGameBoostWithEth{value: 1e18}(jobId, 1e18, quoteExpiry, hash, salt, sig);

        vm.expectRevert("Pausable: paused");
        gameConsumer.inGameBoost(jobId, 1e18, address(token), quoteExpiry, hash, salt, sig);
    }

    function testAllFastCraftsFailPaused() public {
        (uint256 expiryTimestamp, uint256 salt, uint256 jobId, bytes32 hash, bytes memory sig) = setupTx(
            address(token)
        );

        vm.prank(addresses.adminAddress);
        gameConsumer.pause();

        vm.expectRevert("Pausable: paused");
        gameConsumer.fastCraft(tokenId, 100, address(token), jobId, 1e18, expiryTimestamp, hash, salt, sig);

        vm.deal(address(this), 1e18);
        vm.expectRevert("Pausable: paused");
        gameConsumer.fastCraftWithEth{value: 1e18}(tokenId, 100, jobId, 1e18, expiryTimestamp, hash, salt, sig);
    }

    function testWrapEth() public {
        vm.deal(address(gameConsumer), 1e18);

        vm.prank(addresses.adminAddress);
        gameConsumer.wrapEth();

        assertEq(address(weth).balance, 1e18);
        assertEq(address(gameConsumer).balance, 0);
    }

    function testSweepWeth() public {
        testWrapEth();
        uint256 wethBalance = weth.balanceOf(address(gameConsumer));

        vm.prank(addresses.adminAddress);
        gameConsumer.sweepUnclaimedWeth();

        assertEq(weth.balanceOf(address(gameConsumer)), 0);
        assertEq(weth.balanceOf(gameConsumer.proceedsRecipient()), wethBalance);
    }

    function testSweepToken() public {
        testInGameBoostWithTokens();
        uint256 wethBalance = token.balanceOf(address(gameConsumer));

        vm.prank(addresses.adminAddress);
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
