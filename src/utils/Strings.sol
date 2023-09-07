pragma solidity 0.8.18;

library StringUtils {
    function toLowerCase(string memory _input) internal pure returns (string memory) {
        bytes memory inputBytes = bytes(_input);
        bytes memory outputBytes = new bytes(inputBytes.length);

        for (uint256 i = 0; i < inputBytes.length; i++) {
            if ((uint8(inputBytes[i]) >= 65) && (uint8(inputBytes[i]) <= 90)) {
                outputBytes[i] = bytes1(uint8(inputBytes[i]) + 32);
            } else {
                outputBytes[i] = inputBytes[i];
            }
        }

        return string(outputBytes);
    }

    function equals(string memory _input, string memory _input2) public pure returns (bool) {
        return keccak256(abi.encodePacked(_input)) == keccak256(abi.encodePacked(_input2));
    }
}
