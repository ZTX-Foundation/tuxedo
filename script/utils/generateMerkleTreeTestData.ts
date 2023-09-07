import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

/*
    This is a test file to generate a merkle tree and get the proof of a value.
    This is only used for testing purposes to generate a tree and get the proof of a value.
    Those values, tree, root and proofs are used exclusively in ERC1155SaleTests.
    You can view these proofs in the MerkleProof.sol file.
*/

// (1)
const values: Array<[string, number]> = [];

const address = '0x000000000000000000000000000000000000000';

// Specify the types of your values
const types: [string, string] = ['address', 'uint256'];

/// first create an array of arrays
/// each subarray has 2 elements: address and amount
/// addresses go from 1-9 and have amounts 100-900
for (let i = 1; i <= 9; i++) {
    /// tokenId
    values.push([address.concat(i.toString()), 100 * i]);
}

// (2)
/// user address, user amount
/// create the merkle tree using the oz library
const tree: StandardMerkleTree<[string, number]> = StandardMerkleTree.of(values, types);

// (3)
/// log out the merkle root
console.log('Merkle Root:', tree.root);

// (4) no need to write the tree to a file, otherwise we'd have to update the gitignore
// fs.writeFileSync("tree.json", JSON.stringify(tree.dump()));

/// (5) get the proof for the 4th address
for (const [i, v] of tree.entries()) {
    if (v[0] === '0x0000000000000000000000000000000000000004') {
        // (5)
        const proof: string[] = tree.getProof(i);
        console.log('Value:', v);
        console.log('Proof:', proof);
    }
}
