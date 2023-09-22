pragma solidity 0.8.18;

abstract contract Sealable {
    bool public seal = false;

    modifier sealAfter() {
        require(!seal, "Sealable: Contract already Sealed");
        _;
        seal = true;
    }
}
