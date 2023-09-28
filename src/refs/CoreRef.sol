// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {IGlobalReentrancyLock} from "@protocol/core/IGlobalReentrancyLock.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";

/// Standard Core Reference contract. Inherited by system contracts
/// to keep a pointer to Core, and check access controls according to
/// the protocol's ACL in Core.
abstract contract CoreRef is Pausable {
    /// @notice emitted when core is set to a new address
    event CoreUpdate(address indexed oldCore, address indexed newCore);

    /// @notice reference to Core
    Core public core;

    /// set Core reference
    constructor(address coreAddress) {
        require(coreAddress != address(0), "CoreRef: core cannot be address(0)");
        core = Core(coreAddress);
    }

    /// 1. call core and lock the lock
    /// 2. execute the code
    /// 3. call core and unlock the lock back to starting level
    modifier globalLock(uint8 level) {
        IGlobalReentrancyLock lock = core.lock();
        lock.lock(level);
        _;
        lock.unlock(level - 1);
    }

    /// @notice modifier to restrict function access based on user role in Core
    modifier onlyRole(bytes32 role) {
        require(core.hasRole(role, msg.sender), "CoreRef: no role on core");
        _;
    }

    /// @notice modifier to restrict function access based on user role in Core
    modifier hasRole(bytes32 role) {
        require(core.hasRole(role, msg.sender), "CoreRef: no role on core");
        _;
    }

    // Modifiers to allow any combination of roles
    modifier hasAnyOfTwoRoles(bytes32 role1, bytes32 role2) {
        require(core.hasRole(role1, msg.sender) || core.hasRole(role2, msg.sender), "CoreRef: no role on core");
        _;
    }

    modifier hasAnyOfThreeRoles(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3
    ) {
        require(
            core.hasRole(role1, msg.sender) || core.hasRole(role2, msg.sender) || core.hasRole(role3, msg.sender),
            "CoreRef: no role on core"
        );
        _;
    }

    modifier hasAnyOfFourRoles(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3,
        bytes32 role4
    ) {
        require(
            core.hasRole(role1, msg.sender) ||
                core.hasRole(role2, msg.sender) ||
                core.hasRole(role3, msg.sender) ||
                core.hasRole(role4, msg.sender),
            "CoreRef: no role on core"
        );
        _;
    }

    /// ------------------------------------------------------
    /// --- Token Governor, Admin or Guardian Only API -------
    /// ------------------------------------------------------

    /// @notice set pausable methods to paused
    /// callable by admin, guardian, or token governance
    function pause() external hasAnyOfThreeRoles(Roles.ADMIN, Roles.TOKEN_GOVERNOR, Roles.GUARDIAN) {
        _pause();
    }

    /// @notice set pausable methods to unpaused
    /// callable by admin or token governance
    function unpause() external hasAnyOfThreeRoles(Roles.ADMIN, Roles.TOKEN_GOVERNOR, Roles.GUARDIAN) {
        _unpause();
    }

    /// @notice point to a new Core address.
    /// Use with caution, this can permanently DoS a contract if set to invalid core
    /// @param newCore new core address
    function setCore(address newCore) external onlyRole(Roles.ADMIN) {
        address previousCore = address(core);
        core = Core(newCore);

        emit CoreUpdate(previousCore, newCore);
    }

    /// ------------------------------------------
    /// ------------ Emergency Action ------------
    /// ------------------------------------------

    /// inspired by MakerDAO Multicall:
    /// https://github.com/makerdao/multicall/blob/master/src/Multicall.sol

    /// @notice struct to pack calldata and targets for an emergency action
    struct Call {
        /// @notice target address to call
        address target;
        /// @notice amount of eth to send with the call
        uint256 value;
        /// @notice payload to send to target
        bytes callData;
    }

    /// @notice due to inflexibility of current smart contracts,
    /// add this ability to be able to execute arbitrary calldata
    /// against arbitrary addresses.
    /// callable only by admin
    function emergencyAction(
        Call[] calldata calls
    ) external payable onlyRole(Roles.ADMIN) returns (bytes[] memory returnData) {
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            address payable target = payable(calls[i].target);
            require(target != address(0), "CoreRef: taget cannot be address(0)");
            uint256 value = calls[i].value;
            bytes calldata callData = calls[i].callData;

            //slither-disable-next-line arbitrary-send-eth
            (bool success, bytes memory returned) = target.call{value: value}(callData);
            require(success, "CoreRef: call failed");
            returnData[i] = returned;
        }
    }
}
