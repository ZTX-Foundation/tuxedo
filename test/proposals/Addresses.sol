// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Test} from "@forge-std/Test.sol";
import {console} from "@forge-std/console.sol";

import {FinanceGuardian} from "@protocol/finance/FinanceGuardian.sol";

contract Addresses is Test {
    /// mapping for a network such as arbitrum
    mapping(string => mapping(uint256 => address)) _addresses;

    uint256 chainId;

    struct RecordedAddress {
        string name;
        address addr;
    }
    RecordedAddress[] private recordedAddresses;

    constructor() {
        chainId = block.chainid;
        console.log("chainId: ", chainId);

        /// TODO add safe address (should be a timelock) and financial guardian once we have it
        /// TODO add treasury wallet ERC20HoldingDeposit address once we have it

        /** 

            ChainId's 

            5: Goerli
            11155111: Sepolia 
            42161: Arbitrum  mainNet
            421613: Arbitrum  testNet (goerli)
            421614: Arbitrum  testNet (sepolia)
            31337: LocalNet 
        
        */

        _addAddress("DEPLOYER", 421613, 0x023ae071B954eE69c88Dbc179Cc33c15E7A0B42f);
        _addAddress("DEPLOYER", 421614, 0x023ae071B954eE69c88Dbc179Cc33c15E7A0B42f);

        /// WETH addresses
        _addAddress("WETH", 5, 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
        _addAddress("WETH", 31337, 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        _addAddress("WETH", 42161, 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        _addAddress("WETH", 421613, 0xEe01c0CD76354C383B8c7B4e65EA88D00B06f36f);
        _addAddress("WETH", 421614, 0x7331d7864ad4d32F1EBE86E26Dcba90787503757);
        _addAddress("WETH", 11155111, 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

        /// Admin multisig
        _addAddress("ADMIN_MULTISIG", 5, 0xA25f95B2106fE3935bA3229ec6C2960614F69e21);
        _addAddress("ADMIN_MULTISIG", 42161, 0x2145cc1cc05690eBa6eAD2782B3fD547CE66C29C);
        _addAddress("ADMIN_MULTISIG", 421613, 0x5Ec41e3a9c712D0BBC26d2CbA0E653c5d2cc982C);
        _addAddress("ADMIN_MULTISIG", 421614, 0x5Ec41e3a9c712D0BBC26d2CbA0E653c5d2cc982C);
        _addAddress("ADMIN_MULTISIG", 11155111, 0x5Ec41e3a9c712D0BBC26d2CbA0E653c5d2cc982C);

        /// Finance Guardian multisig
        _addAddress("FINANCE_GUARDIAN_MULTISIG", 5, 0xF74E517DA154779ee9770f27ef522F73e0b5b349);
        _addAddress("FINANCE_GUARDIAN_MULTISIG", 42161, 0xE77238A457AcE2eC9a87696DccC74B9E46f2EF34);
        _addAddress("FINANCE_GUARDIAN_MULTISIG", 421613, 0x37fe83f2bEC3C86A71864e80c1F1fE6AFE239d54);
        _addAddress("FINANCE_GUARDIAN_MULTISIG", 421614, 0x37fe83f2bEC3C86A71864e80c1F1fE6AFE239d54);
        _addAddress("FINANCE_GUARDIAN_MULTISIG", 11155111, 0x37fe83f2bEC3C86A71864e80c1F1fE6AFE239d54);

        /// Guardian Multisig
        _addAddress("GUARDIAN_MULTISIG", 5, 0xb74FbC3a1751eCDC5Fc95Db3C0E318cd2e054B1d);
        _addAddress("GUARDIAN_MULTISIG", 42161, 0x9A7a9c5B4Ad6d483664DC9D363542D844B4d116f);
        _addAddress("GUARDIAN_MULTISIG", 421613, 0xc3c1D74048115316dCbd66baeDA8214D2CA83C35);
        _addAddress("GUARDIAN_MULTISIG", 421614, 0xc3c1D74048115316dCbd66baeDA8214D2CA83C35);
        _addAddress("GUARDIAN_MULTISIG", 11155111, 0xc3c1D74048115316dCbd66baeDA8214D2CA83C35);

        /// AutoGraph Minter payment Recipient multisig
        _addAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT", 5, 0x227798656EAFe1287B38E46c7AbA9E19700F2E0a);
        _addAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT", 31337, 0xb6dd3cc3921ED28B600B179D00f3da8aE252a126);
        _addAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT", 42161, 0xb6dd3cc3921ED28B600B179D00f3da8aE252a126);
        _addAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT", 421613, 0x0e6aCa776b3d12dd85363Fd6050eE05A4a242be9);
        _addAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT", 421614, 0x0e6aCa776b3d12dd85363Fd6050eE05A4a242be9);
        _addAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT", 11155111, 0x0e6aCa776b3d12dd85363Fd6050eE05A4a242be9);

        /// TODO Get real addresses

        /// Finance Guardian Safe Address
        _addAddress("FINANCE_GUARDIAN_SAFE_ADDRESS", 31337, 0x0000000000000000000000000000000000000001);
        _addAddress("FINANCE_GUARDIAN_SAFE_ADDRESS", 42161, 0x0000000000000000000000000000000000000001);
        _addAddress("FINANCE_GUARDIAN_SAFE_ADDRESS", 421613, 0x4f4276b76398fB7a4AdbF1F0BC81201B8c55E428);
        _addAddress("FINANCE_GUARDIAN_SAFE_ADDRESS", 421614, 0x4f4276b76398fB7a4AdbF1F0BC81201B8c55E428);

        /// Game Consume Payment Recipient
        _addAddress("GAME_CONSUMER_PAYMENT_RECIPIENT", 31337, 0x0000000000000000000000000000000000000001);
        _addAddress("GAME_CONSUMER_PAYMENT_RECIPIENT", 42161, 0x0000000000000000000000000000000000000001);
        _addAddress("GAME_CONSUMER_PAYMENT_RECIPIENT", 421613, 0xF11cE4b4f8ba5bBf2B6eEbB4DB9099E7CF7ABa04);
        _addAddress("GAME_CONSUMER_PAYMENT_RECIPIENT", 421614, 0xF11cE4b4f8ba5bBf2B6eEbB4DB9099E7CF7ABa04);

        /// Contracts
        _addAddress("CORE", 421613, 0xB4caf09D4C48F57BAe0F6855BDB35578cb209d9B);
        _addAddress("GLOBAL_REENTRANCY_LOCK", 421613, 0x4C8e3dE76a28dd2fD3A9f97309e65e55250b292B);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES", 421613, 0xF80C85400dE2A07A86A09A7C16B5F31839e853A9);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES", 421613, 0x1C7dc2028cE530D068368eB6786f9d70a757Ed62);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES", 421613, 0xEa76Ea43146ecd6DdB5f946C8C8B3951464A6872);
        _addAddress("ERC1155_AUTO_GRAPH_MINTER", 421613, 0xf6477b6A2bC62E857B41ba51E7f23E5FAf23B261);
        _addAddress("WETH_ERC20_HOLDING_DEPOSIT", 421613, 0xa3794C22BAC59a0953144d1E9E9190ccC0f71122);
        _addAddress("ERC1155_SALE_CONSUMABLES", 421613, 0x680F37C43dFBA1d7548967FEFbFC535B2d308288);
        _addAddress("ERC1155_SALE_PLACEABLES", 421613, 0xf0918056423c3E6874389Fb39c5a6062f6f9fD37);
        _addAddress("ERC1155_SALE_WEARABLES", 421613, 0x9277345CaBC05e3333072780B9FE485B540D414A);
        _addAddress("FINANCE_GUARDIAN", 421613, 0xe0664e399Df8956b480F6427C55c24524137C772);
        _addAddress("TOKEN", 421613, 0xaF51C3dA399edE8053355CDd2EbDDE11Eb981811);
        _addAddress("GOVERNOR_DAO", 421613, 0x3Dd78251E48fc0E93b2Dd1D0aA8970cF59eF1315);
        _addAddress("GOVERNOR_DAO_TIMELOCK_CONTROLLER", 421613, 0xc5a3897f039c8989CD4837521516Cdc2222E2D36);
        _addAddress("ADMIN_TIMELOCK_CONTROLLER", 421613, 0xb000d9c3D4893f552082f54798869Ad9cb880E79);
        _addAddress("BURNER_WALLET", 421613, 0x13283881c765eC27C6F1eC5Bc3CbF2cDA70D11Fd);
        _addAddress("TREASURY_WALLET", 421613, 0x275769905723E8E6166Ae3b1beC0bD6ca2625759);
        _addAddress("WETH_TREASURY_WALLET", 421613, 0x76418614d5F94CFD09974d35DC1D1d443aa4abC8);
        _addAddress("CONSUMABLE_SPLITTER", 421613, 0x72188A38E84a245A40F95a7eb7C9f80e13b8D710);
        _addAddress("ERC1155_SALE_SPLITTER", 421613, 0x4C084e0975674dfB0C1D45572DFcD32919Aa8058);
        _addAddress("GAME_CONSUMABLE", 421613, 0x0B9905C4EC0BD8faBD905b1fD684aCd476338FE1);

        _addAddress("CORE", 421614, 0xBee6a4a7d455da91CC4F592de64abC4C8956a5f8);
        _addAddress("GLOBAL_REENTRANCY_LOCK", 421614, 0xeE738d4D7bAcfe0f504fC7E4bAFC4e844Dc0CDa5);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES", 421614, 0x54a53407f1d9407A194c78ec9A3e57Fe8664D373);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES", 421614, 0x2008Eb5ADfEd869eDc19CE8C2A9D78F2391e2fa1);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES", 421614, 0x44b6dED0Abc55e2052aE266BC1E0Fa73c511c8F5);
        _addAddress("ERC1155_AUTO_GRAPH_MINTER", 421614, 0x792d996E2dC2aadccFEc7A7783c163eB1ABd5d22);
        _addAddress("WETH_ERC20_HOLDING_DEPOSIT", 421614, 0x4E808045eE63d89D0E90560FA9c067b1BB4bDa58);
        _addAddress("ERC1155_SALE_CONSUMABLES", 421614, 0x4cec890691E53E29d59E8fF2f81Dd5253e3F2f1c);
        _addAddress("ERC1155_SALE_PLACEABLES", 421614, 0x4f7966430b53D4d31A2e27d81a8111B039A38B46);
        _addAddress("ERC1155_SALE_WEARABLES", 421614, 0x3508910FFdB9CFF8C0C831e2Ad7001cbD3004469);
        _addAddress("FINANCE_GUARDIAN", 421614, 0x15F6251189FeBbcD2fF317365Cc5470Af9b60479);
        _addAddress("TOKEN", 421614, 0x55b115B842E1C0C64c56FBed6a7460EbaFbA4b08);
        _addAddress("GOVERNOR_DAO", 421614, 0x1De18087387aeae9b2AF9469F1909e3C7C30E024);
        _addAddress("GOVERNOR_DAO_TIMELOCK_CONTROLLER", 421614, 0xebd85F2879385bc0D9A845de2fb455c357ED560c);
        _addAddress("ADMIN_TIMELOCK_CONTROLLER", 421614, 0xA769eF67a43998B39F3C2E0602aA7ebA97cB4f92);
        _addAddress("BURNER_WALLET", 421614, 0x46aDA2a81c6Ce36a871FF300A4017D49315EE703);
        _addAddress("TREASURY_WALLET", 421614, 0xBFAC6306884fDb2AB03C1496492C0a83C3698c4e);
        _addAddress("WETH_TREASURY_WALLET", 421614, 0xb5abd20C34a01380e6A8de3387342efCD10bdf99);
        _addAddress("CONSUMABLE_SPLITTER", 421614, 0xaeF3AeF1C1869834E6b6523F28033E442897f775);
        _addAddress("ERC1155_SALE_SPLITTER", 421614, 0xc2FBCA41B9dbb7debE9E5Ce349708602E441C608);
        _addAddress("GAME_CONSUMABLE", 421614, 0x21d993233a9E5F7E3C5F9Ca57d0c103273427840);
    }

    /// @notice add an address for a specific _chainId
    function _addAddress(string memory name, uint256 _chainId, address addr) private {
        _addresses[name][_chainId] = addr;
        vm.label(addr, name);
    }

    function _addAddress(string memory name, address addr) private {
        _addresses[name][chainId] = addr;
        vm.label(addr, name);
    }

    function getAddress(string memory name) public view returns (address) {
        return _addresses[name][chainId];
    }

    function addAddress(string memory name, address addr) public {
        _addAddress(name, addr);

        recordedAddresses.push(RecordedAddress({name: name, addr: addr}));
    }

    function resetRecordingAddresses() external {
        delete recordedAddresses;
    }

    function getRecordedAddresses() external view returns (string[] memory names, address[] memory addresses) {
        names = new string[](recordedAddresses.length);
        addresses = new address[](recordedAddresses.length);
        for (uint256 i = 0; i < recordedAddresses.length; i++) {
            names[i] = recordedAddresses[i].name;
            addresses[i] = recordedAddresses[i].addr;
        }
    }
}
