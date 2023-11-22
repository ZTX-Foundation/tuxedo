// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {IGlobalReentrancyLock} from "@protocol/core/IGlobalReentrancyLock.sol";
import {Roles} from "@protocol/core/Roles.sol";

/// @notice core contract that manages roles and pointer to global reentrancy lock
/// all contracts that need to use roles inherit CoreRef which contains a pointer to this contract
/// roles are managed by the admin role.
contract Core is AccessControlEnumerable {
    /// @notice event emitted when a role is revoked by the guardian
    event EmergencyRevoke(bytes32 role, address account);

    /// @notice event emitted when a role is created
    event RoleCreated(bytes32 role, bytes32 adminRole);

    /// @notice event emitted when global reentrancy lock pointer is updated
    event GlobalReentrancyLockUpdate(address indexed oldLock, address indexed newLock);

    /// @notice reference to the global reentrancy lock
    IGlobalReentrancyLock public lock;

    constructor() {
        _grantRole(Roles.ADMIN, msg.sender);
        _setRoleAdmin(Roles.ADMIN, Roles.ADMIN);
        _setRoleAdmin(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, Roles.ADMIN);
        _setRoleAdmin(Roles.GUARDIAN, Roles.ADMIN);
        _setRoleAdmin(Roles.MINTER_PROTOCOL_ROLE, Roles.ADMIN);
        _setRoleAdmin(Roles.FINANCIAL_CONTROLLER_PROTOCOL_ROLE, Roles.ADMIN);
        _setRoleAdmin(Roles.FINANCIAL_GUARDIAN, Roles.ADMIN);
        _setRoleAdmin(Roles.LOCKER_PROTOCOL_ROLE, Roles.ADMIN);
        _setRoleAdmin(Roles.MINTER_NOTARY_PROTOCOL_ROLE, Roles.ADMIN);
        _setRoleAdmin(Roles.GAME_CONSUMER_NOTARY_PROTOCOL_ROLE, Roles.ADMIN);
        _setRoleAdmin(Roles.REGISTRY_OPERATOR_PROTOCOL_ROLE, Roles.ADMIN);
    }

    /// @notice create a new role. This is the only way
    /// to allow admin to create a new admin.
    /// @param role the role to create
    /// @param adminRole the admin role of the new role
    function createRole(bytes32 role, bytes32 adminRole) external onlyRole(Roles.ADMIN) {
        _setRoleAdmin(role, adminRole);
    }

    /// @notice set the global reentrancy lock
    /// @param _lock the address of the new lock
    /// @dev only callable by admin or token governor
    function setGlobalLock(address _lock) external {
        require(
            hasRole(Roles.ADMIN, msg.sender) || hasRole(Roles.GOVERNOR_DAO_PROTOCOL_ROLE, msg.sender),
            "Core: must be admin or token governor"
        );

        address oldLock = address(lock);
        lock = IGlobalReentrancyLock(_lock);

        emit GlobalReentrancyLockUpdate(oldLock, _lock);
    }

    /// @notice revoke roles as a guardian
    /// @param role to revoke
    /// @param account to revoke the role from
    function emergencyRevoke(bytes32 role, address account) external onlyRole(Roles.GUARDIAN) {
        require(role != Roles.ADMIN, "Core: guardian cannot revoke admin");
        _revokeRole(role, account);

        emit EmergencyRevoke(role, account);
    }
}
