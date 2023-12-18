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

### Arbitrum Sepolia (testnet)

| Address                                                                                                                                 | Contract                                                                           | ABI                                                                                      |
|-----------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| [`0x68D6B4af6668A62Fc1B21ABF3DbfA366DD1d8eC7`](https://sepolia-explorer.arbitrum.io/address/0x68D6B4af6668A62Fc1B21ABF3DbfA366DD1d8eC7) | [CORE](./src/core/Core.sol)                                                        | [Core.abi.json](./dist/v1.0.0/abi/Core.abi.json)                                         |
| [`0x87D7b991540747522404c86b281E4880Cd6dE7f2`](https://sepolia-explorer.arbitrum.io/address/0x87D7b991540747522404c86b281E4880Cd6dE7f2) | [GLOBAL_REENTRANCY_LOCK](./src/core/GlobalReentrancyLock.sol)                      | [GlobalReentrancyLock.abi.json](./dist/v1.0.0/abi/GlobalReentrancyLock.abi.json)         |
| [`0x27564B8cf86aba79b398A39B75898fe8AFf30627`](https://sepolia-explorer.arbitrum.io/address/0x27564B8cf86aba79b398A39B75898fe8AFf30627) | [ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)   | [ERC1155MaxSupplyMintable.abi.json](./dist/v1.0.0/abi/ERC1155MaxSupplyMintable.abi.json) |
| [`0x898C5e72Cb4121A8ae579faEAe2C5879196493fc`](https://sepolia-explorer.arbitrum.io/address/0x898C5e72Cb4121A8ae579faEAe2C5879196493fc) | [ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES](./src/nfts/ERC1155MaxSupplyMintable.sol) | [ERC1155MaxSupplyMintable.abi.json](./dist/v1.0.0/abi/ERC1155MaxSupplyMintable.abi.json) |
| [`0xa7654c44f0A4Da52a10469dC380f02F75d6E0631`](https://sepolia-explorer.arbitrum.io/address/0xa7654c44f0A4Da52a10469dC380f02F75d6E0631) | [ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)  | [ERC1155MaxSupplyMintable.abi.json](./dist/v1.0.0/abi/ERC1155MaxSupplyMintable.abi.json) |
| [`0x8ccE22Fe7Bd3F4998E158De3c3a77ee85A6F6bBB`](https://sepolia-explorer.arbitrum.io/address/0x8ccE22Fe7Bd3F4998E158De3c3a77ee85A6F6bBB) | [SEASONS_TOKEN_ID_REGISTRY](./src/nfts/seasons/SeasonsTokenIdRegistry.sol)         | [SeasonsTokenIdRegistry.abi.json](./dist/v1.0.0/abi/SeasonsTokenIdRegistry.abi.json)     |
| [`0x3006b30E32dEA503503Bf9e3f909163834085A5C`](https://sepolia-explorer.arbitrum.io/address/0x3006b30E32dEA503503Bf9e3f909163834085A5C) | [ERC1155_SEASON_ONE](./src/nfts/seasons/ERC1155SeasonOne.sol)                      | [ERC1155SeasonOne.abi.json](./dist/v1.0.0/abi/ERC1155SeasonOne.abi.json)                 |
| [`0x34c775910e5CbB1511eF00Ea51cd0f6bd1E3E4Db`](https://sepolia-explorer.arbitrum.io/address/0x34c775910e5CbB1511eF00Ea51cd0f6bd1E3E4Db) | [ERC1155_MAX_SUPPLY_ADMIN_MINTER](./src/nfts/ERC1155AdminMinter.sol)               | [ERC1155AdminMinter.abi.json](./dist/v1.0.0/abi/ERC1155AdminMinter.abi.json)             |
| [`0x2a7093311D65550285AcA9650C9F9165f74337f3`](https://sepolia-explorer.arbitrum.io/address/0x2a7093311D65550285AcA9650C9F9165f74337f3) | [ERC1155_AUTO_GRAPH_MINTER](./src/nfts/ERC1155AutoGraphMinter.sol)                 | [ERC1155AutoGraphMinter.abi.json](./dist/v1.0.0/abi/ERC1155AutoGraphMinter.abi.json)     |
| [`0x5422a3De80BA3891d663fa4EC7506A7f263c1Fd9`](https://sepolia-explorer.arbitrum.io/address/0x5422a3De80BA3891d663fa4EC7506A7f263c1Fd9) | [TOKEN](./src/token/Token.sol)                                                     | [Token.abi.json](./dist/v1.0.0/abi/Token.abi.json)                                       |
| [`0xf052f3F94f6E71DfBA39544b8DF02c873De4469F`](https://sepolia-explorer.arbitrum.io/address/0xf052f3F94f6E71DfBA39544b8DF02c873De4469F) | [GAME_CONSUMABLE](./src/game/GameConsumer.sol)                                     | [GameConsumer.abi.json](./dist/v1.0.0/abi/GameConsumer.abi.json)                         |

### Arbitrum

| Address                                                                                                                | Contract                                                                                                                                    | ABI                                                                                      |
|------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| [`0xb2F009749260ddbEFe5E1687895f0A0E411613EA`](https://arbiscan.io/address/0xb2F009749260ddbEFe5E1687895f0A0E411613EA) | [CORE](./src/core/Core.sol)                                                                                                                 | [Core.abi.json](./dist/v1.0.0/abi/Core.abi.json)                                         |
| [`0x90eAa68fAe4703ff5328f2E86982e77EBc10539a`](https://arbiscan.io/address/0x90eAa68fAe4703ff5328f2E86982e77EBc10539a) | [GLOBAL_REENTRANCY_LOCK](./src/utils/GlobalReentrancyLock.sol)                                                                              | [GlobalReentrancyLock.abi.json](./dist/v1.0.0/abi/GlobalReentrancyLock.abi.json)         |
| [`0x792E36c772f6dA6280fa43159792F89e7444CF18`](https://arbiscan.io/address/0x792E36c772f6dA6280fa43159792F89e7444CF18) | [ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                            | [ERC1155MaxSupplyMintable.abi.json](./dist/v1.0.0/abi/ERC1155MaxSupplyMintable.abi.json) |
| [`0x163b2E7696F661F86DBB39Ce4b03e38Bfe22a1C9`](https://arbiscan.io/address/0x163b2E7696F661F86DBB39Ce4b03e38Bfe22a1C9) | [ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                          | [ERC1155MaxSupplyMintable.abi.json](./dist/v1.0.0/abi/ERC1155MaxSupplyMintable.abi.json) |
| [`0x2C154Ae907652A1a9939DBe0622915111816942C`](https://arbiscan.io/address/0x2C154Ae907652A1a9939DBe0622915111816942C) | [ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)                                                           | [ERC1155MaxSupplyMintable.abi.json](./dist/v1.0.0/abi/ERC1155MaxSupplyMintable.abi.json) |
| [`0x5cb7431a545523F25AbD3948c648329636a4b1E5`](https://arbiscan.io/address/0x5cb7431a545523F25AbD3948c648329636a4b1E5) | [SEASONS_TOKEN_ID_REGISTRY](./src/nfts/seasons/SeasonsTokenIdRegistry.sol)                                                                  | [SeasonsTokenIdRegistry.abi.json](./dist/v1.0.0/abi/SeasonsTokenIdRegistry.abi.json)     |
| [`0x59AFA38214C9CCCFB56f72DE7f9a2B47fA17C270`](https://arbiscan.io/address/0x59AFA38214C9CCCFB56f72DE7f9a2B47fA17C270) | [ERC1155_SEASON_ONE](./src/nfts/seasons/ERC1155SeasonOne.sol)                                                                               | [ERC1155SeasonOne.abi.json](./dist/v1.0.0/abi/ERC1155SeasonOne.abi.json)                 |
| [`0xd778a415A3AB81eF27da61218c71a5F31A4D10BE`](https://arbiscan.io/address/0xd778a415A3AB81eF27da61218c71a5F31A4D10BE) | [ERC1155_MAX_SUPPLY_ADMIN_MINTABLE](./src/nfts/ERC1155AdminMinter.sol)                                                                      | [ERC1155AdminMinter.abi.json](./dist/v1.0.0/abi/ERC1155AdminMinter.abi.json)             |
| [`0xD031aD02aD4bADFc06b64ec64eBA32cFc781FB9b`](https://arbiscan.io/address/0xD031aD02aD4bADFc06b64ec64eBA32cFc781FB9b) | [ERC1155_AUTO_GRAPH_MINTER](./src/nfts/ERC1155AutoGraphMinter.sol)                                                                          | [ERC1155AutoGraphMinter.abi.json](./dist/v1.0.0/abi/ERC1155AutoGraphMinter.abi.json)     |
| [`0x2Fd9c72Ea5763340e96e9369226032C38CF7a1da`](https://arbiscan.io/address/0x2Fd9c72Ea5763340e96e9369226032C38CF7a1da) | [ZTX HOODIE](./src/nfts/ERC721ZepetoUA.sol)                                                                                                 | [ERC721ZepetoUA.abi.json](./dist/v1.0.0/abi/ERC721ZepetoUA.abi.json)                     |
| [`0x1C43D05be7E5b54D506e3DdB6f0305e8A66CD04e`](https://arbiscan.io/address/0x1C43D05be7E5b54D506e3DdB6f0305e8A66CD04e) | [TOKEN](./src/token/Token.sol)                                                                                                              | [Token.abi.json](./dist/v1.0.0/abi/Token.abi.json)                                       |
| [`0xeD3ed10Bd8FD4093528B38B6fD7c5a5C616EB28f`](https://arbiscan.io/address/0xeD3ed10Bd8FD4093528B38B6fD7c5a5C616EB28f) | [GAME_CONSUMABLE](./src/game/GameConsumer.sol)                                                                                              | [GameConsumer.abi.json](./dist/v1.0.0/abi/GameConsumer.abi.json)                         |
| [`0x85454964Db79620e239C5425F047eAAe027d0E08`](https://arbiscan.io/address/0x85454964Db79620e239C5425F047eAAe027d0E08) | [CONSUMABLE_SPLITTER](./src/finance/ERC20Splitter.sol)                                                                                      | [ERC20Splitter.abi.json](./dist/v1.0.0/abi/ERC20Splitter.abi.json)                       |
| [`0xf16A0E806A4CF6e9031A0dA028c80eF8A771aE48`](https://arbiscan.io/address/0xf16A0E806A4CF6e9031A0dA028c80eF8A771aE48) | [ADMIN_TIMELOCK_CONTROLLER](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol) | [TimelockController.abi.json](./dist/v1.0.0/abi/TimelockController.abi.json)             | 
