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
| `0xdde8cF29ee078B5a82C88d6Cf7CBF9600c4Cf81e` | [GAME_CONSUMABLE](./src/game/GameConsumer.sol)                                                                                                     |

### Arbitrum Sepolia (testnet)

| Address                                      | Contract                                                                                                                                           |
|----------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| `0xBee6a4a7d455da91CC4F592de64abC4C8956a5f8` | [CORE](./src/core/Core.sol)                                                                                                                        |
| `0xeE738d4D7bAcfe0f504fC7E4bAFC4e844Dc0CDa5` | [GLOBAL_REENTRANCY_LOCK](./src/utils/GlobalReentrancyLock.sol)                                                                                     |
| `0x54a53407f1d9407A194c78ec9A3e57Fe8664D373` | [ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                                 |
| `0x2008Eb5ADfEd869eDc19CE8C2A9D78F2391e2fa1` | [ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                                  |
| `0x44b6dED0Abc55e2052aE266BC1E0Fa73c511c8F5` | [ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                                   |
| `0x792d996E2dC2aadccFEc7A7783c163eB1ABd5d22` | [ERC1155_AUTO_GRAPH_MINTER](./src/nfts/ERC1155AutoGraphMinter.sol)                                                                                 |
| `0x4E808045eE63d89D0E90560FA9c067b1BB4bDa58` | [WETH_ERC20_HOLDING_DEPOSIT](./src/finance/ERC20HoldingDeposit.sol)                                                                                |
| `0x4cec890691E53E29d59E8fF2f81Dd5253e3F2f1c` | [ERC1155_SALE_CONSUMABLES](./src/sale/ERC1155Sale.sol)                                                                                             |
| `0x4f7966430b53D4d31A2e27d81a8111B039A38B46` | [ERC1155_SALE_PLACEABLES](./src/sale/ERC1155Sale.sol)                                                                                              |
| `0x3508910FFdB9CFF8C0C831e2Ad7001cbD3004469` | [ERC1155_SALE_WEARABLES](./src/sale/ERC1155Sale.sol)                                                                                               |
| `0x15F6251189FeBbcD2fF317365Cc5470Af9b60479` | [FINANCE_GUARDIAN](./src/finance/FinanceGuardian.sol)                                                                                              |
| `0x55b115B842E1C0C64c56FBed6a7460EbaFbA4b08` | [TOKEN](./src/token/Token.sol)                                                                                                                     |
| `0x1De18087387aeae9b2AF9469F1909e3C7C30E024` | [GOVERNOR_DAO](./src/governance/GovernorDAO.sol)                                                                                                   |
| `0xebd85F2879385bc0D9A845de2fb455c357ED560c` | [GOVERNOR_DAO_TIMELOCK_CONTROLLER](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol) |
| `0xA769eF67a43998B39F3C2E0602aA7ebA97cB4f92` | [ADMIN_TIMELOCK_CONTROLLER](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol)        |
| `0x46aDA2a81c6Ce36a871FF300A4017D49315EE703` | [BURNER_WALLET](./src/finance/ERC20HoldingDeposit.sol)                                                                                             |
| `0xBFAC6306884fDb2AB03C1496492C0a83C3698c4e` | [TREASURY_WALLET](./src/finance/ERC20HoldingDeposit.sol)                                                                                           |
| `0xb5abd20C34a01380e6A8de3387342efCD10bdf99` | [WETH_TREASURY_WALLET](./src/finance/ERC20HoldingDeposit.sol)                                                                                      |
| `0xaeF3AeF1C1869834E6b6523F28033E442897f775` | [CONSUMABLE_SPLITTER](./src/finance/ERC20Splitter.sol)                                                                                             |
| `0xc2FBCA41B9dbb7debE9E5Ce349708602E441C608` | [ERC1155_SALE_SPLITTER](./src/finance/ERC20Splitter.sol)                                                                                           |
| `0x21d993233a9E5F7E3C5F9Ca57d0c103273427840` | [GAME_CONSUMABLE](./src/game/GameConsumer.sol)                                                                                                     |

### Arbitrum

| Address                                      | Contract                                    |
|----------------------------------------------|---------------------------------------------|
| `0x2Fd9c72Ea5763340e96e9369226032C38CF7a1da` | [ZTX HOODIE](./src/nfts/ERC721ZepetoUA.sol) |
