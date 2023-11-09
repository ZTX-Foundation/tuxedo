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

        // 31337: LocalNet
        _addAddress("WETH", 31337, 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        _addAddress("TREASURY_WALLET_MULTISIG", 31337, 0x0000000000000000000000000000000000000101);
        _addAddress("ADMIN_MULTISIG", 31337, 0x2145cc1cc05690eBa6eAD2782B3fD547CE66C29C);
        _addAddress("FINANCE_GUARDIAN_MULTISIG", 31337, 0xE77238A457AcE2eC9a87696DccC74B9E46f2EF34);
        _addAddress("GUARDIAN_MULTISIG", 31337, 0x9A7a9c5B4Ad6d483664DC9D363542D844B4d116f);
        _addAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT", 31337, 0xb6dd3cc3921ED28B600B179D00f3da8aE252a126);
        _addAddress("FINANCE_GUARDIAN_SAFE_ADDRESS", 31337, 0x0000000000000000000000000000000000000001);
        _addAddress("GAME_CONSUMER_PAYMENT_RECIPIENT", 31337, 0x0000000000000000000000000000000000000001);

        // 421613: Arbitrum  testNet (goerli)
        _addAddress("DEPLOYER", 421613, 0x023ae071B954eE69c88Dbc179Cc33c15E7A0B42f);
        _addAddress("WETH", 421613, 0xEe01c0CD76354C383B8c7B4e65EA88D00B06f36f);
        _addAddress("ADMIN_MULTISIG", 421613, 0x5Ec41e3a9c712D0BBC26d2CbA0E653c5d2cc982C);
        _addAddress("FINANCE_GUARDIAN_MULTISIG", 421613, 0x37fe83f2bEC3C86A71864e80c1F1fE6AFE239d54);
        _addAddress("GUARDIAN_MULTISIG", 421613, 0xc3c1D74048115316dCbd66baeDA8214D2CA83C35);
        _addAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT", 421613, 0x0e6aCa776b3d12dd85363Fd6050eE05A4a242be9);
        _addAddress("FINANCE_GUARDIAN_SAFE_ADDRESS", 421613, 0x4f4276b76398fB7a4AdbF1F0BC81201B8c55E428);
        _addAddress("GAME_CONSUMER_PAYMENT_RECIPIENT", 421613, 0xF11cE4b4f8ba5bBf2B6eEbB4DB9099E7CF7ABa04);
        _addAddress("GLOBAL_REENTRANCY_LOCK", 421613, 0x6820c0dF420e8bce0408eA09822E7B12a58F45D6);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES", 421613, 0x3F5DEdE9A945887C60b64EC82F758a6249d109bf);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES", 421613, 0xdC00e09fa79EC1a4489EDa68Bc911073cEad2c6c);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES", 421613, 0x0D1485e5C5c43610e45A7951271599Ad89477207);
        _addAddress("ERC1155_AUTO_GRAPH_MINTER", 421613, 0x5A6Ca288b656745b540d5Fa7B068229A9aCD97C1);
        _addAddress("WETH_ERC20_HOLDING_DEPOSIT", 421613, 0x04f1267c0dEf0582C049597e8beD5FB36518aC1E);
        _addAddress("ERC1155_SALE_CONSUMABLES", 421613, 0x5d6ce3C67Da4c13cb02Be63E06a989C1d4aF1CED);
        _addAddress("ERC1155_SALE_PLACEABLES", 421613, 0x213359FF756612f19BFEd8167Fd84343e9246943);
        _addAddress("ERC1155_SALE_WEARABLES", 421613, 0x44bbbB8F7Bb8536E94a134D130ac86744704087D);
        _addAddress("FINANCE_GUARDIAN", 421613, 0x982be1aE69d29EAb6C9F185cFF0B7417f0072479);
        _addAddress("TOKEN", 421613, 0x80602B72cc5D87e99441F5926994c493d115D148);
        _addAddress("GOVERNOR_DAO", 421613, 0x53C6524bAd5a74500DfAB3Eacd18D154cc0Eaf51);
        _addAddress("GOVERNOR_DAO_TIMELOCK_CONTROLLER", 421613, 0x87BB0A020C2D54f3F44b200527395A9426Cdf8aA);
        _addAddress("ADMIN_TIMELOCK_CONTROLLER", 421613, 0x3f83406124203728e7ef4dad9132A87fE33321dC);
        _addAddress("BURNER_WALLET", 421613, 0xb4c86d670615A597A4FEf8bc8C6b9F0729D07dDF);
        _addAddress("TREASURY_WALLET", 421613, 0xe6Dd8De10a2596Aa822334e6627BfeBcb3abFfF0);
        _addAddress("WETH_TREASURY_WALLET", 421613, 0xEC08dBc2c4C42De5A77111831e8872723e356843);
        _addAddress("CONSUMABLE_SPLITTER", 421613, 0x5E91b94089dcaCB4C14346Ac2736B9ba4B8eEe8b);
        _addAddress("ERC1155_SALE_SPLITTER", 421613, 0xFecC1EA89705247A5B104c55cc85F2071E7C1bD3);
        _addAddress("GAME_CONSUMABLE", 421613, 0xdde8cF29ee078B5a82C88d6Cf7CBF9600c4Cf81e);
        _addAddress("TREASURY_WALLET_MULTISIG", 421613, 0x0000000000000000000000000000000000000101);

        // 421614: Arbitrum  testNet (sepolia)
        _addAddress("CORE", 421614, 0x88A6473f76B70472C48cE1C5C6b0ebfcF0FB5A55);
        _addAddress("GLOBAL_REENTRANCY_LOCK", 421614, 0xB6Bb6Ec96361a17E94991Ba5A28DAa7ca4aC5909);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES", 421614, 0x0321A813eE91b6a76c3B282a05B35253e4cE75f9);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES", 421614, 0x5F19e60Ba61E230a3e4F8b34444F627F7Dba997C);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES", 421614, 0xf9a992a0e7D5C99033c6c256654458E29a296f3B);
        _addAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTABLE", 421614, 0xE774ccc80519C6F74F7315fCd798E10Bca7Ba53e);
        _addAddress("ERC1155_AUTO_GRAPH_MINTER", 421614, 0xb2Be249fbf8E3502967Fdff3eB112c744408769A);
        _addAddress("GAME_CONSUMABLE", 421614, 0x6e6eb0Df27EC2C79488f83aC2D129e9055A9DCa3);
        _addAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT", 421614, 0x0e6aCa776b3d12dd85363Fd6050eE05A4a242be9);
        _addAddress("GAME_CONSUMER_PAYMENT_RECIPIENT", 421614, 0xF11cE4b4f8ba5bBf2B6eEbB4DB9099E7CF7ABa04);
        _addAddress("TREASURY_WALLET_MULTISIG", 421614, 0x122cE5b2D6711cEac9A6dfCB424846da3f22eaa2);
        _addAddress("TOKEN", 421614, 0x227d544D097bbBE10748592F3ceC63C66Ac0d1D7);
        _addAddress("ADMIN_MULTISIG", 421614, 0x5Ec41e3a9c712D0BBC26d2CbA0E653c5d2cc982C);

        // 42161: Arbitrum  mainNet
        _addAddress("CORE", 42161, 0xb2F009749260ddbEFe5E1687895f0A0E411613EA);
        _addAddress("GLOBAL_REENTRANCY_LOCK", 421614, 0x90eAa68fAe4703ff5328f2E86982e77EBc10539a);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES", 42161, 0x792E36c772f6dA6280fa43159792F89e7444CF18);
        _addAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTABLE", 42161, 0xd778a415A3AB81eF27da61218c71a5F31A4D10BE);
        _addAddress("TREASURY_WALLET_MULTISIG", 42161, 0xb9d7CB819Cf09c1aF796c23e7a5F0b7EE9a62902);
        _addAddress("TOKEN", 42161, 0x1C43D05be7E5b54D506e3DdB6f0305e8A66CD04e);
        _addAddress("ADMIN_MULTISIG", 42161, 0x5dE36e1b22520975021950c0ca190027A6f73aAa);
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

    function getCore() external view returns (address) {
        return getAddress("CORE");
    }
}
