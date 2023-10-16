# IActualERC721Staking.sol

## Introduction
An interface for defining how `ActualERC721Staking` functions. Please see [ActualERC721Staking.sol](./ActualERC721Staking.md) for more details.

## Events
### `Staked`
Emitted when a user stakes NFTs.
Logs:
- `user`: Address of the user who staked NFTs.
- `amount`: Amount of NFTs staked.
- `tokenIds`: IDs of the NFTs staked.
### `Withdrawn`
Emitted when a user withdraws NFTs.
Logs:
- `user`: Address of the user who withdrew NFTs.
- `amount`: Amount of NFTs withdrawn.
- `tokenIds`: IDs of the NFTs withdrawn.
### `EpochCreated`
Emitted when a new epoch is created.
Logs:
- `epoch`: The epoch number.
- `epochStart`: The start time of the epoch.
- `epochDuration`: The duration of the epoch.
