# Tuxedo

Solidity smart contracts for ZTX.

## Dependencies

- [Foundry](https://github.com/foundry-rs/foundry)
- [npm](https://docs.npmjs.com/getting-started)
- [Slither](https://github.com/crytic/slither)

## Documentation

For further details, see the [docs](./doc/contracts).

## Setup

```console
npm install
```

The system also requires the following environment variables to be set:

| Variable               | Description                                                           |
|------------------------|-----------------------------------------------------------------------|
| `TOKEN_NAME`           | The name of the token (e.g. `ZTX Token`).                             |
| `TOKEN_SYMBOL`         | The symbol of the primay token (e.g. `ZTX`).                          |
| `DOMAIN`               | The domain of where the metadata is hosted.                           |
| `ENVIRONMENT`          | The environment of the deployment (`devnet`, `testnet` or `mainnet`). |
| `DEPLOYER_PRIVATE_KEY` | The private key of the deployer.                                      |
| `MAINNET_RPC_URL`      | Arbitrum mainnet RPC host.                                            |
| `TESTNET_RPC_URL`      | Arbitrum testnet RPC host.                                            |
| `ARBITRUM_TESTNET_SEPOLIA_RPC_URL` | Arbitrum Sepolia Testnet RPC host                         |

See the included `.env.example` for an example.

## Build

To build, run:

```console
forge build
```

## Tests

To run the unit tests:

```console
npm run test:unit
```

and the integration tests:

```console
npm run test:integration
```

## Linter

To run the linter:

```console
npm run lint:check
```

## ABI

To generate the ABI files, simply run:

```console
npm run clean && npm run build
```

## Static Analysis

We use [Slither](https://github.com/crytic/slither) to analyse our contracts.

### Install

```console
npm run slither:install
```

### Run

```console
npm run slither
```

## Deployment

Before deploying, please ensure you have the correct environment variables set!

### Arbitrum Goerli (testnet)

To deploy to testnet, run:

```console
npm run deploy:testnet
```

### Arbitrum Mainnet

To deploy to mainnet, run:

```console
npm run deploy:mainnet
```

## Contracts

### Arbitrum Goerli (testnet)

| Address                                      | Contract                                                                                                                                           |
|----------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| `0x27c10c0af3Ab74B789aA31b20FFdcF5C87d3737C` | [CORE](./src/core/Core.sol)                                                                                                                        |
| `0x6820c0dF420e8bce0408eA09822E7B12a58F45D6` | [GLOBAL_REENTRANCY_LOCK](./src/core/GlobalReentrancyLock.sol)                                                                                      |
| `0x3F5DEdE9A945887C60b64EC82F758a6249d109bf` | [ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                                 |
| `0xdC00e09fa79EC1a4489EDa68Bc911073cEad2c6c` | [ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                                  |
| `0x0D1485e5C5c43610e45A7951271599Ad89477207` | [ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                                   |
| `0x5A6Ca288b656745b540d5Fa7B068229A9aCD97C1` | [ERC1155_AUTO_GRAPH_MINTER](./src/nfts/ERC1155AutoGraphMinter.sol)                                                                                 |
| `0x04f1267c0dEf0582C049597e8beD5FB36518aC1E` | [WETH_ERC20_HOLDING_DEPOSIT](./src/finance/ERC20HoldingDeposit.sol)                                                                                |
| `0xFc601A8654aA5857C8C2336AA5f1EC9197e51450` | [ZTX HOODIE](./src/nfts/ERC721ZepetoUA.sol)                                                                                                        |
| `0x5d6ce3C67Da4c13cb02Be63E06a989C1d4aF1CED` | [ERC1155_SALE_CONSUMABLES](./src/sale/ERC1155Sale.sol)                                                                                             |
| `0x213359FF756612f19BFEd8167Fd84343e9246943` | [ERC1155_SALE_PLACEABLES](./src/sale/ERC1155Sale.sol)                                                                                              |
| `0x44bbbB8F7Bb8536E94a134D130ac86744704087D` | [ERC1155_SALE_WEARABLES](./src/sale/ERC1155Sale.sol)                                                                                               |
| `0x982be1aE69d29EAb6C9F185cFF0B7417f0072479` | [FINANCE_GUARDIAN](./src/finance/FinanceGuardian.sol)                                                                                              |
| `0x80602B72cc5D87e99441F5926994c493d115D148` | [TOKEN](./src/token/Token.sol)                                                                                                                     |
| `0x53C6524bAd5a74500DfAB3Eacd18D154cc0Eaf51` | [GOVERNOR_DAO](./src/governance/GovernorDAO.sol)                                                                                                   |
| `0x87BB0A020C2D54f3F44b200527395A9426Cdf8aA` | [GOVERNOR_DAO_TIMELOCK_CONTROLLER](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol) |
| `0x3f83406124203728e7ef4dad9132A87fE33321dC` | [ADMIN_TIMELOCK_CONTROLLER](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol)        |
| `0xb4c86d670615A597A4FEf8bc8C6b9F0729D07dDF` | [BURNER_WALLET](./src/finance/ERC20HoldingDeposit.sol)                                                                                             |
| `0xe6Dd8De10a2596Aa822334e6627BfeBcb3abFfF0` | [TREASURY_WALLET](./src/finance/ERC20HoldingDeposit.sol)                                                                                           |
| `0xEC08dBc2c4C42De5A77111831e8872723e356843` | [WETH_TREASURY_WALLET](./src/finance/ERC20HoldingDeposit.sol)                                                                                      |
| `0x5E91b94089dcaCB4C14346Ac2736B9ba4B8eEe8b` | [CONSUMABLE_SPLITTER](./src/finance/ERC20Splitter.sol)                                                                                             |
| `0xFecC1EA89705247A5B104c55cc85F2071E7C1bD3` | [ERC1155_SALE_SPLITTER](./src/finance/ERC20Splitter.sol)                                                                                           |
| `0x853e2e1fFF72a7B2350dEa202A0fa7C42AA4b42D` | [GAME_CONSUMABLE](./src/game/GameConsumer.sol)                                                                                                     |

### Arbitrum Sepolia (testnet)

| Address                                                                                                                                 | Contract                                                                           | ABI                                                                                           |
|-----------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| [`0x88A6473f76B70472C48cE1C5C6b0ebfcF0FB5A55`](https://sepolia-explorer.arbitrum.io/address/0x88A6473f76B70472C48cE1C5C6b0ebfcF0FB5A55) | [CORE](./src/core/Core.sol)                                                        | [Core.abi.json](./dist/v1.0.2-rc.1/abi/Core.abi.json)                                         |
| [`0xB6Bb6Ec96361a17E94991Ba5A28DAa7ca4aC5909`](https://sepolia-explorer.arbitrum.io/address/0xB6Bb6Ec96361a17E94991Ba5A28DAa7ca4aC5909) | [GLOBAL_REENTRANCY_LOCK](./src/utils/GlobalReentrancyLock.sol)                     | [GlobalReentrancyLock.abi.json](./dist/v1.0.2-rc.1/abi/GlobalReentrancyLock.abi.json)         |
| [`0x0321A813eE91b6a76c3B282a05B35253e4cE75f9`](https://sepolia-explorer.arbitrum.io/address/0x0321A813eE91b6a76c3B282a05B35253e4cE75f9) | [ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)   | [ERC1155MaxSupplyMintable.abi.json](./dist/v1.0.2-rc.1/abi/ERC1155MaxSupplyMintable.abi.json) |
| [`0x5F19e60Ba61E230a3e4F8b34444F627F7Dba997C`](https://sepolia-explorer.arbitrum.io/address/0x5F19e60Ba61E230a3e4F8b34444F627F7Dba997C) | [ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES](./src/nfts/ERC1155MaxSupplyMintable.sol) | [ERC1155MaxSupplyMintable.abi.json](./dist/v1.0.2-rc.1/abi/ERC1155MaxSupplyMintable.abi.json) |
| [`0xf9a992a0e7D5C99033c6c256654458E29a296f3B`](https://sepolia-explorer.arbitrum.io/address/0xf9a992a0e7D5C99033c6c256654458E29a296f3B) | [ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)  | [ERC1155MaxSupplyMintable.abi.json](./dist/v1.0.2-rc.1/abi/ERC1155MaxSupplyMintable.abi.json) |
| [`0xE774ccc80519C6F74F7315fCd798E10Bca7Ba53e`](https://sepolia-explorer.arbitrum.io/address/0xE774ccc80519C6F74F7315fCd798E10Bca7Ba53e) | [ERC1155_MAX_SUPPLY_ADMIN_MINTABLE](./src/nfts/ERC1155AdminMinter.sol)             | [ERC1155AdminMinter.abi.json](./dist/v1.0.2-rc.1/abi/ERC1155AdminMinter.abi.json)             |
| [`0xb2Be249fbf8E3502967Fdff3eB112c744408769A`](https://sepolia-explorer.arbitrum.io/address/0xb2Be249fbf8E3502967Fdff3eB112c744408769A) | [ERC1155_AUTO_GRAPH_MINTER](./src/nfts/ERC1155AutoGraphMinter.sol)                 | [ERC1155AutoGraphMinter.abi.json](./dist/v1.0.2-rc.1/abi/ERC1155AutoGraphMinter.abi.json)     |
| [`0x6e6eb0Df27EC2C79488f83aC2D129e9055A9DCa3`](https://sepolia-explorer.arbitrum.io/address/0x6e6eb0Df27EC2C79488f83aC2D129e9055A9DCa3) | [GAME_CONSUMABLE](./src/game/GameConsumer.sol)                                     | [GameConsumer.abi.json](./dist/v1.0.2-rc.1/abi/GameConsumer.abi.json)                         |
| [`0x227d544D097bbBE10748592F3ceC63C66Ac0d1D7`](https://sepolia-explorer.arbitrum.io/address/0x227d544D097bbBE10748592F3ceC63C66Ac0d1D7) | [TOKEN](./src/token/Token.sol)                                                     | [Token.abi.json](./dist/v1.0.2-rc.1/abi/Token.abi.json)                                       |

### Arbitrum

| Address                                                                                                                | Contract                                                                         | ABI                                                                                      |
|------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| [`0xb2F009749260ddbEFe5E1687895f0A0E411613EA`](https://arbiscan.io/address/0xb2F009749260ddbEFe5E1687895f0A0E411613EA) | [CORE](./src/core/Core.sol)                                                      | [Core.abi.json](./dist/v1.0.1/abi/Core.abi.json)                                         |
| [`0x90eAa68fAe4703ff5328f2E86982e77EBc10539a`](https://arbiscan.io/address/0x90eAa68fAe4703ff5328f2E86982e77EBc10539a) | [GLOBAL_REENTRANCY_LOCK](./src/utils/GlobalReentrancyLock.sol)                   | [GlobalReentrancyLock.abi.json](./dist/v1.0.1/abi/GlobalReentrancyLock.abi.json)         |
| [`0x792E36c772f6dA6280fa43159792F89e7444CF18`](https://arbiscan.io/address/0x792E36c772f6dA6280fa43159792F89e7444CF18) | [ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES](./src/nfts/ERC1155MaxSupplyMintable.sol) | [ERC1155MaxSupplyMintable.abi.json](./dist/v1.0.1/abi/ERC1155MaxSupplyMintable.abi.json) |
| [`0xd778a415A3AB81eF27da61218c71a5F31A4D10BE`](https://arbiscan.io/address/0xd778a415A3AB81eF27da61218c71a5F31A4D10BE) | [ERC1155_MAX_SUPPLY_ADMIN_MINTABLE](./src/nfts/ERC1155AdminMinter.sol)           | [ERC1155AdminMinter.abi.json](./dist/v1.0.1/abi/ERC1155AdminMinter.abi.json)             |
| [`0x2Fd9c72Ea5763340e96e9369226032C38CF7a1da`](https://arbiscan.io/address/0x2Fd9c72Ea5763340e96e9369226032C38CF7a1da) | [ZTX HOODIE](./src/nfts/ERC721ZepetoUA.sol)                                      | [ERC721ZepetoUA.abi.json](./dist/v1.0.1/abi/ERC721ZepetoUA.abi.json)                     |
| [`0x1C43D05be7E5b54D506e3DdB6f0305e8A66CD04e`](https://arbiscan.io/address/0x1C43D05be7E5b54D506e3DdB6f0305e8A66CD04e) | [TOKEN](./src/token/Token.sol)                                                   | [Token.abi.json](./dist/v1.0.1/abi/Token.abi.json)                                       |
