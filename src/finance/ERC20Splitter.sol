// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Roles} from "@protocol/core/Roles.sol";
import {CoreRef} from "@protocol/refs/CoreRef.sol";
import {Constants} from "@protocol/Constants.sol";

/// @title contract for splitting ERC20 tokens into different deposits
contract ERC20Splitter is CoreRef {
    using SafeERC20 for IERC20;

    /// @notice list of Deposits to split to
    struct Allocation {
        /// @notice address of the deposit
        address deposit;
        /// @notice ratio for splitting between allocations
        uint16 ratio;
    }

    /// @notice list of Deposits to split to
    Allocation[] public allocations;

    /// @notice token to split
    IERC20 public immutable token;

    /// @notice emitted when the allocation is updated
    event AllocationUpdate(
        address[] oldDeposits,
        uint256[] oldRatios,
        address[] newDeposits,
        uint256[] newRatios
    );
    
    /// @notice emitted when funds are allocated to deposits
    event Allocate(address indexed caller, uint256 amount);
    
    /// @notice ERC20Splitter constructor
    /// @param _core address of the core contract
    /// @param _token address of the token to split
    /// @param _deposits list of deposits and ratios to split to, optional, this can be provided later by admin
    constructor(
        address _core,
        address _token,
        Allocation[] memory _deposits
    ) CoreRef(_core) {
        require(_token != address(0), "ERC20Splitter: token cannot be address(0)");
        token = IERC20(_token);
        /// do not set up deposits if non provided
        if (_deposits.length > 0) {
            _setAllocation(_deposits);
        }
    }
    
    /// ------- View Only Functions -------

    /// @notice get the number of allocations
    function getNumberOfAllocations() external view returns (uint256) {
        return allocations.length;
    }

    /// @notice get the allocation at a given index
    /// @param index the index of the allocation
    /// @return the allocation at the index
    function getAllocationAt(uint256 index) external view returns (Allocation memory) {
        return allocations[index];
    }

    /// @notice get all the allocations
    /// @return the allocations
    function getAllocations() external view returns (Allocation[] memory) {
        return allocations;
    }
    
    /// @notice make sure an allocation has ratios that total ALLOCATION_GRANULARITY
    /// @param _deposits new list of deposits to send to
    function checkAllocation(Allocation[] memory _deposits) public pure {
        uint256 total;
        unchecked {
            for (uint256 i; i < _deposits.length; i++) {
                total = total + _deposits[i].ratio;
            }
        }
        
        require(total == Constants.BASIS_POINTS_GRANULARITY, "ERC20Splitter: ratios not 100%");
    }

    /// ------- Public Function -------
    
    /// @notice allocate all funds in the splitter to the deposits
    /// @dev callable when not paused
    function allocate() external whenNotPaused {
        uint256 total = token.balanceOf(address(this));
        uint256 granularity = Constants.BASIS_POINTS_GRANULARITY;

        for (uint256 i; i < allocations.length; i++) {
            uint256 amount = (total * allocations[i].ratio) / granularity;
            token.safeTransfer(allocations[i].deposit, amount);
        }

        emit Allocate(msg.sender, total);
    }
    
    /// @notice allocate all funds in the splitter to the deposits
    /// @dev callable when not paused
    /// @param tokenToAllocate token to be allocated by splitter based on defined ratios
    function allocate(address tokenToAllocate) external whenNotPaused {
        uint256 total = IERC20(tokenToAllocate).balanceOf(address(this));
        uint256 granularity = Constants.BASIS_POINTS_GRANULARITY;

        for (uint256 i; i < allocations.length; i++) {
            uint256 amount = (total * allocations[i].ratio) / granularity;
            IERC20(tokenToAllocate).safeTransfer(allocations[i].deposit, amount);
        }

        emit Allocate(msg.sender, total);
    }

    /// ------- Admin Only Functions -------

    /// @notice sets the allocation of each deposit
    /// callable only by the admin role
    /// @param _allocations list of deposits to send to
    function setAllocation(Allocation[] memory _allocations) external onlyRole(Roles.ADMIN) {
        _setAllocation(_allocations);
    }

    /// ------- Internal Helper Function -------

    /// @notice sets a new allocation for the splitter
    /// @param _allocations new list of allocations
    function _setAllocation(Allocation[] memory _allocations) internal {
        checkAllocation(_allocations);

        uint256[] memory _oldRatios = new uint256[](allocations.length);
        address[] memory _oldDeposits = new address[](allocations.length);
        unchecked {
            for (uint256 i; i < allocations.length; i++) {
                _oldRatios[i] = allocations[i].ratio;
                _oldDeposits[i] = allocations[i].deposit;
            }
        }

        /// drop all the allocations
        delete allocations;

        uint256[] memory _newRatios = new uint256[](_allocations.length);
        address[] memory _newDeposits = new address[](_allocations.length);

        /// improbable to ever overflow because deposit length would need to be greater than 2^256-1 
        unchecked {
            for (uint256 i; i < _allocations.length; i++) {
                allocations.push(_allocations[i]);
            }
        }

        emit AllocationUpdate(_oldDeposits, _oldRatios, _newDeposits, _newRatios);
    }
}
