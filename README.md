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
| `0xB4caf09D4C48F57BAe0F6855BDB35578cb209d9B` | [CORE](./src/core/Core.sol)                                                                                                                        |
| `0x4C8e3dE76a28dd2fD3A9f97309e65e55250b292B` | [GLOBAL_REENTRANCY_LOCK](./src/core/GlobalReentrancyLock.sol)                                                                                      |
| `0xF80C85400dE2A07A86A09A7C16B5F31839e853A9` | [ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                                 |
| `0x1C7dc2028cE530D068368eB6786f9d70a757Ed62` | [ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                                  |
| `0xEa76Ea43146ecd6DdB5f946C8C8B3951464A6872` | [ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                                   |
| `0xf6477b6A2bC62E857B41ba51E7f23E5FAf23B261` | [ERC1155_AUTO_GRAPH_MINTER](./src/nfts/ERC1155AutoGraphMinter.sol)                                                                                 |
| `0xa3794C22BAC59a0953144d1E9E9190ccC0f71122` | [WETH_ERC20_HOLDING_DEPOSIT](./src/finance/ERC20HoldingDeposit.sol)                                                                                |
| `0xFc601A8654aA5857C8C2336AA5f1EC9197e51450` | [ZTX HOODIE](./src/nfts/ERC721ZepetoUA.sol)                                                                                                        |
| `0x680F37C43dFBA1d7548967FEFbFC535B2d308288` | [ERC1155_SALE_CONSUMABLES](./src/sale/ERC1155Sale.sol)                                                                                             |
| `0xf0918056423c3E6874389Fb39c5a6062f6f9fD37` | [ERC1155_SALE_PLACEABLES](./src/sale/ERC1155Sale.sol)                                                                                              |
| `0x9277345CaBC05e3333072780B9FE485B540D414A` | [ERC1155_SALE_WEARABLES](./src/sale/ERC1155Sale.sol)                                                                                               |
| `0xe0664e399Df8956b480F6427C55c24524137C772` | [FINANCE_GUARDIAN](./src/finance/FinanceGuardian.sol)                                                                                              |
| `0xaF51C3dA399edE8053355CDd2EbDDE11Eb981811` | [TOKEN](./src/token/Token.sol)                                                                                                                     |
| `0x3Dd78251E48fc0E93b2Dd1D0aA8970cF59eF1315` | [GOVERNOR_DAO](./src/governance/GovernorDAO.sol)                                                                                                   |
| `0xc5a3897f039c8989CD4837521516Cdc2222E2D36` | [GOVERNOR_DAO_TIMELOCK_CONTROLLER](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol) |
| `0xb000d9c3D4893f552082f54798869Ad9cb880E79` | [ADMIN_TIMELOCK_CONTROLLER](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol)        |
| `0x13283881c765eC27C6F1eC5Bc3CbF2cDA70D11Fd` | [BURNER_WALLET](./src/finance/ERC20HoldingDeposit.sol)                                                                                             |
| `0x275769905723E8E6166Ae3b1beC0bD6ca2625759` | [TREASURY_WALLET](./src/finance/ERC20HoldingDeposit.sol)                                                                                           |
| `0x76418614d5F94CFD09974d35DC1D1d443aa4abC8` | [WETH_TREASURY_WALLET](./src/finance/ERC20HoldingDeposit.sol)                                                                                      |
| `0x72188A38E84a245A40F95a7eb7C9f80e13b8D710` | [CONSUMABLE_SPLITTER](./src/finance/ERC20Splitter.sol)                                                                                             |
| `0x4C084e0975674dfB0C1D45572DFcD32919Aa8058` | [ERC1155_SALE_SPLITTER](./src/finance/ERC20Splitter.sol)                                                                                           |
| `0x0B9905C4EC0BD8faBD905b1fD684aCd476338FE1` | [GAME_CONSUMABLE](./src/game/GameConsumer.sol)                                                                                                     |

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
