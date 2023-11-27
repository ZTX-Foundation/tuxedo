// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/**
 @title ACL Roles
 @notice Holds a complete list of all roles which can be held by addresses.
         Roles are broken up into 2 categories:
         * Multisig Roles - Multisig roles are roles which are owned by multisig wallets
                           and are used to control multisig functionality. 
         * Protocol Roles - roles which are owned by protocol contracts and are used to
                           control protocol functionality.
 @dev   Due to a in flight change to the role names, the keccak256 string do not match the namning convention
        the names are correct, but the keccak256 strings are not. 
        As we didnt want to create a new hash and have to then redeploy the whole system 
 */
library Roles {
    /*///////////////////////////////////////////////////////////////
                                 Multisig Roles
    //////////////////////////////////////////////////////////////*/

    /// @notice the ultimate role. Controls all other roles and protocol functionality.
    /// should only be owned by a multisig and or timelock
    bytes32 internal constant ADMIN = keccak256("ADMIN_ROLE");

    /// @notice the protector role. Admin of pause, veto, revoke, and minor roles
    /// should only be owned by a multisig
    bytes32 internal constant GUARDIAN = keccak256("GUARDIAN_ROLE");

    /*///////////////////////////////////////////////////////////////
                                 Protocol Roles
    //////////////////////////////////////////////////////////////*/

    /// @notice the token governance role. Token holders can vote on proposals to change the protocol
    /// should only be owned by a timelock
    bytes32 internal constant GOVERNOR_DAO_PROTOCOL_ROLE = keccak256("TOKEN_GOVERNOR_ROLE");

    /// @notice can move funds out of Finance Deposits that implement the IDepositBase interface
    /// should only be owned by a protocol contract
    bytes32 internal constant FINANCIAL_CONTROLLER_PROTOCOL_ROLE = keccak256("FINANCIAL_CONTROLLER_ROLE");

    /// @notice can mint tokens arbitrarily
    /// should only be owned by a protocol contract
    bytes32 internal constant MINTER_PROTOCOL_ROLE = keccak256("MINTER_ROLE");

    /// @notice can operate a registry contract
    /// should only be owned by a protocol contract
    bytes32 internal constant REGISTRY_OPERATOR_PROTOCOL_ROLE = keccak256("REGISTRY_OPERATOR_ROLE");

    /// @notice can notarize a mint signature
    /// to be used by an offchain service to create a unique signature for a mint transaction for later use
    bytes32 internal constant MINTER_NOTARY_PROTOCOL_ROLE = keccak256("MINTER_NOTARY_ROLE");

    /// @notice can lock and unlock the global reentrancy lock
    /// should only be owned by a protocol contract
    /// protocol roles are only protocols, no assignments to multisigs
    bytes32 internal constant LOCKER_PROTOCOL_ROLE = keccak256("LOCKER_ROLE");

    /// @notice game consumer notary role.
    /// can issue signatures for in-game crafting and speed ups
    bytes32 internal constant GAME_CONSUMER_NOTARY_PROTOCOL_ROLE = keccak256("GAME_CONSUMER_NOTARY_ROLE");
}
