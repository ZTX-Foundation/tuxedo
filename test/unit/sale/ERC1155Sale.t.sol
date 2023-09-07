pragma solidity 0.8.18;

import "@forge-std/Test.sol";

import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {BaseTest} from "@test/BaseTest.sol";
import {MockERC20} from "@test/mock/MockERC20.sol";
import {Constants} from "@protocol/Constants.sol";
import {ERC1155Sale} from "@protocol/sale/ERC1155Sale.sol";
import {ERC20Splitter} from "@protocol/finance/ERC20Splitter.sol";
import {FinanceGuardian} from "@protocol/finance/FinanceGuardian.sol";
import {MockERC20, IERC20} from "@test/mock/MockERC20.sol";
import {GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {TestAddresses as addresses} from "@test/fixtures/TestAddresses.sol";
import {getSystem, configureSale, setSupplyCap} from "@test/fixtures/Fixtures.sol";
import {MerkleProof} from "@test/fixtures/MerkleProof.sol";

contract UnitTestERC1155Sale is BaseTest {
    MerkleProof public proof;
    bytes32[] public userProof;
    bytes32[] public beneficiaryOneProof;
    bytes32 public root;
    bytes32[][] public proofArrays;

    function setUp() public virtual override {
        super.setUp();
        proof = new MerkleProof();
        root = proof.root();

        userProof.push(proof.userOneProof(0));
        userProof.push(proof.userOneProof(1));
        userProof.push(proof.userOneProof(2));
        userProof.push(proof.userOneProof(3));

        beneficiaryOneProof.push(proof.beneficiaryOneProof(0));
        beneficiaryOneProof.push(proof.beneficiaryOneProof(1));
        beneficiaryOneProof.push(proof.beneficiaryOneProof(2));
        beneficiaryOneProof.push(proof.beneficiaryOneProof(3));
    }

    function testSetup() public {
        assertEq(address(sale.nft()), address(nft));
        assertEq(address(sale.core()), address(core));
        assertEq(address(core.lock()), address(lock));
        assertEq(address(lock.core()), address(core));
        assertEq(address(guardian.core()), address(core));

        (address tokenPricedIn, , uint240 price, uint16 _fee, bool overrideRoot, bytes32 merkleRoot) = sale
            .getTokenInfo(tokenId);

        assertEq(tokenPricedIn, address(token));
        assertEq(price, tokenPrice);
        assertEq(fee, _fee);
        assertEq(root, merkleRoot);
        assertTrue(!overrideRoot);

        (address _proceedsRecipient, address _feeRecipient, uint128 _unclaimedProceeds, uint128 _unclaimedFees) = sale
            .getTokenRecipientsAndUnclaimed(address(token));
        assertEq(_proceedsRecipient, proceedsRecipient);
        assertEq(_feeRecipient, feeRecipient);
        assertEq(_unclaimedProceeds, 0);
        assertEq(_unclaimedFees, 0);

        assertEq(nft.maxTokenSupply(tokenId), supplyCap);
    }

    /// PAUSE TESTS

    function testBuyTokenWithEthFailsPaused() public {
        vm.prank(addresses.adminAddress);
        sale.pause();

        vm.expectRevert("Pausable: paused");
        sale.buyTokenWithEth{value: 1}(tokenId, 100, 100, userProof, addresses.userAddress);
    }

    function testBuyTokensWithEthFailsPaused() public {
        vm.prank(addresses.adminAddress);
        sale.pause();

        vm.expectRevert("Pausable: paused");
        sale.buyTokensWithEth{value: 1}(
            new uint256[](0),
            new uint256[](0),
            new uint256[](0),
            proofArrays,
            addresses.userAddress
        );
    }

    function testBuyTokenFailsPaused() public {
        vm.prank(addresses.adminAddress);
        sale.pause();

        vm.expectRevert("Pausable: paused");
        sale.buyToken(tokenId, 100, 100, userProof, addresses.userAddress);
    }

    function testBuyTokensFailsPaused() public {
        vm.prank(addresses.adminAddress);
        sale.pause();

        vm.expectRevert("Pausable: paused");
        sale.buyTokens(new uint256[](0), new uint256[](0), new uint256[](0), proofArrays, addresses.userAddress);
    }

    /// ACL TESTS

    function testNonAdminSetsTokenRecipientsFails(address user) public {
        vm.assume(user != addresses.adminAddress);
        vm.prank(user);
        vm.expectRevert("CoreRef: no role on core");
        sale.setTokenRecipients(address(token), proceedsRecipient, feeRecipient);
    }

    function testNonAdminSetsTokenConfigFails(address user) public {
        vm.assume(user != addresses.adminAddress && user != addresses.tokenGovernorAddress);
        vm.prank(user);
        vm.expectRevert("CoreRef: no role on core");
        sale.setTokenConfig(tokenId, address(token), uint96(block.timestamp + 1), tokenPrice, fee, false, bytes32(0));
    }

    function testBuyZeroTokenFails() public {
        vm.expectRevert("ERC1155Sale: no token out");
        vm.prank(addresses.userAddress);
        sale.buyToken(tokenId, 0, 100, userProof, address(0));
    }

    function testBuyTokenProceedsRecipientInvalid() public {
        vm.prank(addresses.adminAddress);
        sale.setTokenRecipients(address(token), address(0), feeRecipient);

        vm.prank(addresses.userAddress);
        vm.expectRevert("ERC1155Sale: no recipient set");
        sale.buyToken(tokenId, 0, 100, userProof, address(0));
    }

    function testBuyTokenFeeRecipientInvalid() public {
        vm.prank(addresses.adminAddress);
        sale.setTokenRecipients(address(token), proceedsRecipient, address(0));

        vm.prank(addresses.userAddress);
        vm.expectRevert("ERC1155Sale: no fee recipient set");
        sale.buyToken(tokenId, 0, 100, userProof, address(0));
    }

    function testBuyTokensFailInvalidProof() public {
        vm.prank(addresses.userAddress);
        vm.expectRevert("ERC1155Sale: invalid proof");
        sale.buyToken(tokenId, 0, 100, beneficiaryOneProof, address(0));
    }

    function testBuyTokensWithEthFailInvalidProof() public {
        vm.prank(addresses.userAddress);
        vm.expectRevert("ERC1155Sale: invalid proof");
        sale.buyTokenWithEth(tokenId, 0, 100, beneficiaryOneProof, address(0));
    }

    function testBuyTokensFailEmptyProof() public {
        bytes32[] memory emptyProof = new bytes32[](0);
        vm.prank(addresses.userAddress);
        vm.expectRevert("ERC1155Sale: invalid proof");
        sale.buyToken(tokenId, 0, 100, emptyProof, address(0));
    }

    function testSetTokenConfigStartTimePresentFails() public {
        vm.prank(addresses.adminAddress);
        vm.expectRevert("ERC1155Sale: sale must start in the future");
        sale.setTokenConfig(tokenId, address(token), uint96(block.timestamp), tokenPrice, fee, false, bytes32(0));
    }

    function testPurchaseTokensNoProofSucceedsProofOverriden(uint8 amount) public {
        vm.prank(addresses.adminAddress);
        /// set proof to 0 and override the root
        sale.setTokenConfig(tokenId, address(token), uint96(block.timestamp + 1), tokenPrice, fee, true, bytes32(0));

        (, , , , bool overriden, bytes32 newRoot) = sale.getTokenInfo(tokenId);

        assertEq(newRoot, bytes32(0));
        assertTrue(overriden);

        vm.warp(block.timestamp + 1); /// start the sale
        testPurchaseTokens(amount);
    }

    function testSetupWeth() public {
        vm.startPrank(addresses.adminAddress);
        sale.setTokenConfig(tokenId, address(weth), uint96(block.timestamp + 1), tokenPrice, fee, true, root);
        sale.setTokenRecipients(address(weth), proceedsRecipient, feeRecipient);
        vm.stopPrank();

        (address tokenPricedIn, , uint240 price, uint16 _fee, bool overrideRoot, bytes32 merkleRoot) = sale
            .getTokenInfo(tokenId);

        assertEq(tokenPricedIn, address(weth));
        assertEq(price, tokenPrice);
        assertEq(fee, _fee);
        assertEq(root, merkleRoot);
        assertTrue(overrideRoot);
    }

    function _setupWeth() private {
        vm.startPrank(addresses.adminAddress);

        sale.setTokenConfig(1, address(weth), uint96(block.timestamp + 1), tokenPrice, fee, true, root);
        sale.setTokenConfig(2, address(weth), uint96(block.timestamp + 1), tokenPrice, fee, true, root);
        sale.setTokenConfig(3, address(weth), uint96(block.timestamp + 1), tokenPrice, fee, true, root);
        sale.setTokenRecipients(address(weth), proceedsRecipient, feeRecipient);

        nft.setSupplyCap(1, supplyCap);
        nft.setSupplyCap(2, supplyCap);
        nft.setSupplyCap(3, supplyCap);

        vm.stopPrank();
    }

    function testBulkPurchaseWithEth() public {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        uint256[] memory tokenAmounts = new uint256[](3);
        tokenAmounts[0] = supplyCap;
        tokenAmounts[1] = supplyCap;
        tokenAmounts[2] = supplyCap;

        bytes32[] memory emptyProof = new bytes32[](0);

        /// values not checked because merkle root is overriden
        proofArrays.push(emptyProof);
        proofArrays.push(emptyProof);
        proofArrays.push(emptyProof);

        _setupWeth();

        vm.warp(block.timestamp + 1); /// kick off sale

        uint256 ethAmount = sale.getBulkPurchaseTotal(tokenIds, tokenAmounts);

        vm.deal(addresses.userAddress, ethAmount);

        vm.prank(addresses.userAddress);
        assertEq(
            sale.buyTokensWithEth{value: ethAmount}(
                tokenIds,
                tokenAmounts,
                tokenAmounts,
                proofArrays,
                addresses.userAddress
            ),
            ethAmount
        );

        assertEq(supplyCap, nft.balanceOf(addresses.userAddress, 1));
        assertEq(supplyCap, nft.balanceOf(addresses.userAddress, 2));
        assertEq(supplyCap, nft.balanceOf(addresses.userAddress, 3));

        assertEq(0, sale.getMaxMintAmountOut(1));
        assertEq(0, sale.getMaxMintAmountOut(2));
        assertEq(0, sale.getMaxMintAmountOut(3));

        assertEq(address(sale).balance, ethAmount);
        assertEq(addresses.userAddress.balance, 0);
    }

    function testBuyWithEthFailsUnderlyingNotWeth() public {
        (uint256 cost, , ) = sale.getPurchasePrice(tokenId, 100);
        vm.deal(addresses.userAddress, cost);
        vm.prank(addresses.userAddress);
        vm.expectRevert("ERC1155Sale: purchase token token must be weth");
        sale.buyTokenWithEth{value: cost}(tokenId, 100, 100, userProof, addresses.userAddress);
    }

    function testBuysWithEthFailsUnderlyingNotWeth() public {
        _setupWeth();

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = tokenId;
        tokenIds[1] = tokenId;
        tokenIds[2] = tokenId;

        uint256[] memory tokenAmounts = new uint256[](3);
        tokenAmounts[0] = supplyCap;
        tokenAmounts[1] = supplyCap;
        tokenAmounts[2] = supplyCap;

        bytes32[] memory emptyProof = new bytes32[](0);

        uint256 totalCost = sale.getBulkPurchaseTotal(tokenIds, tokenAmounts);

        /// values not checked because merkle root is overriden
        proofArrays.push(emptyProof);
        proofArrays.push(emptyProof);
        proofArrays.push(emptyProof);

        vm.prank(addresses.adminAddress);
        sale.setTokenConfig(tokenId, address(token), uint96(block.timestamp + 1), tokenPrice, fee, true, bytes32(0));
        vm.warp(block.timestamp + 1);

        vm.deal(addresses.userAddress, totalCost);
        vm.prank(addresses.userAddress);
        vm.expectRevert("ERC1155Sale: purchase token token must be weth");
        sale.buyTokensWithEth{value: totalCost}(
            tokenIds,
            tokenAmounts,
            tokenAmounts,
            proofArrays,
            addresses.userAddress
        );
    }

    function testBuyTokenWithEthFailsIncorrectEthAmount() public {
        vm.deal(addresses.userAddress, 1);
        vm.prank(addresses.userAddress);
        vm.expectRevert("ERC1155Sale: incorrect eth value");
        sale.buyTokenWithEth{value: 1}(tokenId, 100, 100, userProof, addresses.userAddress);
    }

    function testBuyTokensWithEthFailsIncorrectEthAmount() public {
        _setupWeth();

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        uint256[] memory tokenAmounts = new uint256[](3);
        tokenAmounts[0] = supplyCap;
        tokenAmounts[1] = supplyCap;
        tokenAmounts[2] = supplyCap;

        bytes32[] memory emptyProof = new bytes32[](0);

        /// values not checked because merkle root is overriden
        proofArrays.push(emptyProof);
        proofArrays.push(emptyProof);
        proofArrays.push(emptyProof);

        vm.deal(addresses.userAddress, 1);
        vm.prank(addresses.userAddress);
        vm.expectRevert("ERC1155Sale: incorrect eth value");
        sale.buyTokensWithEth{value: 1}(tokenIds, tokenAmounts, tokenAmounts, proofArrays, addresses.userAddress);
    }

    function testBuyTokensWithEthFailsArityMismatch0() public {
        _setupWeth();

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        uint256[] memory tokenAmounts = new uint256[](2);
        tokenAmounts[0] = supplyCap;
        tokenAmounts[1] = supplyCap;

        uint256[] memory approvedAmounts = new uint256[](2);
        approvedAmounts[0] = supplyCap;
        approvedAmounts[1] = supplyCap;

        bytes32[] memory emptyProof = new bytes32[](0);

        /// values not checked because merkle root is overriden
        proofArrays.push(emptyProof);
        proofArrays.push(emptyProof);
        proofArrays.push(emptyProof);

        vm.deal(addresses.userAddress, 1);
        vm.prank(addresses.userAddress);
        vm.expectRevert("ERC1155Sale: arity mismatch 0");
        sale.buyTokensWithEth{value: 1}(tokenIds, tokenAmounts, approvedAmounts, proofArrays, addresses.userAddress);
    }

    function testBuyTokensWithEthFailsArityMismatch1() public {
        _setupWeth();

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        uint256[] memory tokenAmounts = new uint256[](3);
        tokenAmounts[0] = supplyCap;
        tokenAmounts[1] = supplyCap;
        tokenAmounts[2] = supplyCap;

        uint256[] memory approvedAmounts = new uint256[](2);
        tokenAmounts[0] = supplyCap;
        tokenAmounts[1] = supplyCap;

        bytes32[] memory emptyProof = new bytes32[](0);

        /// values not checked because merkle root is overriden
        proofArrays.push(emptyProof);
        proofArrays.push(emptyProof);
        proofArrays.push(emptyProof);

        vm.deal(addresses.userAddress, 1);
        vm.prank(addresses.userAddress);
        vm.expectRevert("ERC1155Sale: arity mismatch 1");
        sale.buyTokensWithEth{value: 1}(tokenIds, tokenAmounts, approvedAmounts, proofArrays, addresses.userAddress);
    }

    function testBuyTokensWithEthFailsArityMismatch2() public {
        _setupWeth();

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        uint256[] memory tokenAmounts = new uint256[](3);
        tokenAmounts[0] = supplyCap;
        tokenAmounts[1] = supplyCap;
        tokenAmounts[2] = supplyCap;

        uint256[] memory approvedAmounts = new uint256[](3);
        tokenAmounts[0] = supplyCap;
        tokenAmounts[1] = supplyCap;

        bytes32[] memory emptyProof = new bytes32[](0);

        /// values not checked because merkle root is overriden
        proofArrays.push(emptyProof);
        proofArrays.push(emptyProof);

        vm.deal(addresses.userAddress, 1);
        vm.prank(addresses.userAddress);
        vm.expectRevert("ERC1155Sale: arity mismatch 2");
        sale.buyTokensWithEth{value: 1}(tokenIds, tokenAmounts, approvedAmounts, proofArrays, addresses.userAddress);
    }

    function testWrapEthSucceeds() public {
        testBulkPurchaseWithEth();

        uint256 ethBalance = address(sale).balance;

        vm.prank(addresses.adminAddress);
        sale.wrapEth();

        assertEq(address(sale).balance, 0);
        assertEq(weth.balanceOf(address(sale)), ethBalance);
    }

    function testPurchaseWithEth(uint8 tokenAmount) public {
        vm.assume(tokenAmount != 0);

        testSetupWeth();
        vm.warp(block.timestamp + 1); /// start the sale

        (, , , uint16 buyFee, , ) = sale.getTokenInfo(uint256(tokenId));

        uint256 cost = (tokenPrice * tokenAmount);
        uint256 fees = (cost * buyFee) / Constants.BASIS_POINTS_GRANULARITY;
        uint256 totalCost = cost + fees;

        vm.deal(addresses.beneficiaryAddress1, totalCost);
        vm.startPrank(addresses.beneficiaryAddress1);
        sale.buyTokenWithEth{value: totalCost}(
            tokenId,
            tokenAmount,
            300, /// approved to purchase 300
            beneficiaryOneProof,
            addresses.beneficiaryAddress1
        );
        vm.stopPrank();

        assertEq(address(sale).balance, totalCost);
        assertEq(addresses.beneficiaryAddress1.balance, 0);
        assertEq(nft.balanceOf(addresses.beneficiaryAddress1, tokenId), tokenAmount);

        (, , uint128 unclaimedProceeds, uint128 unclaimedFees) = sale.getTokenRecipientsAndUnclaimed(address(weth));
        assertEq(unclaimedProceeds, cost);
        assertEq(unclaimedFees, fees);
        if (sale.isRootOverriden(tokenId)) {
            assertEq(sale.purchased(tokenId, addresses.beneficiaryAddress1), 0);
        } else {
            assertEq(sale.purchased(tokenId, addresses.beneficiaryAddress1), tokenAmount);
        }
    }

    function testPurchaseTokens(uint8 tokenAmount) public {
        vm.assume(tokenAmount != 0);
        (, , , uint16 buyFee, , ) = sale.getTokenInfo(tokenId);

        uint256 cost = (tokenPrice * tokenAmount);
        uint256 fees = (cost * buyFee) / Constants.BASIS_POINTS_GRANULARITY;
        uint256 totalCost = cost + fees;

        token.mint(addresses.beneficiaryAddress1, totalCost);
        vm.startPrank(addresses.beneficiaryAddress1);
        token.approve(address(sale), totalCost);

        sale.buyToken(
            tokenId,
            tokenAmount,
            300, /// approved to purchase 300
            beneficiaryOneProof,
            address(this)
        );
        vm.stopPrank();

        assertEq(token.balanceOf(address(sale)), totalCost);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(nft.balanceOf(address(this), tokenId), tokenAmount);

        (, , uint128 unclaimedProceeds, uint128 unclaimedFees) = sale.getTokenRecipientsAndUnclaimed(address(token));
        assertEq(unclaimedProceeds, cost);
        assertEq(unclaimedFees, fees);

        if (sale.isRootOverriden(tokenId)) {
            assertEq(sale.purchased(tokenId, addresses.beneficiaryAddress1), 0);
        } else {
            assertEq(sale.purchased(tokenId, addresses.beneficiaryAddress1), tokenAmount);
        }
    }

    function testBulkPurchaseTokensFailsExceedsApproval() public {
        _setupWeth();

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = tokenId;
        tokenIds[1] = tokenId;
        tokenIds[2] = tokenId;

        uint256[] memory tokenAmounts = new uint256[](3);
        tokenAmounts[0] = 100;
        tokenAmounts[1] = 100;
        tokenAmounts[2] = 100;

        uint256[] memory approvedAmounts = new uint256[](3);
        approvedAmounts[0] = 100;
        approvedAmounts[1] = 100;
        approvedAmounts[2] = 100;

        uint256 totalCost = sale.getBulkPurchaseTotal(tokenIds, tokenAmounts);

        /// values not checked because merkle root is overriden
        proofArrays.push(userProof);
        proofArrays.push(userProof);
        proofArrays.push(userProof);

        token.mint(addresses.userAddress, totalCost);
        vm.startPrank(addresses.userAddress);
        token.approve(address(sale), totalCost);

        vm.expectRevert("ERC1155Sale: purchased amount exceeds approved amount");
        sale.buyTokens(
            tokenIds,
            tokenAmounts, /// purchase 400, which is 100 over approved amount
            approvedAmounts, /// approved to purchase 300
            proofArrays,
            addresses.userAddress
        );
        vm.stopPrank();
    }

    function testPurchaseTokensFailsExceedsApproval() public {
        uint256 tokenAmount = 400;
        (, , , uint16 buyFee, , ) = sale.getTokenInfo(tokenId);

        uint256 cost = (tokenPrice * tokenAmount);
        uint256 fees = (cost * buyFee) / Constants.BASIS_POINTS_GRANULARITY;
        uint256 totalCost = cost + fees;

        token.mint(addresses.beneficiaryAddress1, totalCost);
        vm.startPrank(addresses.beneficiaryAddress1);
        token.approve(address(sale), totalCost);

        vm.expectRevert("ERC1155Sale: purchased amount exceeds approved amount");
        sale.buyToken(
            tokenId,
            tokenAmount, /// purchase 400, which is 100 over approved amount
            300, /// approved to purchase 300
            beneficiaryOneProof,
            address(this)
        );
        vm.stopPrank();
    }

    function testSweepUnclaimedSuccess() public {
        testPurchaseTokens(255);
        {
            (, , uint128 unclaimedProceeds, uint128 unclaimedFees) = sale.getTokenRecipientsAndUnclaimed(
                address(token)
            );

            sale.sweepUnclaimed(address(token));

            assertEq(token.balanceOf(proceedsRecipient), unclaimedProceeds);
            assertEq(token.balanceOf(feeRecipient), unclaimedFees);
            assertEq(token.balanceOf(address(sale)), 0);
        }
        {
            (, , uint128 unclaimedProceeds, uint128 unclaimedFees) = sale.getTokenRecipientsAndUnclaimed(
                address(token)
            );
            assertEq(unclaimedProceeds, 0);
            assertEq(unclaimedFees, 0);
        }
    }

    function testSweepUnclaimedFailsNothingToPay() public {
        (, , uint128 unclaimedProceeds, uint128 unclaimedFees) = sale.getTokenRecipientsAndUnclaimed(address(token));
        assertEq(unclaimedProceeds, 0);
        assertEq(unclaimedFees, 0);

        vm.expectRevert("ERC1155Sale: nothing to pay");
        sale.sweepUnclaimed(address(token));
    }

    function testSweepUnclaimedFailsNoRecipient() public {
        testPurchaseTokens(255);
        vm.prank(addresses.adminAddress);
        sale.setTokenRecipients(address(token), address(0), address(0));

        {
            (, , uint128 unclaimedProceeds, uint128 unclaimedFees) = sale.getTokenRecipientsAndUnclaimed(
                address(token)
            );
            assertTrue(unclaimedProceeds != 0);
            assertTrue(unclaimedFees != 0);

            vm.expectRevert("ERC1155Sale: no recipient set");
            sale.sweepUnclaimed(address(token));
        }
    }

    function testSweepOnlyProceedsSucceeds() public {
        vm.prank(addresses.adminAddress);
        sale.setTokenConfig(tokenId, address(token), uint96(block.timestamp + 1), tokenPrice, fee, false, root);

        vm.warp(block.timestamp + 1); /// start the sale
        testPurchaseTokens(255);
        {
            (, , uint128 unclaimedProceeds, uint128 unclaimedFees) = sale.getTokenRecipientsAndUnclaimed(
                address(token)
            );

            sale.sweepUnclaimed(address(token));
            (, , uint256 feeAmount) = sale.getPurchasePrice(tokenId, 255);

            assertEq(token.balanceOf(proceedsRecipient), unclaimedProceeds);
            assertEq(token.balanceOf(address(sale)), 0);
            assertEq(unclaimedFees, feeAmount); /// this is incorrect
        }
        {
            (, , uint128 unclaimedProceeds, uint128 unclaimedFees) = sale.getTokenRecipientsAndUnclaimed(
                address(token)
            );
            assertEq(unclaimedProceeds, 0);
            assertEq(unclaimedFees, 0);
        }
    }

    function testPurchaseTokenBeforeStartTimeFails() public {
        vm.prank(addresses.adminAddress);
        /// set start time in the future
        sale.setTokenConfig(tokenId, address(token), uint96(block.timestamp + 1), tokenPrice, fee, false, root);

        /// do not warp to start the sale
        vm.prank(addresses.userAddress);
        vm.expectRevert("ERC1155Sale: sale has not started");
        sale.buyToken(tokenId, 100, 100, userProof, addresses.userAddress);
    }

    function testPurchaseTokensBeforeStartTimeFails() public {
        vm.prank(addresses.adminAddress);
        sale.setTokenConfig(tokenId, address(token), uint96(block.timestamp + 1), tokenPrice, fee, false, root);

        /// do not start the sale

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        uint256[] memory approvedAmounts = new uint256[](1);
        approvedAmounts[0] = 100;

        proofArrays.push(userProof);

        vm.prank(addresses.userAddress);
        vm.expectRevert("ERC1155Sale: sale has not started");
        sale.buyTokens(tokenIds, amounts, approvedAmounts, proofArrays, addresses.userAddress);
    }

    function testGetPurchasePrice(uint8 amountToPurchase) public {
        uint256 totalAmount = (amountToPurchase * tokenPrice * (fee + Constants.BASIS_POINTS_GRANULARITY)) /
            Constants.BASIS_POINTS_GRANULARITY;
        (uint256 total, , ) = sale.getPurchasePrice(tokenId, amountToPurchase);

        assertEq(total, totalAmount);
    }

    function testPurchaseBatchSuccess() public {
        uint8 amountToPurchase = 100;
        uint256 totalAmount = (amountToPurchase * tokenPrice * (fee + Constants.BASIS_POINTS_GRANULARITY)) /
            Constants.BASIS_POINTS_GRANULARITY;

        token.mint(addresses.userAddress, totalAmount);
        vm.startPrank(addresses.userAddress);
        token.approve(address(sale), totalAmount);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountToPurchase;

        proofArrays.push(userProof);

        sale.buyTokens(tokenIds, amounts, amounts, proofArrays, addresses.userAddress);

        vm.stopPrank();

        assertEq(token.balanceOf(address(sale)), totalAmount);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(nft.balanceOf(addresses.userAddress, tokenId), amountToPurchase);

        (, , uint128 unclaimedProceeds, uint128 unclaimedFees) = sale.getTokenRecipientsAndUnclaimed(address(token));
        assertEq(unclaimedProceeds, amountToPurchase * tokenPrice);
        assertEq(unclaimedFees, (amountToPurchase * tokenPrice * fee) / Constants.BASIS_POINTS_GRANULARITY);

        assertEq(sale.purchased(tokenId, addresses.userAddress), amountToPurchase);
    }

    function testPurchaseArityMismatchFailure0() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = tokenId;
        tokenIds[1] = tokenId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        vm.expectRevert("ERC1155Sale: arity mismatch 0");
        sale.buyTokens(tokenIds, amounts, amounts, proofArrays, addresses.userAddress);
    }

    function testPurchaseArityMismatchFailure1() public {
        uint256[] memory tokenIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);

        uint256[] memory approvedAmounts = new uint256[](1);

        vm.expectRevert("ERC1155Sale: arity mismatch 1");
        sale.buyTokens(tokenIds, amounts, approvedAmounts, proofArrays, addresses.userAddress);
    }

    function testPurchaseArityMismatchFailure2() public {
        uint256[] memory tokenIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        uint256[] memory approvedAmounts = new uint256[](2);

        vm.expectRevert("ERC1155Sale: arity mismatch 2");
        sale.buyTokens(tokenIds, amounts, approvedAmounts, proofArrays, addresses.userAddress);
    }

    function testPurchaseMultipleBatchesSuccess(uint256[99] memory tokenIds, uint256[99] memory amounts) external {
        uint256 tokenAmount;
        bytes32[] memory emptyProof = new bytes32[](0);
        uint96 startTime = uint96(block.timestamp + 1);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenIds[i] = i;
            if (amounts[i] == 0 || amounts[i] > supplyCap) {
                amounts[i] = i + 1;
            }

            tokenAmount += amounts[i];

            vm.prank(addresses.adminAddress);
            sale.setTokenConfig(tokenIds[i], address(token), startTime, tokenPrice, fee, true, bytes32(0));

            setSupplyCap(vm, nft, tokenIds[i], supplyCap);
            proofArrays.push(emptyProof);
        }

        vm.warp(block.timestamp + 1);

        uint256 totalAmount = (tokenAmount * tokenPrice * (fee + Constants.BASIS_POINTS_GRANULARITY)) /
            Constants.BASIS_POINTS_GRANULARITY;

        token.mint(address(this), totalAmount);
        token.approve(address(sale), totalAmount);

        sale.buyTokens(
            convertArray(tokenIds),
            convertArray(amounts),
            convertArray(amounts),
            proofArrays,
            address(this)
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(nft.balanceOf(address(this), tokenIds[i]), amounts[i]);
        }
    }

    function testWithdrawERC20SucceedsFinancialController(uint128 tokenAmount) public {
        vm.assume(tokenAmount != 0);

        token.mint(address(sale), tokenAmount);

        vm.prank(addresses.financialControllerAddress);
        sale.withdrawERC20(address(token), address(this), tokenAmount);

        assertEq(token.balanceOf(address(sale)), 0);
        assertEq(token.balanceOf(address(this)), tokenAmount);
    }

    function testWithdrawERC20FailNonFinancialController() public {
        uint256 tokenAmount = 100e18;

        token.mint(address(sale), tokenAmount);

        vm.prank(addresses.userAddress);
        vm.expectRevert("CoreRef: no role on core");
        sale.withdrawERC20(address(token), address(this), tokenAmount);

        assertEq(token.balanceOf(address(sale)), tokenAmount);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testSetTokenConfigToZeroFeeFails() public {
        vm.prank(addresses.adminAddress);
        vm.expectRevert("ERC1155Sale: fee cannot be 0");
        sale.setTokenConfig(tokenId, address(token), uint96(block.timestamp + 1), tokenPrice, 0, false, root);
    }

    function testSetTokenConfigGtMaxFeeFails() public {
        vm.prank(addresses.adminAddress);
        vm.expectRevert("ERC1155Sale: fee cannot exceed max");
        sale.setTokenConfig(tokenId, address(token), uint96(block.timestamp + 1), tokenPrice, 5001, false, root);
    }

    function testSetFeeNonGovOrAdminFails() public {
        vm.prank(addresses.guardianAddress);
        vm.expectRevert("UNAUTHORIZED");
        sale.setFee(tokenId, 100);
    }

    function testSetFeeNonexistentSetFails() public {
        vm.prank(addresses.tokenGovernorAddress);
        vm.expectRevert("ERC1155Sale: asset not listed");
        sale.setFee(tokenId + 1, 100);
    }

    function testSetFeeZeroFailsGov() public {
        vm.prank(addresses.tokenGovernorAddress);
        vm.expectRevert("ERC1155Sale: fee cannot be 0");
        sale.setFee(tokenId, 0);
    }

    function testSetFeeOverMaxFailsGov() public {
        uint256 maxFee = sale.MAX_FEE();
        vm.prank(addresses.tokenGovernorAddress);
        vm.expectRevert("ERC1155Sale: fee cannot exceed max");
        sale.setFee(tokenId, uint16(maxFee + 1));
    }

    function testSetFeeNonexistentSetFailsAdmin() public {
        vm.prank(addresses.adminAddress);
        vm.expectRevert("ERC1155Sale: asset not listed");
        sale.setFee(tokenId + 1, 100);
    }

    function testSetFeeZeroFailsAdmin() public {
        vm.prank(addresses.adminAddress);
        vm.expectRevert("ERC1155Sale: fee cannot be 0");
        sale.setFee(tokenId, 0);
    }

    function testSetFeeOverMaxFailsAdmin() public {
        uint256 maxFee = sale.MAX_FEE();
        vm.prank(addresses.adminAddress);
        vm.expectRevert("ERC1155Sale: fee cannot exceed max");
        sale.setFee(tokenId, uint16(maxFee + 1));
    }

    function testSetFeeGovSucceeds() public {
        uint256 maxFee = sale.MAX_FEE();
        vm.prank(addresses.tokenGovernorAddress);
        sale.setFee(tokenId, uint16(maxFee));

        (, , , uint16 fee, , ) = sale.getTokenInfo(tokenId);
        assertEq(fee, uint16(maxFee));
    }

    function convertArray(uint256[99] memory tokenIds) internal pure returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ids[i] = tokenIds[i];
        }

        return ids;
    }
}
