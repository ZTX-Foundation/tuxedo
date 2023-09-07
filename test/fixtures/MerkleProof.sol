// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.18;

// Value: [ '0x0000000000000000000000000000000000000001', 100 ]
contract MerkleProof {

    bytes32 public constant root = 0x5fe607afad1e60e1e661a8f06acada612eb43d5a8ae77cc7622628cef27b7063;

    /// purchase 100
    /// for address 1
    bytes32[4] public userOneProof = [
        bytes32(0x40175b6f179bf2ae772281ea077b6fe4496ff428cc96c0b03f82f73f32f921e7),
        bytes32(0xf4159d2565e3c8f4e672f85815a1b54aa89f1f3e7b10e77de2e8351107018d1a),
        bytes32(0x111546ddbe80ae95782aeb6feeda77c1544bf5734cc66b058191fe584081a384),
        bytes32(0xbc6bf496eef770615a8ce22f605821233fd5ca60624eb7eada5a95086263108c)
    ];
    
    /// purchase 300
    /// for beneficiary 1
    bytes32[4] public beneficiaryOneProof = [
        bytes32(0x86018fea227187f64e70e63b1bd5ceca4f313147ec409856a552c6337e7caacf),
        bytes32(0x89b9df585efceba4413883f89c7d350ee16a45ac7ef56bccb03c6020f2ef16ac),
        bytes32(0x111546ddbe80ae95782aeb6feeda77c1544bf5734cc66b058191fe584081a384),
        bytes32(0xbc6bf496eef770615a8ce22f605821233fd5ca60624eb7eada5a95086263108c)
    ];
    
    /// purchase 400
    /// for beneficiary 2
    bytes32[3] public beneficiaryTwoProof = [
        bytes32(0xc64ffb5eaff921f8055328da73d72e81697e72e4806901f1136950d8c375c4f6),
        bytes32(0xf17bf56467cfd4d229229d43d11ec55b4b55c8c14879b0717de49221d037e261),
        bytes32(0x4833fa49ea295c265eabb778fc7952448d846960c39a23977c397f136fd09494)
    ];
}
