// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/**
 @title ACL Roles
 @notice Holds a complete list of all roles which can be held by addresses.
         Roles are broken up into 3 categories:
         * Major Roles - the most powerful roles which should be carefully managed.
         * Admin Roles - roles with management capability over critical functionality. Should only be held by automated or optimistic mechanisms
         * Minor Roles - operational roles. May be held or managed by shorter optimistic timelocks or trusted multisigs.
 */
library Roles {
    /*///////////////////////////////////////////////////////////////
                                 Major Roles
    //////////////////////////////////////////////////////////////*/

    /// @notice the ultimate role. Controls all other roles and protocol functionality.
    /// should only be owned by a multisig and or timelock
    bytes32 internal constant ADMIN = keccak256("ADMIN_ROLE");

    /// @notice the token governance role. Token holders can vote on proposals to change the protocol
    /// should only be owned by a timelock
    bytes32 internal constant TOKEN_GOVERNOR = keccak256("TOKEN_GOVERNOR_ROLE");

    /// @notice the protector role. Admin of pause, veto, revoke, and minor roles
    /// should only be owned by a multisig
    bytes32 internal constant GUARDIAN = keccak256("GUARDIAN_ROLE");

    /// @notice can mint tokens arbitrarily
    /// should only be owned by a protocol contract
    bytes32 internal constant MINTER = keccak256("MINTER_ROLE");

    /// @notice can operate a registry contract
    /// should only be owned by a protocol contract
    bytes32 internal constant REGISTRY_OPERATOR = keccak256("REGISTRY_OPERATOR_ROLE");

    /// @notice can notarize a mint signature
    /// to be used by an offchain service to create a unique signature for a mint transaction for later use
    bytes32 internal constant MINTER_NOTARY = keccak256("MINTER_NOTARY_ROLE");

    /// @notice can move funds out of Finance Deposits
    /// should only be owned by a protocol contract
    bytes32 internal constant FINANCIAL_CONTROLLER = keccak256("FINANCIAL_CONTROLLER_ROLE");

    /// @notice can move faster to protect funds than the guardian
    /// can be owned by an EOA
    bytes32 internal constant FINANCIAL_GUARDIAN = keccak256("FINANCIAL_GUARDIAN_ROLE");

    /// @notice can lock and unlock the global reentrancy lock
    /// should only be owned by a protocol contract
    bytes32 internal constant LOCKER = keccak256("LOCKER_ROLE");

    /// @notice game consumer notary role.
    /// can issue signatures for in-game crafting and speed ups
    bytes32 internal constant GAME_CONSUMER_NOTARY = keccak256("GAME_CONSUMER_NOTARY_ROLE");

    /// @notice DEPLOYER role.
    bytes32 internal constant DEPLOYER = keccak256("DEPLOYER_ROLE");
}
