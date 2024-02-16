pragma solidity 0.8.18;

abstract contract Config { 
    bool public DEBUG = true;
    uint256 public privateKey;
    bool public doDeploy;
    bool public doAfterdeploy;
    bool public doValidate;
    bool public doTeardown;
}