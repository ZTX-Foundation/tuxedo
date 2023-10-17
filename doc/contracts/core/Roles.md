# Roles.sol

## Introduction
Roles used by the ZTX protocol.

## Roles
### Major
- `GUARDIAN`: The protector role that has administrative powers over critical functionality such as pause, veto, revoke, and minor roles. This role should only be owned by a multisig, providing an additional layer of security and oversight.
- `MINTER`: The role that can mint tokens arbitrarily. This role should only be owned by a protocol contract, ensuring controlled and authorized token minting.
- `MINTER_NOTARY`: The role that can notarize a mint signature. This role is typically used by an off-chain service to create a unique signature for a mint transaction for later use.
- `FINANCIAL_CONTROLLER`: The role that can move funds out of deposits. This role should only be owned by a protocol contract, ensuring controlled and authorized fund movements.
- `FINANCIAL_GUARDIAN`: The role that can move faster to protect funds than the guardian. This role can be owned by an externally owned account (EOA) and provides an additional layer of control and security for financial operations.
- `LOCKER`: The role that can lock and unlock the global reentrancy lock. This role should only be owned by a protocol contract, ensuring secure management of reentrancy protection.
- `GAME_CONSUMER_NOTARY`: The role that acts as a notary for game consumers. This role can issue signatures for in-game crafting and speed-ups, enabling secure and authorized game-related operations.
- `REGISTRY_OPERATOR`: The role that can operator a registry contract. This role is typically used by a protocol contract.
### Admin
- `ADMIN`: The ultimate role that controls all other roles and protocol functionality. This role should only be owned by a multisig or a timelock contract, ensuring careful management and control. Can revoke other roles and itself.
- `TOKEN_GOVERNOR`: The token governance role that allows ZTX token holders to vote on proposals to change the protocol. This role should also only be owned by a timelock contract, ensuring secure and deliberate governance decisions.
