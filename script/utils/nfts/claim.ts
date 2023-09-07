/**
 * Generate a hash and claim a Zepeto NFT.
 */
import fs from "fs";
import { program } from "commander";
import { ethers } from "ethers";
import { hashMessage } from "@ethersproject/hash";

program
    .name("claim.ts")
    .description("Generate a hash and claim a Zepeto NFT")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/ERC721ZepetoUA.sol/ERC721ZepetoUA.abi.json"
    )
    .requiredOption(
        "-c, --contract-address <address>",
        "Contract address"
    )
    .requiredOption("-r, --recipient <address>", "Recipient address to mint to")
    .requiredOption("-t, --token-id <id>", "Token ID")
    .requiredOption("-s, --salt <salt>", "Salt")
    .requiredOption("-m, --metadata-url <url>", "Metadata URL")
    .requiredOption(
        "-u, --rpc-url <url>",
        "RPC URL",
        process.env.TESTNET_RPC_URL || ""
    );

program.parse();

const abi = JSON.parse(fs.readFileSync(program.opts().abiPath, "utf-8"));
const provider = new ethers.providers.JsonRpcProvider(program.opts().rpcUrl);

const wallet = new ethers.Wallet(process.env.PRIVATE_KEY || "", provider);
console.log(`Wallet address: ${wallet.address}`);

const contract = new ethers.Contract(
    program.opts().contractAddress,
    abi,
    wallet
);
const expiryToken = Math.floor(Date.now() / 1000) - 1000; // from whatever the expiryToken is you have 1 hour to process this request.

function getHash(input: any) {
    // Convert the input to the required encoded format
    const encodedInput = ethers.utils.defaultAbiCoder.encode(
        [
            "address",
            "address",
            "uint256",
            "uint256",
            "uint256"
        ],
        [
            wallet.address,
            input.recipient,
            input.tokenId,
            input.salt,
            input.expiryToken
        ]
    );

    // Calculate the keccak256 hash of the encoded input
    const hash = ethers.utils.keccak256(encodedInput);

    console.log(`Generated hash: ${hash}`);
    console.log(`Hash length: ${hash.length}`); // 66 correct length
    console.log(`'typeof' hash: ${typeof hash}`); // string

    // convert to bytes
    return ethers.utils.arrayify(hash);
}

const params = {
    recipient: program.opts().recipient,
    tokenId: program.opts().tokenId,
    salt: program.opts().salt,
    expiryToken: expiryToken,
};

/// Create offchain hash
const hash = getHash(params); // Without the messagePrefix = "\x19Ethereum Signed Message:\n" header
const onChainHash = await contract.getHash(params);

console.log(`Do the hashes match? ${hashMessage(hash) === onChainHash}`); // HashMessage adds the messagePrefix

/// Generate signature on hash (ethers.js added the messagePrefix = "\x19Ethereum Signed Message:\n" header) under the hood
/// The signer requires the MINTER_NOTARY role.
const flatSig = await wallet.signMessage(hash);

/// Recover signer from signature and hash
const recovered = await contract.recoverSigner(
    hashMessage(hash),
    flatSig
);

/// this should be true.
console.log(
    `Is the recovered address equal to wallet address? ${
        recovered === wallet.address
    }\n`
);

/// Claim NFT.
await contract
    .claim(
        program.opts().recipient,
        program.opts().tokenId,
        hashMessage(hash),
        program.opts().salt,
        flatSig,
        expiryToken,
        program.opts().metadataUrl,
        { gasLimit: 100000000, gasPrice: 100000000 }
    )
    .then((tx: any) => {
        console.log(tx);
    })
    .catch((err: any) => {
        console.log(err);
    });
