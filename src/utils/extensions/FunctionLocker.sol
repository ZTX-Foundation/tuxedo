pragma solidity 0.8.18;

/// @title abstract contract for locking functions after being called once
abstract contract FunctionLocker {
    mapping(string => bool) private _lockedFunctions;

    /// @notice event emitted when a function is locked
    event FunctionLocked(string functionSignature);

    modifier lockFunction(string memory functionSignature) {
        require(!_lockedFunctions[functionSignature], "FunctionLocker: function locked");
        _lockedFunctions[functionSignature] = true;
        emit FunctionLocked(functionSignature);
        _;
    }
}
