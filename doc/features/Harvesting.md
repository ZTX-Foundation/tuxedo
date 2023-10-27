# Harvesting

## Introduction
This feature covers the basics of harvesting from within the game, as it relates to the ZTX protocol contracts. Harvesting does not involve NFTs.

## Expedite
During the game, it's possible that a user may wish to expedite their harvesting for a fee. The fee can be paid in either `$ZTX` or `ETH`. The contract just takes payment and emits a `TakePayment` event. It does not change game state.

### Generate a signed hash
Before taking payment, you need to generate a signed hash. The hash must be signed by an EOA that has the `GAME_CONSUMER_NOTARY` role. The hash can be generated off-chain or on-chain. To generate the hash on-chain, you need to call `getHash()`. See [GameConsumer](../contracts/game/GameConsumer.md#gethash) for more details.

Refer to the [example scripts](../../script/utils/game) for more details on how to generate and sign a hash.

### Sequence
```mermaid
sequenceDiagram
    participant Client
    participant GameConsumer.sol
    Client->>+GameConsumer.sol: getHash()
    GameConsumer.sol->>-Client: return hash
    Client->>Client: sign hash
    alt
        Client->>+GameConsumer.sol: takePaymentWithETH()
        alt jobFee and hash are valid
            GameConsumer.sol->>Client: payment successful
            GameConsumer.sol->>GameConsumer.sol: emit TakePayment event
        else
            GameConsumer.sol->>-Client: revert
        end
    else
        Client->>+GameConsumer.sol: takePayment()
        alt hash is valid
            GameConsumer.sol->>Client: payment successful
            GameConsumer.sol->>GameConsumer.sol: emit TakePayment event
        else
            GameConsumer.sol->>-Client: revert
        end 
    end
```
