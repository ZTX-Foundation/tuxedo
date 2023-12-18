// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Test} from "@forge-std/Test.sol";
import {console} from "@forge-std/console.sol";

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
        _addAddress("GUARDIAN_MULTISIG", 31337, 0x9A7a9c5B4Ad6d483664DC9D363542D844B4d116f);
        _addAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT", 31337, 0xb6dd3cc3921ED28B600B179D00f3da8aE252a126);
        _addAddress("GAME_CONSUMER_PAYMENT_RECIPIENT", 31337, 0x0000000000000000000000000000000000000001);
        _addAddress("REVENUE_WALLET_MULTISIG01", 31337, 0x0000000000000000000000000000000000000002); // TODO Naming
        _addAddress("REVENUE_WALLET_MULTISIG02", 31337, 0x0000000000000000000000000000000000000003); // TODO Naming

        // 421613: Arbitrum  testNet (goerli)
        _addAddress("CORE", 421613, 0x27c10c0af3Ab74B789aA31b20FFdcF5C87d3737C);
        _addAddress("WETH", 421613, 0xEe01c0CD76354C383B8c7B4e65EA88D00B06f36f);
        _addAddress("ADMIN_MULTISIG", 421613, 0x5Ec41e3a9c712D0BBC26d2CbA0E653c5d2cc982C);
        _addAddress("GUARDIAN_MULTISIG", 421613, 0xc3c1D74048115316dCbd66baeDA8214D2CA83C35);
        _addAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT", 421613, 0x0e6aCa776b3d12dd85363Fd6050eE05A4a242be9);
        _addAddress("GAME_CONSUMER_PAYMENT_RECIPIENT", 421613, 0xF11cE4b4f8ba5bBf2B6eEbB4DB9099E7CF7ABa04);
        _addAddress("GLOBAL_REENTRANCY_LOCK", 421613, 0x6820c0dF420e8bce0408eA09822E7B12a58F45D6);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES", 421613, 0x3F5DEdE9A945887C60b64EC82F758a6249d109bf);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES", 421613, 0xdC00e09fa79EC1a4489EDa68Bc911073cEad2c6c);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES", 421613, 0x0D1485e5C5c43610e45A7951271599Ad89477207);
        _addAddress("SEASONS_TOKEN_ID_REGISTRY", 421613, 0x8d073006E834F5C69D4f7463Ba302cd7Db947029);
        _addAddress("ERC1155_SEASON_ONE", 421613, 0xB0D993F3a431A8eEE85D439Deea6c847f45BB9d9);
        _addAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTABLE", 421613, 0xacd649320A6229f14D67f78e6541c8b45a21D8Ba);
        _addAddress("ERC1155_AUTO_GRAPH_MINTER", 421613, 0xb352F8Da6a69aC73e638f8d3798Cb52a91D40D1a);
        _addAddress("WETH_ERC20_HOLDING_DEPOSIT", 421613, 0x04f1267c0dEf0582C049597e8beD5FB36518aC1E);
        _addAddress("ERC1155_SALE_CONSUMABLES", 421613, 0x5d6ce3C67Da4c13cb02Be63E06a989C1d4aF1CED);
        _addAddress("ERC1155_SALE_PLACEABLES", 421613, 0x213359FF756612f19BFEd8167Fd84343e9246943);
        _addAddress("ERC1155_SALE_WEARABLES", 421613, 0x44bbbB8F7Bb8536E94a134D130ac86744704087D);
        _addAddress("TOKEN", 421613, 0x80602B72cc5D87e99441F5926994c493d115D148);
        _addAddress("GOVERNOR_DAO", 421613, 0x53C6524bAd5a74500DfAB3Eacd18D154cc0Eaf51);
        _addAddress("GOVERNOR_DAO_TIMELOCK_CONTROLLER", 421613, 0x87BB0A020C2D54f3F44b200527395A9426Cdf8aA);
        _addAddress("ADMIN_TIMELOCK_CONTROLLER", 421613, 0x3f83406124203728e7ef4dad9132A87fE33321dC);
        _addAddress("BURNER_HOLDING_DEPOSIT", 421613, 0xb4c86d670615A597A4FEf8bc8C6b9F0729D07dDF);
        _addAddress("TREASURY_WALLET_MULTISIG", 421613, 0xe6Dd8De10a2596Aa822334e6627BfeBcb3abFfF0);
        _addAddress("WETH_TREASURY_HOLDING_DEPOSIT", 421613, 0xEC08dBc2c4C42De5A77111831e8872723e356843);
        _addAddress("CONSUMABLE_SPLITTER", 421613, 0x5E91b94089dcaCB4C14346Ac2736B9ba4B8eEe8b);
        _addAddress("ERC1155_SALE_SPLITTER", 421613, 0xFecC1EA89705247A5B104c55cc85F2071E7C1bD3);
        _addAddress("GAME_CONSUMABLE", 421613, 0xdde8cF29ee078B5a82C88d6Cf7CBF9600c4Cf81e);

        // 421614: Arbitrum  testNet (sepolia)
        _addAddress("CORE", 421614, 0x68D6B4af6668A62Fc1B21ABF3DbfA366DD1d8eC7);
        _addAddress("GLOBAL_REENTRANCY_LOCK", 421614, 0x87D7b991540747522404c86b281E4880Cd6dE7f2);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES", 421614, 0x27564B8cf86aba79b398A39B75898fe8AFf30627);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES", 421614, 0x898C5e72Cb4121A8ae579faEAe2C5879196493fc);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES", 421614, 0xa7654c44f0A4Da52a10469dC380f02F75d6E0631);
        _addAddress("SEASONS_TOKEN_ID_REGISTRY", 421614, 0x8ccE22Fe7Bd3F4998E158De3c3a77ee85A6F6bBB);
        _addAddress("ERC1155_SEASON_ONE", 421614, 0x3006b30E32dEA503503Bf9e3f909163834085A5C);
        _addAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTER", 421614, 0x34c775910e5CbB1511eF00Ea51cd0f6bd1E3E4Db);
        _addAddress("ERC1155_AUTO_GRAPH_MINTER", 421614, 0x2a7093311D65550285AcA9650C9F9165f74337f3);
        _addAddress("GAME_CONSUMABLE", 421614, 0xf052f3F94f6E71DfBA39544b8DF02c873De4469F);
        _addAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT", 421614, 0x0e6aCa776b3d12dd85363Fd6050eE05A4a242be9);
        _addAddress("GAME_CONSUMER_PAYMENT_RECIPIENT", 421614, 0xF11cE4b4f8ba5bBf2B6eEbB4DB9099E7CF7ABa04);
        _addAddress("TREASURY_WALLET_MULTISIG", 421614, 0x122cE5b2D6711cEac9A6dfCB424846da3f22eaa2);
        _addAddress("TOKEN", 421614, 0x5422a3De80BA3891d663fa4EC7506A7f263c1Fd9);
        _addAddress("ADMIN_MULTISIG", 421614, 0x5Ec41e3a9c712D0BBC26d2CbA0E653c5d2cc982C);

        // 42161: Arbitrum  mainNet
        _addAddress("CORE", 42161, 0xb2F009749260ddbEFe5E1687895f0A0E411613EA);
        _addAddress("GLOBAL_REENTRANCY_LOCK", 42161, 0x90eAa68fAe4703ff5328f2E86982e77EBc10539a);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES", 42161, 0x792E36c772f6dA6280fa43159792F89e7444CF18);
        _addAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTABLE", 42161, 0xd778a415A3AB81eF27da61218c71a5F31A4D10BE);
        _addAddress("TREASURY_WALLET_MULTISIG", 42161, 0xb9d7CB819Cf09c1aF796c23e7a5F0b7EE9a62902);
        _addAddress("TOKEN", 42161, 0x1C43D05be7E5b54D506e3DdB6f0305e8A66CD04e);

        // Multisigs addresses
        _addAddress("ADMIN_MULTISIG", 42161, 0x5dE36e1b22520975021950c0ca190027A6f73aAa);
        _addAddress("GUARDIAN_MULTISIG", 42161, 0xc6a9E0C54A678cC769563204bd84456d7314EF21);

        // Revenue Wallets addresses
        _addAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT", 42161, 0xc3B2c05A417CD4903615556A81F82602C9D9eA04);
        _addAddress("REVENUE_WALLET_MULTISIG01", 42161, 0x8A8041eaA86aD43656420FB4b04dcBf66EbD6261); // TODO Naming
        _addAddress("REVENUE_WALLET_MULTISIG02", 42161, 0xC3Ae66c6a96Cb4737D95B7D3e8587992332304a1); // TODO Naming

        // Autograph service KMS EOA
        _addAddress("AUTOGRAPH_SERVICE_KMS_WALLET", 42161, 0xEE8b0f0708224FbB5832f90f0441A9BaDE417568);

        // 3rd party contract addresses
        _addAddress("WETH", 42161, 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
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
