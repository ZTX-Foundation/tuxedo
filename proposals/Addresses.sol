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

        // 421614: Arbitrum  testNet (sepolia)
        _addAddress("CORE", 421614, 0x68D6B4af6668A62Fc1B21ABF3DbfA366DD1d8eC7);
        _addAddress("WETH", 421614, 0xc556bAe1e86B2aE9c22eA5E036b07E55E7596074);
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
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES", 42161, 0x163b2E7696F661F86DBB39Ce4b03e38Bfe22a1C9);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES", 42161, 0x2C154Ae907652A1a9939DBe0622915111816942C);
        _addAddress("SEASONS_TOKEN_ID_REGISTRY", 42161, 0x5cb7431a545523F25AbD3948c648329636a4b1E5);
        _addAddress("ERC1155_SEASON_ONE", 42161, 0x59AFA38214C9CCCFB56f72DE7f9a2B47fA17C270);
        _addAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTABLE", 42161, 0xd778a415A3AB81eF27da61218c71a5F31A4D10BE);
        _addAddress("ERC1155_AUTO_GRAPH_MINTER", 42161, 0xD031aD02aD4bADFc06b64ec64eBA32cFc781FB9b);
        _addAddress("GAME_CONSUMABLE", 42161, 0xeD3ed10Bd8FD4093528B38B6fD7c5a5C616EB28f);
        _addAddress("CONSUMABLE_SPLITTER", 42161, 0x85454964Db79620e239C5425F047eAAe027d0E08);
        _addAddress("TREASURY_WALLET_MULTISIG", 42161, 0xb9d7CB819Cf09c1aF796c23e7a5F0b7EE9a62902);
        _addAddress("TOKEN", 42161, 0x1C43D05be7E5b54D506e3DdB6f0305e8A66CD04e);
        _addAddress("ADMIN_TIMELOCK_CONTROLLER", 42161, 0xf16A0E806A4CF6e9031A0dA028c80eF8A771aE48);

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
