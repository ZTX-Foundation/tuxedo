# Tuxedo

Solidity smart contracts for ZTX.

## Dependencies

-   [Foundry](https://github.com/foundry-rs/foundry)
-   [npm](https://docs.npmjs.com/getting-started)
-   [Slither](https://github.com/crytic/slither)

## Documentation

For further details, see the [docs](./doc/contracts).

## Setup

```console
npm install
```

The system also requires the following environment variables to be set:

| Variable             | Description                                                           |
|----------------------|-----------------------------------------------------------------------|
| `TOKEN_NAME`         | The name of the token (e.g. `ZTX Token`).                             |
| `TOKEN_SYMBOL`       | The symbol of the primay token (e.g. `ZTX`).                          |
| `DOMAIN`             | The domain of where the metadata is hosted.                           |
| `ENVIRONMENT`        | The environment of the deployment (`devnet`, `testnet` or `mainnet`). |
| `DEPLOY_PRIVATE_KEY` | The private key of the deployer.                                      |
| `MAINNET_RPC_URL`    | Arbitrum mainnet RPC host.                                            |
| `TESTNET_RPC_URL`    | Arbitrum testnet RPC host.                                            |

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
| `0xDe4d49cC1F2290F2E9c1819bB08fd9eE27e85e10` | [CORE](./src/core/Core.sol)                                                                                                                        |
| `0xbDa804c509876208B1427dDB9c3fA198bD592Dcc` | [GLOBAL_REENTRANCY_LOCK](./src/core/GlobalReentrancyLock.sol)                                                                                      |
| `0xcEe5a709Cc84602682ba1daa0D32160B877b7d23` | [ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                                 |
| `0x7F4947658C92bD6354aE86bb338B7D5EB4EcD4A5` | [ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                                  |
| `0x4fC879B3F1bb8042ba1355b626c09aCA860946a4` | [ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                                   |
| `0x048e3E22DbdA4a654D80A1Ad2c35d45CFB0DBE40` | [ERC1155_AUTO_GRAPH_MINTER](./src/nfts/ERC1155AutoGraphMinter.sol)                                                                                 |
| `0xa4BDe75354C3676501089F276742B0E0A4A33b01` | [WETH_ERC20_HOLDING_DEPOSIT](./src/finance/ERC20HoldingDeposit.sol)                                                                                |
| `0xFc601A8654aA5857C8C2336AA5f1EC9197e51450` | [ZTX HOODIE](./src/nfts/ERC721ZepetoUA.sol)                                                                                                        |
| `0x9481fB6dE0191d64056E6381fda01f5AD89C6438` | [ERC1155_SALE_CONSUMABLES](./src/sale/ERC1155Sale.sol)                                                                                             |
| `0x4576e12B73e8E6639379f03dfbD758D86D659557` | [ERC1155_SALE_PLACEABLES](./src/sale/ERC1155Sale.sol)                                                                                              |
| `0x2eDA363797939661Dbc9c60e7e952869F2b73A1B` | [ERC1155_SALE_WEARABLES](./src/sale/ERC1155Sale.sol)                                                                                               |
| `0x51939A75530ff4600795097574554BEa5be35BA9` | [FINANCE_GUARDIAN](./src/finance/FinanceGuardian.sol)                                                                                              |
| `0x01a283489544EF558034bcFF99DBA8F79467b4A7` | [TOKEN](./src/token/Token.sol)                                                                                                                     |
| `0x0CF950b4e2C939916E595070eC460BeFFA9A572a` | [GOVERNOR_DAO](./src/governance/GovernorDAO.sol)                                                                                                   |
| `0x0E01AAe38414611B446C0843b8bC491F67571615` | [GOVERNOR_DAO_TIMELOCK_CONTROLLER](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol) |
| `0x424d7CCceA75F1c42aF56fC223AD560e6eCaE6c3` | [ADMIN_TIMELOCK_CONTROLLER](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol)        |
| `0x96554C1D09907aC27a336e2300D082527163C7a7` | [BURNER_WALLET](./src/finance/ERC20HoldingDeposit.sol)                                                                                             |
| `0xFea3F87bbAcCa68D074AaD05f3891267A1D21a33` | [TREASURY_WALLET](./src/finance/ERC20HoldingDeposit.sol)                                                                                           |
| `0x71E1Fc5bb31e7a4891E1a611aD84E3BF145aa9A7` | [WETH_TREASURY_WALLET](./src/finance/ERC20HoldingDeposit.sol)                                                                                      |
| `0x346D3AAC8E2fA297ec26b37c3EFc331D08997990` | [CONSUMABLE_SPLITTER](./src/finance/ERC20Splitter.sol)                                                                                             |
| `0xdBF55CcC2D393444287dbfC60849da2E347A3cfD` | [ERC1155_SALE_SPLITTER](./src/finance/ERC20Splitter.sol)                                                                                           |
| `0xD406Ba326A187A8756fB096793b71b69Be3D91d5` | [GAME_CONSUMABLE](./src/game/GameConsumer.sol)                                                                                                     |

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
