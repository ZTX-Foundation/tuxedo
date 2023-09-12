/**
 * Generate a hash and mint an NFT for free.
 */
import fs from "fs";
import { program } from "commander";
import { ethers } from "ethers";
import { hashMessage } from "@ethersproject/hash";

program
    .name("mintForFree.ts")
    .description("Generate a hash and mint an NFT for free.")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/ERC1155AutoGraphMinter.sol/ERC1155AutoGraphMinter.abi.json"
    )
    .requiredOption(
        "-c, --contract-address <address>",
        "Autograph minter contract"
    )
    .requiredOption("-n, --nft-contract-address <address>", "NFT contract")
    .requiredOption("-r, --recipient <address>", "Recipient address to mint to")
    .requiredOption("-t, --token-id <id>", "Token ID")
    .requiredOption("-a, --units <amount>", "Number of NFTs to mint")
    .requiredOption("-s, --salt <salt>", "Salt")
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

const autoGraphMinterContract = new ethers.Contract(
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
            "uint256",
            "uint256",
            "uint256",
            "address",
            "address",
            "uint256",
            "uint256",
        ],
        [
            input.recipient,
            input.tokenId,
            input.units,
            input.salt,
            input.nftContract,
            input.paymentToken,
            input.paymentAmount,
            input.expiryToken,
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
    units: program.opts().units,
    salt: program.opts().salt,
    nftContract: program.opts().nftContractAddress,
    paymentToken: "0x0000000000000000000000000000000000000000",
    paymentAmount: 0,
    expiryToken: expiryToken,
};

/// Create offchain hash
const hash = getHash(params); // Without the messagePrefix = "\x19Ethereum Signed Message:\n" header
const onChainHash = await autoGraphMinterContract.getHash(params);

console.log(`Do the hashes match? ${hashMessage(hash) === onChainHash}`); // HashMessage adds the messagePrefix

/// Generate signature on hash (ethers.js added the messagePrefix = "\x19Ethereum Signed Message:\n" header) under the hood
/// This signing process will be done by the AutoGraphMinter backend service.
/// The AutoGraphMinter service will have a key that has the MINTER_NOTARY_ROLE role which is tested for as part of all the mint functions.
const flatSig = await wallet.signMessage(hash);

/// Recover signer from signature and hash
const recovered = await autoGraphMinterContract.recoverSigner(
    hashMessage(hash),
    flatSig
);

/// this should be true.
console.log(
    `Is the recovered address equal to wallet address? ${
        recovered === wallet.address
    }\n`
);

/// call mintForFree contract function.
await autoGraphMinterContract
    .mintForFree(
        program.opts().recipient,
        program.opts().tokenId,
        program.opts().units,
        hashMessage(hash),
        program.opts().salt,
        flatSig,
        program.opts().nftContractAddress,
        expiryToken,
        { gasLimit: 100000000, gasPrice: 100000000 }
    )
    .then((tx: any) => {
        console.log("SUCCESS");
        console.log(tx);
    })
    .catch((err: any) => {
        console.log("FAILED");
        console.log(err);
    });
