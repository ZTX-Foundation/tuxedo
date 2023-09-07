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
| `0x227d544D097bbBE10748592F3ceC63C66Ac0d1D7` | [CORE](./src/core/Core.sol)                                                                                                                        |
| `0xD5dF2B57A10E7260DE561283E1274D1D2470cc15` | [GLOBAL_REENTRANCY_LOCK](./src/core/GlobalReentrancyLock.sol)                                                                                      |
| `0x312A00D9183c155Bac1eE736441536D8c15429D7` | [ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                                 |
| `0x7D0FAa703CD188a630b516a69Ceb2c87D9896DdA` | [ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                                  |
| `0xCC64Cd2e02a2F091D77df3F9554f5054f0883F0d` | [ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                                   |
| `0x6b8D486fD16f94811bC41f5129f1Ec076A76D385` | [ERC1155_AUTO_GRAPH_MINTER](./src/nfts/ERC1155AutoGraphMinter.sol)                                                                                 |
| `0x0224A8a1cc4156EeA54493Ef1Db5D181290A94b5` | [WETH_ERC20_HOLDING_DEPOSIT](./src/finance/ERC20HoldingDeposit.sol)                                                                                |
| `0xFc601A8654aA5857C8C2336AA5f1EC9197e51450` | [ZTX HOODIE](./src/nfts/ERC721ZepetoUA.sol)                                                                                                        |
| `0x0Bb86Cf23b9cF9F727C67D0AF0409f4a991de988` | [ERC1155_SALE_CONSUMABLES](./src/sale/ERC1155Sale.sol)                                                                                             |
| `0xbD87bf7b2d628aE24C44868561A3BaD49404a6e4` | [ERC1155_SALE_PLACEABLES](./src/sale/ERC1155Sale.sol)                                                                                              |
| `0x07650701Baae19F60B159fb4854E50D352D23b08` | [ERC1155_SALE_WEARABLES](./src/sale/ERC1155Sale.sol)                                                                                               |
| `0xff24A2b4Bab63b9148e4C20875b9285F081C3f7E` | [FINANCE_GUARDIAN](./src/finance/FinanceGuardian.sol)                                                                                              |
| `0xFB6dAAB27b8213eAe2F07F189A62736cE280f585` | [TOKEN](./src/token/Token.sol)                                                                                                                     |
| `0x0AeFc2E0eA3fBd336d89CdF8252f9dbd5f622E36` | [GOVERNOR_DAO](./src/governance/GovernorDAO.sol)                                                                                                   |
| `0xCF26151eaA0872A9e4048CC270975008b4Ddc42D` | [GOVERNOR_DAO_TIMELOCK_CONTROLLER](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol) |
| `0xbD7A47e81598a221cB5c915b48a52A696aFfbB80` | [ADMIN_TIMELOCK_CONTROLLER](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol)        |
| `0x8C227D6231C072ee17894D6298cCEe2133A7F48A` | [BURNER_WALLET](./src/finance/ERC20HoldingDeposit.sol)                                                                                             |
| `0x68D6B4af6668A62Fc1B21ABF3DbfA366DD1d8eC7` | [TREASURY_WALLET](./src/finance/ERC20HoldingDeposit.sol)                                                                                           |
| `0x87D7b991540747522404c86b281E4880Cd6dE7f2` | [WETH_TREASURY_WALLET](./src/finance/ERC20HoldingDeposit.sol)                                                                                      |
| `0xb26A67448a3F5aBC04245733357A5c779ed35eB8` | [CONSUMABLE_SPLITTER](./src/finance/ERC20Splitter.sol)                                                                                             |
| `0x358AD419A0EE85E6882E74d254575Cc2D5Fe636b` | [ERC1155_SALE_SPLITTER](./src/finance/ERC20Splitter.sol)                                                                                           |
| `0x8ee5a166A19A987bf3B874e44E1eE98EE346D75f` | [GAME_CONSUMABLE](./src/game/GameConsumer.sol)                                                                                                     |

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
