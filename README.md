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

| Address                                                                                                                       | Contract                                                                           | ABI                                                                                           |
|-------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| [`0x27c10c0af3Ab74B789aA31b20FFdcF5C87d3737C`](https://goerli.arbiscan.io/address/0x27c10c0af3Ab74B789aA31b20FFdcF5C87d3737C) | [CORE](./src/core/Core.sol)                                                        | [Core.abi.json](./dist/v1.0.0-rc.2/abi/Core.abi.json)                                         |
| [`0x6820c0dF420e8bce0408eA09822E7B12a58F45D6`](https://goerli.arbiscan.io/address/0x6820c0dF420e8bce0408eA09822E7B12a58F45D6) | [GLOBAL_REENTRANCY_LOCK](./src/core/GlobalReentrancyLock.sol)                      | [GlobalReentrancyLock.abi.json](./dist/v1.0.0-rc.2/abi/GlobalReentrancyLock.abi.json)         |
| [`0x0D1485e5C5c43610e45A7951271599Ad89477207`](https://goerli.arbiscan.io/address/0x0D1485e5C5c43610e45A7951271599Ad89477207) | [ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)   | [ERC1155MaxSupplyMintable.abi.json](./dist/v1.0.0-rc.2/abi/ERC1155MaxSupplyMintable.abi.json) |
| [`0x3F5DEdE9A945887C60b64EC82F758a6249d109bf`](https://goerli.arbiscan.io/address/0x3F5DEdE9A945887C60b64EC82F758a6249d109bf) | [ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES](./src/nfts/ERC1155MaxSupplyMintable.sol) | [ERC1155MaxSupplyMintable.abi.json](./dist/v1.0.0-rc.2/abi/ERC1155MaxSupplyMintable.abi.json) |
| [`0xdC00e09fa79EC1a4489EDa68Bc911073cEad2c6c`](https://goerli.arbiscan.io/address/0xdC00e09fa79EC1a4489EDa68Bc911073cEad2c6c) | [ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)  | [ERC1155MaxSupplyMintable.abi.json](./dist/v1.0.0-rc.2/abi/ERC1155MaxSupplyMintable.abi.json) |
| [`0x8d073006E834F5C69D4f7463Ba302cd7Db947029`](https://goerli.arbiscan.io/address/0x8d073006E834F5C69D4f7463Ba302cd7Db947029) | [SEASONS_TOKEN_ID_REGISTRY](./src/nfts/seasons/SeasonsTokenIdRegistry.sol)         | [SeasonsTokenIdRegistry.abi.json](./dist/v1.0.0-rc.2/abi/SeasonsTokenIdRegistry.abi.json)     |
| [`0xB0D993F3a431A8eEE85D439Deea6c847f45BB9d9`](https://goerli.arbiscan.io/address/0xB0D993F3a431A8eEE85D439Deea6c847f45BB9d9) | [ERC1155_SEASON_ONE](./src/nfts/seasons/ERC1155SeasonOne.sol)                      | [ERC1155SeasonOne.abi.json](./dist/v1.0.0-rc.2/abi/ERC1155SeasonOne.abi.json)                 |
| [`0xacd649320A6229f14D67f78e6541c8b45a21D8Ba`](https://goerli.arbiscan.io/address/0xacd649320A6229f14D67f78e6541c8b45a21D8Ba) | [ERC1155_MAX_SUPPLY_ADMIN_MINTER](./src/nfts/ERC1155AdminMinter.sol)               | [ERC1155AdminMinter.abi.json](./dist/v1.0.0-rc.2/abi/ERC1155AdminMinter.abi.json)             |
| [`0xb352F8Da6a69aC73e638f8d3798Cb52a91D40D1a`](https://goerli.arbiscan.io/address/0xb352F8Da6a69aC73e638f8d3798Cb52a91D40D1a) | [ERC1155_AUTO_GRAPH_MINTER](./src/nfts/ERC1155AutoGraphMinter.sol)                 | [ERC1155AutoGraphMinter.abi.json](./dist/v1.0.0-rc.2/abi/ERC1155AutoGraphMinter.abi.json)     |
| [`0xFc601A8654aA5857C8C2336AA5f1EC9197e51450`](https://goerli.arbiscan.io/address/0xFc601A8654aA5857C8C2336AA5f1EC9197e51450) | [ZTX HOODIE](./src/nfts/ERC721ZepetoUA.sol)                                        | [ERC721ZepetoUA.abi.json](./dist/v1.0.0-rc.2/abi/ERC721ZepetoUA.abi.json)                     |
| [`0x80602B72cc5D87e99441F5926994c493d115D148`](https://goerli.arbiscan.io/address/0x80602B72cc5D87e99441F5926994c493d115D148) | [TOKEN](./src/token/Token.sol)                                                     | [Token.abi.json](./dist/v1.0.0-rc.2/abi/Token.abi.json)                                       |
| [`0x853e2e1fFF72a7B2350dEa202A0fa7C42AA4b42D`](https://goerli.arbiscan.io/address/0x853e2e1fFF72a7B2350dEa202A0fa7C42AA4b42D) | [GAME_CONSUMABLE](./src/game/GameConsumer.sol)                                     | [GameConsumer.abi.json](./dist/v1.0.0-rc.2/abi/GameConsumer.abi.json)                         |

### Arbitrum Sepolia (testnet)

| Address                                                                                                                                 | Contract                                                                           | ABI                                                                                           |
|-----------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| [`0x68D6B4af6668A62Fc1B21ABF3DbfA366DD1d8eC7`](https://sepolia-explorer.arbiscan.io/address/0x68D6B4af6668A62Fc1B21ABF3DbfA366DD1d8eC7) | [CORE](./src/core/Core.sol)                                                        | [Core.abi.json](./dist/v1.0.0-rc.2/abi/Core.abi.json)                                         |
| [`0x87D7b991540747522404c86b281E4880Cd6dE7f2`](https://sepolia-explorer.arbiscan.io/address/0x87D7b991540747522404c86b281E4880Cd6dE7f2) | [GLOBAL_REENTRANCY_LOCK](./src/core/GlobalReentrancyLock.sol)                      | [GlobalReentrancyLock.abi.json](./dist/v1.0.0-rc.2/abi/GlobalReentrancyLock.abi.json)         |
| [`0x27564B8cf86aba79b398A39B75898fe8AFf30627`](https://sepolia-explorer.arbiscan.io/address/0x27564B8cf86aba79b398A39B75898fe8AFf30627) | [ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)   | [ERC1155MaxSupplyMintable.abi.json](./dist/v1.0.0-rc.2/abi/ERC1155MaxSupplyMintable.abi.json) |
| [`0x898C5e72Cb4121A8ae579faEAe2C5879196493fc`](https://sepolia-explorer.arbiscan.io/address/0x898C5e72Cb4121A8ae579faEAe2C5879196493fc) | [ERC1155_MAX_SUPPLY_MINTABLE_CONSUMABLES](./src/nfts/ERC1155MaxSupplyMintable.sol) | [ERC1155MaxSupplyMintable.abi.json](./dist/v1.0.0-rc.2/abi/ERC1155MaxSupplyMintable.abi.json) |
| [`0xa7654c44f0A4Da52a10469dC380f02F75d6E0631`](https://sepolia-explorer.arbiscan.io/address/0xa7654c44f0A4Da52a10469dC380f02F75d6E0631) | [ERC1155_MAX_SUPPLY_MINTABLE_PLACEABLES](./src/nfts/ERC1155MaxSupplyMintable.sol)  | [ERC1155MaxSupplyMintable.abi.json](./dist/v1.0.0-rc.2/abi/ERC1155MaxSupplyMintable.abi.json) |
| [`0x8ccE22Fe7Bd3F4998E158De3c3a77ee85A6F6bBB`](https://sepolia-explorer.arbiscan.io/address/0x8ccE22Fe7Bd3F4998E158De3c3a77ee85A6F6bBB) | [SEASONS_TOKEN_ID_REGISTRY](./src/nfts/seasons/SeasonsTokenIdRegistry.sol)         | [SeasonsTokenIdRegistry.abi.json](./dist/v1.0.0-rc.2/abi/SeasonsTokenIdRegistry.abi.json)     |
| [`0x3006b30E32dEA503503Bf9e3f909163834085A5C`](https://sepolia-explorer.arbiscan.io/address/0x3006b30E32dEA503503Bf9e3f909163834085A5C) | [ERC1155_SEASON_ONE](./src/nfts/seasons/ERC1155SeasonOne.sol)                      | [ERC1155SeasonOne.abi.json](./dist/v1.0.0-rc.2/abi/ERC1155SeasonOne.abi.json)                 |
| [`0x34c775910e5CbB1511eF00Ea51cd0f6bd1E3E4Db`](https://sepolia-explorer.arbiscan.io/address/0x34c775910e5CbB1511eF00Ea51cd0f6bd1E3E4Db) | [ERC1155_MAX_SUPPLY_ADMIN_MINTER](./src/nfts/ERC1155AdminMinter.sol)               | [ERC1155AdminMinter.abi.json](./dist/v1.0.0-rc.2/abi/ERC1155AdminMinter.abi.json)             |
| [`0x2a7093311D65550285AcA9650C9F9165f74337f3`](https://sepolia-explorer.arbiscan.io/address/0x2a7093311D65550285AcA9650C9F9165f74337f3) | [ERC1155_AUTO_GRAPH_MINTER](./src/nfts/ERC1155AutoGraphMinter.sol)                 | [ERC1155AutoGraphMinter.abi.json](./dist/v1.0.0-rc.2/abi/ERC1155AutoGraphMinter.abi.json)     |
| [`0x5422a3De80BA3891d663fa4EC7506A7f263c1Fd9`](https://sepolia-explorer.arbiscan.io/address/0x5422a3De80BA3891d663fa4EC7506A7f263c1Fd9) | [TOKEN](./src/token/Token.sol)                                                     | [Token.abi.json](./dist/v1.0.0-rc.2/abi/Token.abi.json)                                       |
| [`0xf052f3F94f6E71DfBA39544b8DF02c873De4469F`](https://sepolia-explorer.arbiscan.io/address/0xf052f3F94f6E71DfBA39544b8DF02c873De4469F) | [GAME_CONSUMABLE](./src/game/GameConsumer.sol)                                     | [GameConsumer.abi.json](./dist/v1.0.0-rc.2/abi/GameConsumer.abi.json)                         |   

### Arbitrum

| Address                                                                                                                | Contract                                                                         | ABI                                                                                      |
|------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| [`0xb2F009749260ddbEFe5E1687895f0A0E411613EA`](https://arbiscan.io/address/0xb2F009749260ddbEFe5E1687895f0A0E411613EA) | [CORE](./src/core/Core.sol)                                                      | [Core.abi.json](./dist/v1.0.1/abi/Core.abi.json)                                         |
| [`0x90eAa68fAe4703ff5328f2E86982e77EBc10539a`](https://arbiscan.io/address/0x90eAa68fAe4703ff5328f2E86982e77EBc10539a) | [GLOBAL_REENTRANCY_LOCK](./src/utils/GlobalReentrancyLock.sol)                   | [GlobalReentrancyLock.abi.json](./dist/v1.0.1/abi/GlobalReentrancyLock.abi.json)         |
| [`0x792E36c772f6dA6280fa43159792F89e7444CF18`](https://arbiscan.io/address/0x792E36c772f6dA6280fa43159792F89e7444CF18) | [ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES](./src/nfts/ERC1155MaxSupplyMintable.sol) | [ERC1155MaxSupplyMintable.abi.json](./dist/v1.0.1/abi/ERC1155MaxSupplyMintable.abi.json) |
| [`0xd778a415A3AB81eF27da61218c71a5F31A4D10BE`](https://arbiscan.io/address/0xd778a415A3AB81eF27da61218c71a5F31A4D10BE) | [ERC1155_MAX_SUPPLY_ADMIN_MINTABLE](./src/nfts/ERC1155AdminMinter.sol)           | [ERC1155AdminMinter.abi.json](./dist/v1.0.1/abi/ERC1155AdminMinter.abi.json)             |
| [`0x2Fd9c72Ea5763340e96e9369226032C38CF7a1da`](https://arbiscan.io/address/0x2Fd9c72Ea5763340e96e9369226032C38CF7a1da) | [ZTX HOODIE](./src/nfts/ERC721ZepetoUA.sol)                                      | [ERC721ZepetoUA.abi.json](./dist/v1.0.1/abi/ERC721ZepetoUA.abi.json)                     |
| [`0x1C43D05be7E5b54D506e3DdB6f0305e8A66CD04e`](https://arbiscan.io/address/0x1C43D05be7E5b54D506e3DdB6f0305e8A66CD04e) | [TOKEN](./src/token/Token.sol)                                                   | [Token.abi.json](./dist/v1.0.1/abi/Token.abi.json)                                       |
