// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Test} from "@forge-std/Test.sol";
import {console} from "@forge-std/console.sol";

/// TODO Switch to Emum for contract name labels for compile time checking

enum EnvVar {
    LocalNet,
    SandPitNet, // Tuxedo's team env for localized testing on sepolia
    DevNet, // dev env
    TestNet, // qa env
    MixedNet, // TODO to be removed. Only used for contracts getting used in devNet and testNet
    StageNet, // staging env
    MainNet // prod env
}

function getEnvVar(EnvVar env) pure returns (string memory) {
    if (EnvVar.SandPitNet == env) {
        return "SandPitNet";
    } else if (EnvVar.LocalNet == env) {
        return "LocalNet";
    } else if (EnvVar.DevNet == env) {
        return "DevNet";
    } else if (EnvVar.TestNet == env) {
        return "TestNet";
    } else if (EnvVar.MixedNet == env) {
        return "MixedNet";
    } else if (EnvVar.StageNet == env) {
        return "StageNet";
    } else if (EnvVar.MainNet == env) {
        return "MainNet";
    } else {
        return "Unknown";
    }
}

function getEnvVar(uint256 chainId) pure returns (EnvVar) {
    if (421614 == chainId) {
        return EnvVar.SandPitNet;
    } else if (31337 == chainId) {
        return EnvVar.LocalNet;
    } else if (421614 == chainId) {
        return EnvVar.DevNet;
    } else if (421614 == chainId) {
        return EnvVar.TestNet;
    } else if (421614 == chainId) {
        return EnvVar.MixedNet;
    } else if (421614 == chainId) {
        return EnvVar.StageNet;
    } else if (42161 == chainId) {
        return EnvVar.MainNet;
    } else {
        return EnvVar.LocalNet;
    }
}

function getChainId(EnvVar env) pure returns (uint256) {
    if (EnvVar.SandPitNet == env) {
        return 421614; // Arbitrum (sepolia)
    } else if (EnvVar.LocalNet == env) {
        return 31337;
    } else if (EnvVar.DevNet == env) {
        return 421614; // Arbitrum (sepolia)
    } else if (EnvVar.TestNet == env) {
        return 421614; // Arbitrum (sepolia)
    } else if (EnvVar.MixedNet == env) {
        return 421614; // Arbitrum (sepolia)
    } else if (EnvVar.StageNet == env) {
        return 421614; // Arbitrum (sepolia)
    } else if (EnvVar.MainNet == env) {
        return 42161; // Arbitrum (mainNet)
    } else {
        return 0; // invalid
    }
}

contract Addresses is Test {
    uint256 private immutable chainId;
    EnvVar private immutable envVar;

    /// @notice mapping of Envirnment to contract name to address
    /// @dev example: _addresses[EnvVar.MainNet]["CORE"] = 0xb2F009749260ddbEFe5E1687895f0A0E411613EA
    mapping(EnvVar env => mapping(string contractName => address contractAddr)) private _addresses;

    /// @notice RecordedAddress array for contract name and address of the current zip saved in memory
    /// @dev These addresses are to be saved post deployment to this file.
    struct RecordedAddress {
        string name;
        address addr;
    }
    RecordedAddress[] private recordedAddresses;

    constructor(EnvVar _env) {
        chainId = block.chainid;
        envVar = _env;

        console.log("chainId: ", chainId);
        console.log("envVar: ", getEnvVar(envVar));

        setNetworkAddresses(envVar);
    }

    // TODO Write this to import addresses from a json file at some point
    function setNetworkAddresses(EnvVar env) public {
        console.log("Load pre-saved Network addresses: ", getEnvVar(env));
        if (EnvVar.MainNet == envVar) {
            setMainNetAddresses();
        } else if (EnvVar.StageNet == envVar) {
            setStageNetAddresses();
        } else if (EnvVar.TestNet == envVar) {
            setTestNetAddresses();
        } else if (EnvVar.DevNet == envVar) {
            setDevNetAddresses();
        } else if (EnvVar.LocalNet == envVar) {
            setLocalNetAddresses();
        } else if (EnvVar.MixedNet == envVar) {
            setMixedNetAddresses();
        } else if (EnvVar.SandPitNet == envVar) {
            setSandPitNetAddresses();
        } else {
            console.log("Unknown env: ", getEnvVar(envVar));
            assert(false);
        }
    }

    /// 42161: Arbitrum  mainNet
    function setMainNetAddresses() private {
        _addAddress("CORE", 0xb2F009749260ddbEFe5E1687895f0A0E411613EA);
        _addAddress("GLOBAL_REENTRANCY_LOCK", 0x90eAa68fAe4703ff5328f2E86982e77EBc10539a);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES", 0x792E36c772f6dA6280fa43159792F89e7444CF18);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES", 0x163b2E7696F661F86DBB39Ce4b03e38Bfe22a1C9);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES", 0x2C154Ae907652A1a9939DBe0622915111816942C);
        _addAddress("SEASONS_TOKEN_ID_REGISTRY", 0x5cb7431a545523F25AbD3948c648329636a4b1E5);
        _addAddress("ERC1155_SEASON_ONE", 0x59AFA38214C9CCCFB56f72DE7f9a2B47fA17C270);
        _addAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTABLE", 0xd778a415A3AB81eF27da61218c71a5F31A4D10BE);
        _addAddress("ERC1155_AUTO_GRAPH_MINTER", 0xD031aD02aD4bADFc06b64ec64eBA32cFc781FB9b);
        _addAddress("GAME_CONSUMABLE", 0xeD3ed10Bd8FD4093528B38B6fD7c5a5C616EB28f);
        _addAddress("CONSUMABLE_SPLITTER", 0x85454964Db79620e239C5425F047eAAe027d0E08);
        _addAddress("TREASURY_WALLET_MULTISIG", 0xb9d7CB819Cf09c1aF796c23e7a5F0b7EE9a62902);
        _addAddress("TOKEN", 0x1C43D05be7E5b54D506e3DdB6f0305e8A66CD04e);
        _addAddress("ADMIN_TIMELOCK_CONTROLLER", 0xf16A0E806A4CF6e9031A0dA028c80eF8A771aE48);

        // Multisigs addresses
        _addAddress("ADMIN_MULTISIG", 0x5dE36e1b22520975021950c0ca190027A6f73aAa);
        _addAddress("GUARDIAN_MULTISIG", 0xc6a9E0C54A678cC769563204bd84456d7314EF21);

        // Revenue Wallets addresses
        _addAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT", 0xc3B2c05A417CD4903615556A81F82602C9D9eA04);
        _addAddress("REVENUE_WALLET_MULTISIG01", 0x8A8041eaA86aD43656420FB4b04dcBf66EbD6261); // TODO Naming
        _addAddress("REVENUE_WALLET_MULTISIG02", 0xC3Ae66c6a96Cb4737D95B7D3e8587992332304a1); // TODO Naming

        // Autograph service KMS EOA
        _addAddress("AUTOGRAPH_SERVICE_KMS_WALLET", 0xEE8b0f0708224FbB5832f90f0441A9BaDE417568);

        // 3rd party contract addresses
        _addAddress("WETH", 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    }
    function setStageNetAddresses() private {}

    function setTestNetAddresses() private {}
    function setDevNetAddresses() private {}

    /// 31337: LocalNet
    function setLocalNetAddresses() private {
        _addAddress("WETH", 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        _addAddress("TREASURY_WALLET_MULTISIG", 0x0000000000000000000000000000000000000101);
        _addAddress("ADMIN_MULTISIG", 0x2145cc1cc05690eBa6eAD2782B3fD547CE66C29C);
        _addAddress("GUARDIAN_MULTISIG", 0x9A7a9c5B4Ad6d483664DC9D363542D844B4d116f);
        _addAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT", 0xb6dd3cc3921ED28B600B179D00f3da8aE252a126);
        _addAddress("GAME_CONSUMER_PAYMENT_RECIPIENT", 0x0000000000000000000000000000000000000001);
        _addAddress("REVENUE_WALLET_MULTISIG01", 0x0000000000000000000000000000000000000002); // TODO Naming
        _addAddress("REVENUE_WALLET_MULTISIG02", 0x0000000000000000000000000000000000000003); // TODO Naming
    }

    /// @dev to be decommissioned
    /// 421614: Arbitrum  testNet (sepolia)
    function setMixedNetAddresses() private {
        _addAddress("CORE", 0x68D6B4af6668A62Fc1B21ABF3DbfA366DD1d8eC7);
        _addAddress("GLOBAL_REENTRANCY_LOCK", 0x87D7b991540747522404c86b281E4880Cd6dE7f2);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES", 0x27564B8cf86aba79b398A39B75898fe8AFf30627);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES", 0x898C5e72Cb4121A8ae579faEAe2C5879196493fc);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES", 0xa7654c44f0A4Da52a10469dC380f02F75d6E0631);
        _addAddress("SEASONS_TOKEN_ID_REGISTRY", 0x8ccE22Fe7Bd3F4998E158De3c3a77ee85A6F6bBB);
        _addAddress("ERC1155_SEASON_ONE", 0x3006b30E32dEA503503Bf9e3f909163834085A5C);
        _addAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTER", 0x34c775910e5CbB1511eF00Ea51cd0f6bd1E3E4Db);
        _addAddress("ERC1155_AUTO_GRAPH_MINTER", 0x2a7093311D65550285AcA9650C9F9165f74337f3);
        _addAddress("GAME_CONSUMABLE", 0xf052f3F94f6E71DfBA39544b8DF02c873De4469F);
        _addAddress("AUTOGRAPH_MINTER_PAYMENT_RECIPIENT", 0x0e6aCa776b3d12dd85363Fd6050eE05A4a242be9);
        _addAddress("GAME_CONSUMER_PAYMENT_RECIPIENT", 0xF11cE4b4f8ba5bBf2B6eEbB4DB9099E7CF7ABa04);
        _addAddress("TREASURY_WALLET_MULTISIG", 0x122cE5b2D6711cEac9A6dfCB424846da3f22eaa2);
        _addAddress("TOKEN", 0x5422a3De80BA3891d663fa4EC7506A7f263c1Fd9);
        _addAddress("ADMIN_MULTISIG", 0x5Ec41e3a9c712D0BBC26d2CbA0E653c5d2cc982C);
    }

    /// @dev utx0's RnD set of contracts
    function setSandPitNetAddresses() private {
        _addAddress("TREASURY_WALLET_MULTISIG", 0xa8d0Fc249A1927D5D718Ee0a1F2A98fe72B10049); // utx0's wallet address
        _addAddress("ADMIN_MULTISIG", 0xa8d0Fc249A1927D5D718Ee0a1F2A98fe72B10049); // utx0's wallet address
        _addAddress("TOKEN", 0x0CF950b4e2C939916E595070eC460BeFFA9A572a);
        _addAddress("CORE", 0xCe97fB8A1afbc3A0095AF633040D215f9EdF1831);
        _addAddress("GLOBAL_REENTRANCY_LOCK", 0xAae39744f77D422BdfBf922D67707173014eebdd);
        _addAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES", 0x6bC6eAd87Dc24d7C8466424Dc8e3AC40701e7053);
        _addAddress("ERC1155_MAX_SUPPLY_ADMIN_MINTER", 0xB30f4d4c2044567AEEBBb6bC0542579600832fFc);
    }

    /// TODO possible remove?
    /// Seams like this really isnt needed.
    // function selectNetworkFork(EnvVar env) private {
    //     string memory fork;

    //     console.log("Select Network Fork");
    //     if(EnvVar.LocalNet == env) {
    //         console.log("LocalNet does not require fork");
    //         return;
    //     } else if (EnvVar.SandPitNet == env) {
    //         fork = vm.envString("ARBITRUM_TESTNET_SEPOLIA_RPC_URL");
    //     } else if (EnvVar.DevNet == env) {
    //         fork = vm.envString("ARBITRUM_TESTNET_SEPOLIA_RPC_URL");
    //     } else if (EnvVar.TestNet == env) {
    //         fork = vm.envString("ARBITRUM_TESTNET_SEPOLIA_RPC_URL");
    //     } else if (EnvVar.MixedNet == env) {
    //         fork = vm.envString("ARBITRUM_TESTNET_SEPOLIA_RPC_URL");
    //     } else if (EnvVar.StageNet == env) {
    //         fork = vm.envString("ARBITRUM_TESTNET_SEPOLIA_RPC_URL");
    //     } else if (EnvVar.MainNet == env) {
    //         fork = vm.envString("ARBITRUM_MAINNET_RPC_URL");
    //     } else {
    //         console.log("Unknown env: ", getEnvVar(env));
    //         assert(false);
    //     }

    //     console.log("Fork RPC: ", fork);
    //     // uint x = vm.createFork(fork);
    //     // vm.selectFork(x);

    //     vm.createSelectFork(fork);
    // }

    function _addAddress(string memory name, address addr) private {
        _addresses[envVar][name] = addr;
        vm.label(addr, name);
    }

    function getAddress(string memory name) public view returns (address) {
        return _addresses[envVar][name];
    }

    /// @notice Added an address to the in memory addresses array
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

    function printRecordedAddresses() external view {
        for (uint256 i = 0; i < recordedAddresses.length; i++) {
            console.log("Recorded", recordedAddresses[i].addr, recordedAddresses[i].name);
        }
    }

    function getCore() external view returns (address) {
        return getAddress("CORE");
    }
}
