// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {MockWeth} from "@test/mock/MockWeth.sol";
import {MockERC20} from "@test/mock/MockERC20.sol";
import {ERC1155Sale} from "@protocol/sale/ERC1155Sale.sol";
import {TestAddresses} from "./TestAddresses.sol";
import {ERC20Splitter} from "@protocol/finance/ERC20Splitter.sol";
import {FinanceGuardian} from "@protocol/finance/FinanceGuardian.sol";
import {GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

import "@forge-std/Test.sol";

/// @notice Deploy and configure Core
/// @param vm Virtual machine
/// @return Core
function getCore(Vm vm) returns (Core) {
    // Deploy Core from admin address
    vm.startPrank(TestAddresses.adminAddress);
    Core core = new Core();

    core.grantRole(Roles.TOKEN_GOVERNOR, TestAddresses.tokenGovernorAddress);
    core.grantRole(Roles.GUARDIAN, TestAddresses.guardianAddress);
    core.grantRole(Roles.MINTER, TestAddresses.minterAddress);
    core.grantRole(Roles.FINANCIAL_CONTROLLER, TestAddresses.financialControllerAddress);
    core.grantRole(Roles.FINANCIAL_GUARDIAN, TestAddresses.financialGuardianAddress);
    core.grantRole(Roles.LOCKER, TestAddresses.lockerAddress);
    core.grantRole(Roles.MINTER_NOTARY, TestAddresses.minterNotaryAddress);

    vm.stopPrank();
    return core;
}

/// @notice Get system
/// @param vm Virtual machine
/// @return Core, GlobalReentrancyLock, FinanceGuardian, ERC20Splitter, MockERC20, ERC1155MaxSupplyMintable, ERC1155Sale
function getSystem(
    Vm vm
)
    returns (
        Core,
        GlobalReentrancyLock,
        FinanceGuardian,
        ERC20Splitter,
        MockERC20,
        ERC1155MaxSupplyMintable,
        ERC1155Sale
    )
{
    Core core = getCore(vm);
    GlobalReentrancyLock lock = new GlobalReentrancyLock(address(core));
    FinanceGuardian guardian = new FinanceGuardian(address(core), TestAddresses.safeAddress, new address[](0));

    ERC1155MaxSupplyMintable nft;
    ERC1155Sale sale;
    {
        MockWeth weth = new MockWeth();
        nft = new ERC1155MaxSupplyMintable(address(core), "https://exampleUri.com/", "NFT", "NFT");
        sale = new ERC1155Sale(address(core), address(nft), address(weth));
    }

    MockERC20 token = new MockERC20();

    /// no allocations at first
    ERC20Splitter splitter = new ERC20Splitter(address(core), address(token), new ERC20Splitter.Allocation[](0));

    vm.startPrank(TestAddresses.adminAddress);
    core.setGlobalLock(address(lock));
    core.grantRole(Roles.LOCKER, address(nft));
    core.grantRole(Roles.LOCKER, address(sale));
    core.grantRole(Roles.MINTER, address(sale));
    core.grantRole(Roles.LOCKER, address(guardian));
    core.grantRole(Roles.FINANCIAL_CONTROLLER, address(guardian));
    core.grantRole(Roles.GUARDIAN, address(guardian));
    vm.stopPrank();

    return (core, lock, guardian, splitter, token, nft, sale);
}

/// @notice Configure ERC1155Sale
/// @param vm Virtual machine
/// @param tokenId Token ID
/// @param sale ERC1155Sale contract
/// @param proceedsRecipient Proceeds recipient
/// @param feeRecipient Fee recipient
/// @param token Token
/// @param tokenPrice Token price
/// @param fee Fee
function configureSale(
    Vm vm,
    uint256 tokenId,
    ERC1155Sale sale,
    address proceedsRecipient,
    address feeRecipient,
    address token,
    uint232 tokenPrice,
    uint16 fee
) {
    configureSale(
        vm,
        tokenId,
        sale,
        proceedsRecipient,
        feeRecipient,
        token,
        uint96(block.timestamp + 1),
        tokenPrice,
        fee
    );
}

/// @notice Configure ERC1155Sale pranking as a specific user
/// @param vm Virtual machine
/// @param prank Prank address
/// @param tokenId Token ID
/// @param sale ERC1155Sale contract
/// @param proceedsRecipient Proceeds recipient
/// @param feeRecipient Fee recipient
/// @param token Token
/// @param tokenPrice Token price
/// @param fee Fee
function configureSale(
    Vm vm,
    address prank,
    uint256 tokenId,
    ERC1155Sale sale,
    address proceedsRecipient,
    address feeRecipient,
    address token,
    uint232 tokenPrice,
    uint16 fee
) {
    configureSale(
        vm,
        prank,
        tokenId,
        sale,
        proceedsRecipient,
        feeRecipient,
        token,
        uint96(block.timestamp + 1),
        tokenPrice,
        fee
    );
}

/// @notice Configure ERC1155Sale with a specific start time
/// @param vm Virtual machine
/// @param tokenId Token ID
/// @param sale ERC1155Sale contract
/// @param proceedsRecipient Proceeds recipient
/// @param feeRecipient Fee recipient
/// @param token Token
/// @param startTime Start time
/// @param tokenPrice Token price
/// @param fee Fee
function configureSale(
    Vm vm,
    uint256 tokenId,
    ERC1155Sale sale,
    address proceedsRecipient,
    address feeRecipient,
    address token,
    uint96 startTime,
    uint232 tokenPrice,
    uint16 fee
) {
    bytes32 root = 0x5fe607afad1e60e1e661a8f06acada612eb43d5a8ae77cc7622628cef27b7063;

    vm.startPrank(TestAddresses.adminAddress);
    sale.setTokenRecipients(address(token), proceedsRecipient, feeRecipient);
    /// do not override merkle root out of the gate
    sale.setTokenConfig(tokenId, address(token), startTime, tokenPrice, fee, false, root);
    vm.stopPrank();
}

/// @notice Configure ERC1155Sale with a specific start time, pranking as a specific user
/// @param vm Virtual machine
/// @param prank Prank address
/// @param tokenId Token ID
/// @param sale ERC1155Sale contract
/// @param proceedsRecipient Proceeds recipient
/// @param feeRecipient Fee recipient
/// @param token Token
/// @param startTime Start time
/// @param tokenPrice Token price
/// @param fee Fee
function configureSale(
    Vm vm,
    address prank,
    uint256 tokenId,
    ERC1155Sale sale,
    address proceedsRecipient,
    address feeRecipient,
    address token,
    uint96 startTime,
    uint232 tokenPrice,
    uint16 fee
) {
    bytes32 root = 0x5fe607afad1e60e1e661a8f06acada612eb43d5a8ae77cc7622628cef27b7063;

    vm.startPrank(prank);
    sale.setTokenRecipients(address(token), proceedsRecipient, feeRecipient);
    /// do not override merkle root out of the gate
    sale.setTokenConfig(tokenId, address(token), startTime, tokenPrice, fee, false, root);
    vm.stopPrank();
}

/// @notice Configure ERC1155Sale with a specific start time, pranking as a specific user and overriding merkle root
/// @param vm Virtual machine
/// @param prank Prank address
/// @param tokenId Token ID
/// @param sale ERC1155Sale contract
/// @param proceedsRecipient Proceeds recipient
/// @param feeRecipient Fee recipient
/// @param token Token
/// @param startTime Start time
/// @param tokenPrice Token price
/// @param fee Fee
/// @param overrideMerkleRoot Override the merkle root
function configureSale(
    Vm vm,
    address prank,
    uint256 tokenId,
    ERC1155Sale sale,
    address proceedsRecipient,
    address feeRecipient,
    address token,
    uint96 startTime,
    uint232 tokenPrice,
    uint16 fee,
    bool overrideMerkleRoot
) {
    bytes32 root = 0x5fe607afad1e60e1e661a8f06acada612eb43d5a8ae77cc7622628cef27b7063;

    vm.startPrank(prank);
    sale.setTokenRecipients(address(token), proceedsRecipient, feeRecipient);
    /// do not override merkle root out of the gate
    sale.setTokenConfig(tokenId, address(token), startTime, tokenPrice, fee, overrideMerkleRoot, root);
    vm.stopPrank();
}

/// @notice Set the ERC1155MaxSupplyMintable supply cap
/// @param vm Virtual machine
/// @param nft ERC1155MaxSupplyMintable contract
/// @param tokenId Token ID
/// @param supplyCap Supply cap
function setSupplyCap(Vm vm, ERC1155MaxSupplyMintable nft, uint256 tokenId, uint256 supplyCap) {
    vm.prank(TestAddresses.adminAddress);
    nft.setSupplyCap(tokenId, supplyCap);
}

/// @notice Set the ERC1155MaxSupplyMintable supply cap, pranking as a specific user
/// @param vm Virtual machine
/// @param prank Prank address
/// @param nft ERC1155MaxSupplyMintable contract
/// @param tokenId Token ID
function setSupplyCap(Vm vm, address prank, ERC1155MaxSupplyMintable nft, uint256 tokenId, uint256 supplyCap) {
    vm.prank(prank);
    nft.setSupplyCap(tokenId, supplyCap);
}

/// @notice Get the revert message
/// @param role Role
/// @param account Account address
/// @return Revert message
function getRevertMessage(bytes32 role, address account) pure returns (string memory) {
    return
        string(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(account),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )
        );
}
