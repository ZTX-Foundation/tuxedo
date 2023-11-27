// SPDX-License-Identifier = GPL-3.0-or-later
pragma solidity 0.8.18;

import {Test} from "@forge-std/Test.sol";

import {MockERC721} from "@test/mock/MockERC721.sol";
import {Addresses} from "@proposals/Addresses.sol";
import {MerkleProof} from "@test/fixtures/MerkleProof.sol";
import {TestAddresses as testAddresses} from "@test/fixtures/TestAddresses.sol";
import {configureSale, setSupplyCap} from "@test/fixtures/Fixtures.sol";
import {BaseTest} from "@test/integration/BaseTest.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {Constants} from "@protocol/Constants.sol";
import {IWETH} from "@protocol/interface/IWETH.sol";
import {ERC1155Sale} from "@protocol/sale/ERC1155Sale.sol";
import {ERC20Splitter} from "@protocol/finance/ERC20Splitter.sol";
import {GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";
import {ERC20HoldingDeposit} from "@protocol/finance/ERC20HoldingDeposit.sol";
import {ActualERC721Staking} from "@protocol/nfts/staking/ActualERC721Staking.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

/// @title Parent contract for running integration tests
contract BasePauseSystem is BaseTest {
    /// @dev NFT/AMM
    ERC1155MaxSupplyMintable erc1155MaxSupplyMintableConsumable;
    ERC1155MaxSupplyMintable erc1155MaxSupplyMintablePlaceable;
    ERC1155MaxSupplyMintable erc1155MaxSupplyMintableWearable;
    ERC1155Sale erc1155SaleConsumable;
    ERC1155Sale erc1155SalePlaceable;
    ERC1155Sale erc1155SaleWearable;

    /// @dev MockERC721
    MockERC721 mockERC721;

    /// @dev ERC721 staking
    ActualERC721Staking actualERC721Staking;

    /// @dev weth
    IWETH weth;

    /// @dev Global reentrancy lock
    GlobalReentrancyLock lock;

    /// @dev Merkle root
    MerkleProof public proof;

    bytes32[] public userProof;
    bytes32[] public emptyProof;
    bytes32[][] public proofArrays;

    /// @dev For bulk purchases
    uint256[] public bulkTokenIds;
    uint256[] public bulkPurchaseAmounts;
    uint256[] public bulkApprovedAmounts;

    /// @dev Staked tokens
    uint256[] public stakedTokens;

    /// @notice Select the fork
    function setUp() public virtual override {
        super.setUp();

        /// @dev WETH.
        weth = IWETH(addresses.getAddress("WETH"));

        /// @dev Merkle proof
        proof = new MerkleProof();
        userProof.push(proof.userOneProof(0));
        userProof.push(proof.userOneProof(1));
        userProof.push(proof.userOneProof(2));
        userProof.push(proof.userOneProof(3));

        /// @dev Empty proof
        proofArrays.push(emptyProof);
        proofArrays.push(emptyProof);

        /// @dev Configure the ERC1155Sale and ERC1155MaxSupplyMintable contracts
        _configureContracts();

        /// @dev Fund the user
        vm.deal(testAddresses.userAddress, 100 ether);

        bulkTokenIds = [2, 3];
        bulkPurchaseAmounts = [1, 1];
        bulkApprovedAmounts = [100, 100];

        /// @dev Staked tokens
        stakedTokens = new uint256[](1);
        stakedTokens[0] = 1;
    }

    /// @notice Token cost
    /// @param tokenId The token ID
    /// @param amount The amount to purchase
    /// @param sale The ERC1155Sale contract
    /// @return total The total cost
    function getTokenCost(uint256 tokenId, uint256 amount, ERC1155Sale sale) public view returns (uint256 total) {
        (, , uint232 price, uint16 fee, , ) = sale.getTokenInfo(tokenId);

        uint256 cost = (price * amount);
        uint256 fees = (cost * fee) / Constants.BASIS_POINTS_GRANULARITY;
        total = cost + fees;
    }

    /// @notice Pause AMM
    function pause() public {
        vm.startPrank(addresses.getAddress("GUARDIAN_MULTISIG"));
        erc1155SaleConsumable.pause();
        erc1155SalePlaceable.pause();
        erc1155SaleWearable.pause();
        ERC20Splitter(addresses.getAddress("ERC1155_SALE_SPLITTER")).pause();
        actualERC721Staking.pause();
        vm.stopPrank();

        assertTrue(erc1155SaleConsumable.paused());
        assertTrue(erc1155SalePlaceable.paused());
        assertTrue(erc1155SaleWearable.paused());
        assertTrue(ERC20Splitter(addresses.getAddress("ERC1155_SALE_SPLITTER")).paused());
        assertTrue(actualERC721Staking.paused());
    }

    /// @notice Unpause AMM
    function unpause() public {
        vm.startPrank(addresses.getAddress("GUARDIAN_MULTISIG"));
        erc1155SaleConsumable.unpause();
        erc1155SalePlaceable.unpause();
        erc1155SaleWearable.unpause();
        ERC20Splitter(addresses.getAddress("ERC1155_SALE_SPLITTER")).unpause();
        actualERC721Staking.unpause();
        vm.stopPrank();

        assertFalse(erc1155SaleConsumable.paused());
        assertFalse(erc1155SalePlaceable.paused());
        assertFalse(erc1155SaleWearable.paused());
        assertFalse(ERC20Splitter(addresses.getAddress("ERC1155_SALE_SPLITTER")).paused());
        assertFalse(actualERC721Staking.paused());
    }

    /// @notice Pause and then unpause the system
    function pauseUnpause() public {
        pause();
        vm.roll(block.number + 1);
        unpause();
        vm.roll(block.number + 1);
    }

    /// @notice Purchase NFTs
    /// @param expectedBalance Expected balance after the purchase
    function purchase(uint8 expectedBalance) public {
        vm.startPrank(address(1));

        /// @dev Get some WETH
        weth.deposit{value: 10e18}();

        uint256 totalCostConsumable = getTokenCost(1, 1, erc1155SaleConsumable);
        weth.approve(address(erc1155SaleConsumable), totalCostConsumable);

        erc1155SaleConsumable.buyToken(1, 1, 100, userProof, address(1));
        assertEq(erc1155MaxSupplyMintableConsumable.balanceOf(address(1), 1), expectedBalance);

        uint256 totalCostPlaceable = getTokenCost(1, 1, erc1155SalePlaceable);
        weth.approve(address(erc1155SalePlaceable), totalCostPlaceable);

        erc1155SalePlaceable.buyToken(1, 1, 100, userProof, address(1));
        assertEq(erc1155MaxSupplyMintablePlaceable.balanceOf(address(1), 1), expectedBalance);

        uint256 totalCostWearable = getTokenCost(1, 1, erc1155SaleWearable);
        weth.approve(address(erc1155SaleWearable), totalCostWearable);

        erc1155SaleWearable.buyToken(1, 1, 100, userProof, address(1));
        assertEq(erc1155MaxSupplyMintableWearable.balanceOf(address(1), 1), expectedBalance);
        vm.stopPrank();
    }

    /// @notice Purchase NFTs with ETH
    /// @param expectedBalance Expected balance after the purchase
    function purchaseWithEth(uint8 expectedBalance) public {
        vm.startPrank(address(1));
        (uint256 totalCostConsumable, , ) = erc1155SaleConsumable.getPurchasePrice(1, 1);
        erc1155SaleConsumable.buyTokenWithEth{value: totalCostConsumable}(1, 1, 100, userProof, address(1));
        assertEq(erc1155MaxSupplyMintableConsumable.balanceOf(address(1), 1), expectedBalance);

        (uint256 totalCostPlaceable, , ) = erc1155SalePlaceable.getPurchasePrice(1, 1);
        erc1155SalePlaceable.buyTokenWithEth{value: totalCostPlaceable}(1, 1, 100, userProof, address(1));
        assertEq(erc1155MaxSupplyMintablePlaceable.balanceOf(address(1), 1), expectedBalance);

        (uint256 totalCostWearable, , ) = erc1155SaleWearable.getPurchasePrice(1, 1);
        erc1155SaleWearable.buyTokenWithEth{value: totalCostWearable}(1, 1, 100, userProof, address(1));
        assertEq(erc1155MaxSupplyMintableWearable.balanceOf(address(1), 1), expectedBalance);
        vm.stopPrank();
    }

    /// @notice Bulk purchase
    /// @param expectedBalance Expected balance after the purchase
    function bulkPurchase(uint8 expectedBalance) public {
        vm.startPrank(address(1));

        /// @dev Get some WETH
        weth.deposit{value: 10e18}();

        uint256 totalCostConsumable = getTokenCost(2, 1, erc1155SaleConsumable) +
            getTokenCost(3, 1, erc1155SaleConsumable);
        weth.approve(address(erc1155SaleConsumable), totalCostConsumable);

        erc1155SaleConsumable.buyTokens(
            bulkTokenIds,
            bulkPurchaseAmounts,
            bulkApprovedAmounts,
            proofArrays,
            address(1)
        );
        assertEq(erc1155MaxSupplyMintableConsumable.balanceOf(address(1), 2), expectedBalance);
        assertEq(erc1155MaxSupplyMintableConsumable.balanceOf(address(1), 3), expectedBalance);

        uint256 totalCostPlaceable = getTokenCost(2, 1, erc1155SalePlaceable) +
            getTokenCost(3, 1, erc1155SalePlaceable);
        weth.approve(address(erc1155SalePlaceable), totalCostPlaceable);

        erc1155SalePlaceable.buyTokens(bulkTokenIds, bulkPurchaseAmounts, bulkApprovedAmounts, proofArrays, address(1));
        assertEq(erc1155MaxSupplyMintablePlaceable.balanceOf(address(1), 2), expectedBalance);
        assertEq(erc1155MaxSupplyMintablePlaceable.balanceOf(address(1), 3), expectedBalance);

        uint256 totalCostWearable = getTokenCost(2, 1, erc1155SaleWearable) + getTokenCost(3, 1, erc1155SaleWearable);
        weth.approve(address(erc1155SaleWearable), totalCostWearable);

        erc1155SaleWearable.buyTokens(bulkTokenIds, bulkPurchaseAmounts, bulkApprovedAmounts, proofArrays, address(1));
        assertEq(erc1155MaxSupplyMintableWearable.balanceOf(address(1), 2), expectedBalance);
        assertEq(erc1155MaxSupplyMintableWearable.balanceOf(address(1), 3), expectedBalance);
        vm.stopPrank();
    }

    /// @notice Bulk purchase NFTs with ETH
    /// @param expectedBalance Expected balance after the purchase
    function bulkPurchaseWithEth(uint8 expectedBalance) public {
        vm.startPrank(address(1));
        uint256 totalCostConsumables = erc1155SaleConsumable.getBulkPurchaseTotal(bulkTokenIds, bulkPurchaseAmounts);
        erc1155SaleConsumable.buyTokensWithEth{value: totalCostConsumables}(
            bulkTokenIds,
            bulkPurchaseAmounts,
            bulkApprovedAmounts,
            proofArrays,
            address(1)
        );
        assertEq(erc1155MaxSupplyMintableConsumable.balanceOf(address(1), 2), expectedBalance);
        assertEq(erc1155MaxSupplyMintableConsumable.balanceOf(address(1), 3), expectedBalance);

        uint256 totalCostPlaceables = erc1155SalePlaceable.getBulkPurchaseTotal(bulkTokenIds, bulkPurchaseAmounts);
        erc1155SalePlaceable.buyTokensWithEth{value: totalCostPlaceables}(
            bulkTokenIds,
            bulkPurchaseAmounts,
            bulkApprovedAmounts,
            proofArrays,
            address(1)
        );
        assertEq(erc1155MaxSupplyMintablePlaceable.balanceOf(address(1), 2), expectedBalance);
        assertEq(erc1155MaxSupplyMintablePlaceable.balanceOf(address(1), 3), expectedBalance);

        uint256 totalCostWearables = erc1155SalePlaceable.getBulkPurchaseTotal(bulkTokenIds, bulkPurchaseAmounts);
        erc1155SaleWearable.buyTokensWithEth{value: totalCostWearables}(
            bulkTokenIds,
            bulkPurchaseAmounts,
            bulkApprovedAmounts,
            proofArrays,
            address(1)
        );
        assertEq(erc1155MaxSupplyMintableWearable.balanceOf(address(1), 2), expectedBalance);
        assertEq(erc1155MaxSupplyMintableWearable.balanceOf(address(1), 3), expectedBalance);
        vm.stopPrank();
    }

    /// @notice Purchase NFTs when paused
    function purchasePaused() public {
        vm.startPrank(address(1));
        (uint256 totalCostConsumable, , ) = erc1155SaleConsumable.getPurchasePrice(1, 1);
        vm.expectRevert("Pausable: paused");
        erc1155SaleConsumable.buyTokenWithEth{value: totalCostConsumable}(1, 1, 100, userProof, address(1));

        vm.expectRevert("Pausable: paused");
        erc1155SaleConsumable.buyToken(1, 1, 100, userProof, address(1));

        (uint256 totalCostPlaceable, , ) = erc1155SalePlaceable.getPurchasePrice(1, 1);
        vm.expectRevert("Pausable: paused");
        erc1155SalePlaceable.buyTokenWithEth{value: totalCostPlaceable}(1, 1, 100, userProof, address(1));

        vm.expectRevert("Pausable: paused");
        erc1155SalePlaceable.buyToken(1, 1, 100, userProof, address(1));

        (uint256 totalCostWearable, , ) = erc1155SaleWearable.getPurchasePrice(1, 1);
        vm.expectRevert("Pausable: paused");
        erc1155SaleWearable.buyTokenWithEth{value: totalCostWearable}(1, 1, 100, userProof, address(1));

        vm.expectRevert("Pausable: paused");
        erc1155SaleWearable.buyToken(1, 1, 100, userProof, address(1));
        vm.stopPrank();
    }

    /// @notice Bulk purchase NFTs when paused
    function bulkPurchasePaused() public {
        vm.startPrank(address(1));
        uint256 totalCostConsumables = erc1155SaleConsumable.getBulkPurchaseTotal(bulkTokenIds, bulkPurchaseAmounts);
        vm.expectRevert("Pausable: paused");
        erc1155SaleConsumable.buyTokensWithEth{value: totalCostConsumables}(
            bulkTokenIds,
            bulkPurchaseAmounts,
            bulkApprovedAmounts,
            proofArrays,
            address(1)
        );

        vm.expectRevert("Pausable: paused");
        erc1155SaleConsumable.buyTokens(
            bulkTokenIds,
            bulkPurchaseAmounts,
            bulkApprovedAmounts,
            proofArrays,
            address(1)
        );

        uint256 totalCostPlaceables = erc1155SalePlaceable.getBulkPurchaseTotal(bulkTokenIds, bulkPurchaseAmounts);
        vm.expectRevert("Pausable: paused");
        erc1155SalePlaceable.buyTokensWithEth{value: totalCostPlaceables}(
            bulkTokenIds,
            bulkPurchaseAmounts,
            bulkApprovedAmounts,
            proofArrays,
            address(1)
        );

        vm.expectRevert("Pausable: paused");
        erc1155SalePlaceable.buyTokens(bulkTokenIds, bulkPurchaseAmounts, bulkApprovedAmounts, proofArrays, address(1));

        uint256 totalCostWearables = erc1155SalePlaceable.getBulkPurchaseTotal(bulkTokenIds, bulkPurchaseAmounts);
        vm.expectRevert("Pausable: paused");
        erc1155SaleWearable.buyTokensWithEth{value: totalCostWearables}(
            bulkTokenIds,
            bulkPurchaseAmounts,
            bulkApprovedAmounts,
            proofArrays,
            address(1)
        );

        vm.expectRevert("Pausable: paused");
        erc1155SaleWearable.buyTokens(bulkTokenIds, bulkPurchaseAmounts, bulkApprovedAmounts, proofArrays, address(1));
        vm.stopPrank();
    }

    /// @notice Stake
    /// @param user User address
    function _stake(address user) internal {
        vm.startPrank(user);
        mockERC721.setApprovalForAll(address(actualERC721Staking), true);
        actualERC721Staking.stake(stakedTokens);
        vm.stopPrank();

        (, uint216 lastStakedTime) = actualERC721Staking.getStakedUserInfo(user);
        assertEq(lastStakedTime, block.timestamp);
        assertEq(actualERC721Staking.getUserAmountStaked(user), 1);
    }

    /// @notice Stake when paused
    function _stakePaused() internal {
        vm.startPrank(address(1));
        mockERC721.setApprovalForAll(address(actualERC721Staking), true);
        vm.expectRevert("Pausable: paused");
        actualERC721Staking.stake(stakedTokens);
        vm.stopPrank();
    }

    /// @notice Purchase NFTs with invalid lock level
    function purchaseInvalidLockLevel() public {
        vm.startPrank(address(1));
        (uint256 totalCostConsumable, , ) = erc1155SaleConsumable.getPurchasePrice(1, 1);
        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        erc1155SaleConsumable.buyTokenWithEth{value: totalCostConsumable}(1, 1, 100, userProof, address(1));

        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        erc1155SaleConsumable.buyToken(1, 1, 100, userProof, address(1));

        (uint256 totalCostPlaceable, , ) = erc1155SalePlaceable.getPurchasePrice(1, 1);
        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        erc1155SalePlaceable.buyTokenWithEth{value: totalCostPlaceable}(1, 1, 100, userProof, address(1));

        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        erc1155SalePlaceable.buyToken(1, 1, 100, userProof, address(1));

        (uint256 totalCostWearable, , ) = erc1155SaleWearable.getPurchasePrice(1, 1);
        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        erc1155SaleWearable.buyTokenWithEth{value: totalCostWearable}(1, 1, 100, userProof, address(1));

        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        erc1155SaleWearable.buyToken(1, 1, 100, userProof, address(1));
        vm.stopPrank();
    }

    /// @notice Bulk purchase NFTs with invalid lock level
    function bulkPurchaseInvalidLockLevel() public {
        vm.startPrank(address(1));
        uint256 totalCostConsumables = erc1155SaleConsumable.getBulkPurchaseTotal(bulkTokenIds, bulkPurchaseAmounts);
        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        erc1155SaleConsumable.buyTokensWithEth{value: totalCostConsumables}(
            bulkTokenIds,
            bulkPurchaseAmounts,
            bulkApprovedAmounts,
            proofArrays,
            address(1)
        );

        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        erc1155SaleConsumable.buyTokens(
            bulkTokenIds,
            bulkPurchaseAmounts,
            bulkApprovedAmounts,
            proofArrays,
            address(1)
        );

        uint256 totalCostPlaceables = erc1155SalePlaceable.getBulkPurchaseTotal(bulkTokenIds, bulkPurchaseAmounts);
        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        erc1155SalePlaceable.buyTokensWithEth{value: totalCostPlaceables}(
            bulkTokenIds,
            bulkPurchaseAmounts,
            bulkApprovedAmounts,
            proofArrays,
            address(1)
        );

        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        erc1155SalePlaceable.buyTokens(bulkTokenIds, bulkPurchaseAmounts, bulkApprovedAmounts, proofArrays, address(1));

        uint256 totalCostWearables = erc1155SalePlaceable.getBulkPurchaseTotal(bulkTokenIds, bulkPurchaseAmounts);
        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        erc1155SaleWearable.buyTokensWithEth{value: totalCostWearables}(
            bulkTokenIds,
            bulkPurchaseAmounts,
            bulkApprovedAmounts,
            proofArrays,
            address(1)
        );

        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        erc1155SaleWearable.buyTokens(bulkTokenIds, bulkPurchaseAmounts, bulkApprovedAmounts, proofArrays, address(1));
        vm.stopPrank();
    }

    /// @notice Stake with invalid lock level
    function _stakeInvalidLockLevel() internal {
        vm.startPrank(address(1));
        mockERC721.setApprovalForAll(address(actualERC721Staking), true);
        vm.expectRevert("GlobalReentrancyLock: invalid lock level");
        actualERC721Staking.stake(stakedTokens);
        vm.stopPrank();
    }

    /// @notice Wrap ETH
    function wrapEth() public {
        vm.startPrank(addresses.getAddress("ADMIN_MULTISIG"));
        erc1155SaleConsumable.wrapEth();
        erc1155SalePlaceable.wrapEth();
        erc1155SaleWearable.wrapEth();
        vm.stopPrank();
    }

    /// @notice Sweep unclaimed fees after a purchase
    /// @param consumable The expected amount of WETH swept from the consumable sale
    /// @param placeable The expected amount of WETH swept from the placeable sale
    /// @param wearable The expected amount of WETH swept from the wearable sale
    function sweepUnclaimed(uint256 consumable, uint256 placeable, uint256 wearable) public {
        wrapEth();
        vm.startPrank(addresses.getAddress("ADMIN_MULTISIG"));
        erc1155SaleConsumable.sweepUnclaimed(addresses.getAddress("WETH"));
        assertEq(IWETH(addresses.getAddress("WETH")).balanceOf(addresses.getAddress("ADMIN_MULTISIG")), consumable);

        erc1155SalePlaceable.sweepUnclaimed(addresses.getAddress("WETH"));
        assertEq(IWETH(addresses.getAddress("WETH")).balanceOf(addresses.getAddress("ADMIN_MULTISIG")), placeable);

        erc1155SaleWearable.sweepUnclaimed(addresses.getAddress("WETH"));
        assertEq(IWETH(addresses.getAddress("WETH")).balanceOf(addresses.getAddress("ADMIN_MULTISIG")), wearable);
        vm.stopPrank();
    }

    /// @notice Allocate fees
    /// @param fee The expected amount of WETH allocated to the treasury
    function allocateFees(uint256 fee) public {
        ERC20Splitter(addresses.getAddress("ERC1155_SALE_SPLITTER")).allocate();
        assertEq(weth.balanceOf(addresses.getAddress("WETH_TREASURY_HOLDING_DEPOSIT")), fee);
    }

    /// @notice Withdraw fees
    /// @param fee The expected amount of WETH withdrawn from the treasury
    function withdrawFees(uint256 fee) public {
        vm.startPrank(addresses.getAddress("TREASURY_WALLET_MULTISIG"));
        ERC20HoldingDeposit(addresses.getAddress("WETH_TREASURY_HOLDING_DEPOSIT")).withdraw(
            addresses.getAddress("TREASURY_WALLET_MULTISIG"),
            fee
        );
        vm.stopPrank();
        assertEq(weth.balanceOf(addresses.getAddress("TREASURY_WALLET_MULTISIG")), fee);
    }

    /// @notice Emergency pause
    function emergencyPause() public {
        vm.startPrank(addresses.getAddress("ADMIN_MULTISIG"));
        lock = GlobalReentrancyLock(addresses.getAddress("GLOBAL_REENTRANCY_LOCK"));
        lock.adminEmergencyPause();
        vm.roll(block.number + 1);

        assertTrue(erc1155SaleConsumable.core().lock().isLocked());
        assertTrue(erc1155SalePlaceable.core().lock().isLocked());
        assertTrue(erc1155SaleWearable.core().lock().isLocked());
        assertTrue(ERC20Splitter(addresses.getAddress("ERC1155_SALE_SPLITTER")).core().lock().isLocked());
        assertTrue(actualERC721Staking.core().lock().isLocked());
        vm.stopPrank();
    }

    /// @notice Emergency recover
    function emergencyRecover() public {
        vm.startPrank(addresses.getAddress("ADMIN_MULTISIG"));
        lock = GlobalReentrancyLock(addresses.getAddress("GLOBAL_REENTRANCY_LOCK"));
        lock.adminEmergencyRecover();
        vm.roll(block.number + 1);

        assertFalse(erc1155SaleConsumable.core().lock().isLocked());
        assertFalse(erc1155SalePlaceable.core().lock().isLocked());
        assertFalse(erc1155SaleWearable.core().lock().isLocked());
        assertFalse(ERC20Splitter(addresses.getAddress("ERC1155_SALE_SPLITTER")).core().lock().isLocked());
        assertFalse(actualERC721Staking.core().lock().isLocked());
        vm.stopPrank();
    }

    /// @notice Configure the ERC1155Sale and ERC1155MaxSupplyMintable contracts with three tokens each
    function _configureContracts() private {
        /// @dev ERC1155MaxSupplyMintable contracts
        erc1155MaxSupplyMintableConsumable = ERC1155MaxSupplyMintable(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES")
        );
        erc1155MaxSupplyMintablePlaceable = ERC1155MaxSupplyMintable(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES")
        );
        erc1155MaxSupplyMintableWearable = ERC1155MaxSupplyMintable(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")
        );

        /// @dev Consumable supply cap
        setSupplyCap(vm, addresses.getAddress("ADMIN_MULTISIG"), erc1155MaxSupplyMintableConsumable, 1, 10_000e18);
        setSupplyCap(vm, addresses.getAddress("ADMIN_MULTISIG"), erc1155MaxSupplyMintableConsumable, 2, 10_000e18);
        setSupplyCap(vm, addresses.getAddress("ADMIN_MULTISIG"), erc1155MaxSupplyMintableConsumable, 3, 10_000e18);

        /// @dev Placeable supply cap
        setSupplyCap(vm, addresses.getAddress("ADMIN_MULTISIG"), erc1155MaxSupplyMintablePlaceable, 1, 10_000e18);
        setSupplyCap(vm, addresses.getAddress("ADMIN_MULTISIG"), erc1155MaxSupplyMintablePlaceable, 2, 10_000e18);
        setSupplyCap(vm, addresses.getAddress("ADMIN_MULTISIG"), erc1155MaxSupplyMintablePlaceable, 3, 10_000e18);

        /// @dev Wearable supply cap
        setSupplyCap(vm, addresses.getAddress("ADMIN_MULTISIG"), erc1155MaxSupplyMintableWearable, 1, 10_000e18);
        setSupplyCap(vm, addresses.getAddress("ADMIN_MULTISIG"), erc1155MaxSupplyMintableWearable, 2, 10_000e18);
        setSupplyCap(vm, addresses.getAddress("ADMIN_MULTISIG"), erc1155MaxSupplyMintableWearable, 3, 10_000e18);

        /// @dev ERC1155Sale contracts
        erc1155SaleConsumable = ERC1155Sale(addresses.getAddress("ERC1155_SALE_CONSUMABLES"));
        erc1155SalePlaceable = ERC1155Sale(addresses.getAddress("ERC1155_SALE_PLACEABLES"));
        erc1155SaleWearable = ERC1155Sale(addresses.getAddress("ERC1155_SALE_WEARABLES"));

        /// @dev Configure ERC1155Sale (don't override merkle root)
        {
            configureSale(
                vm,
                addresses.getAddress("ADMIN_MULTISIG"),
                1,
                erc1155SaleConsumable,
                addresses.getAddress("ADMIN_MULTISIG"),
                addresses.getAddress("ERC1155_SALE_SPLITTER"),
                address(weth),
                0.1e18,
                100
            );

            configureSale(
                vm,
                addresses.getAddress("ADMIN_MULTISIG"),
                1,
                erc1155SalePlaceable,
                addresses.getAddress("ADMIN_MULTISIG"),
                addresses.getAddress("ERC1155_SALE_SPLITTER"),
                address(weth),
                0.1e18,
                100
            );

            configureSale(
                vm,
                addresses.getAddress("ADMIN_MULTISIG"),
                1,
                erc1155SaleWearable,
                addresses.getAddress("ADMIN_MULTISIG"),
                addresses.getAddress("ERC1155_SALE_SPLITTER"),
                address(weth),
                0.1e18,
                100
            );
        }

        /// @dev Configure ERC1155Sale (override merkle root)
        {
            configureSale(
                vm,
                addresses.getAddress("ADMIN_MULTISIG"),
                2,
                erc1155SaleConsumable,
                addresses.getAddress("ADMIN_MULTISIG"),
                addresses.getAddress("ERC1155_SALE_SPLITTER"),
                address(weth),
                uint96(block.timestamp + 1),
                0.1e18,
                100,
                true
            );

            configureSale(
                vm,
                addresses.getAddress("ADMIN_MULTISIG"),
                2,
                erc1155SalePlaceable,
                addresses.getAddress("ADMIN_MULTISIG"),
                addresses.getAddress("ERC1155_SALE_SPLITTER"),
                address(weth),
                uint96(block.timestamp + 1),
                0.1e18,
                100,
                true
            );

            configureSale(
                vm,
                addresses.getAddress("ADMIN_MULTISIG"),
                2,
                erc1155SaleWearable,
                addresses.getAddress("ADMIN_MULTISIG"),
                addresses.getAddress("ERC1155_SALE_SPLITTER"),
                address(weth),
                uint96(block.timestamp + 1),
                0.1e18,
                100,
                true
            );

            configureSale(
                vm,
                addresses.getAddress("ADMIN_MULTISIG"),
                3,
                erc1155SaleConsumable,
                addresses.getAddress("ADMIN_MULTISIG"),
                addresses.getAddress("ERC1155_SALE_SPLITTER"),
                address(weth),
                uint96(block.timestamp + 1),
                0.1e18,
                100,
                true
            );

            configureSale(
                vm,
                addresses.getAddress("ADMIN_MULTISIG"),
                3,
                erc1155SalePlaceable,
                addresses.getAddress("ADMIN_MULTISIG"),
                addresses.getAddress("ERC1155_SALE_SPLITTER"),
                address(weth),
                uint96(block.timestamp + 1),
                0.1e18,
                100,
                true
            );

            configureSale(
                vm,
                addresses.getAddress("ADMIN_MULTISIG"),
                3,
                erc1155SaleWearable,
                addresses.getAddress("ADMIN_MULTISIG"),
                addresses.getAddress("ERC1155_SALE_SPLITTER"),
                address(weth),
                uint96(block.timestamp + 1),
                0.1e18,
                100,
                true
            );
        }

        /// @dev Staking
        mockERC721 = new MockERC721();
        mockERC721.mint(address(1), 1);

        actualERC721Staking = new ActualERC721Staking(addresses.getAddress("CORE"), address(mockERC721));

        vm.startPrank(addresses.getAddress("ADMIN_MULTISIG"));
        Core(addresses.getAddress("CORE")).grantRole(Roles.LOCKER_PROTOCOL_ROLE, address(actualERC721Staking));
        vm.stopPrank();
    }
}
