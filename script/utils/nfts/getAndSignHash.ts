/**
 * Generate a hash.
 */
import fs from "fs";
import { program } from "commander";
import { ethers } from "ethers";
import {hashMessage} from "@ethersproject/hash";

program
    .name("getHash.ts")
    .description("Generate a hash.")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/ERC1155AutoGraphMinter.sol/ERC1155AutoGraphMinter.abi.json"
    )
    .requiredOption(
        "-c, --contract-address <address>",
        "ERC1155AutoGraphMinter contract"
    )
    .requiredOption("-n, --nft-contract-address <address>", "NFT contract")
    .requiredOption("-r, --recipient <address>", "Recipient address to mint to")
    .requiredOption("-j, --job-id <job id>", "Job ID")
    .requiredOption("-t, --token-id <id>", "Token ID")
    .requiredOption("-a, --units <amount>", "Number of NFTs to mint")
    .requiredOption("-s, --salt <salt>", "Salt")
    .requiredOption("-p, --payment-token <address>", "Payment token contract")
    .requiredOption("-q, --payment-amount <amount>", "Payment amount")
    .requiredOption("-e, --expiry-token <timestamp>", "Expiry timestamp")
    .requiredOption("-m, --mode <mode>", "Mode [onchain|offchain])", "onchain")
    .requiredOption(
        "-u, --rpc-url <url>",
        "RPC URL",
        process.env.TESTNET_RPC_URL || ""
    );

program.parse();

function getHash(params: any) {
    // Convert the input to the required encoded format
    const encodedInput = ethers.utils.defaultAbiCoder.encode(
        [
            "address",
            "uint256",
            "uint256",
            "uint256",
            "uint256",
            "address",
            "address",
            "uint256",
            "uint256",
        ],
        [
            params.recipient,
            params.jobId,
            params.tokenId,
            params.units,
            params.salt,
            params.nftContract,
            params.paymentToken,
            params.paymentAmount,
            params.expiryToken,
        ]
    );

    // Calculate the keccak256 hash of the encoded input
    const hash = ethers.utils.keccak256(encodedInput);
    return ethers.utils.arrayify(hash);
}

const params = {
    recipient: program.opts().recipient,
    jobId: program.opts().jobId,
    tokenId: program.opts().tokenId,
    units: program.opts().units,
    salt: program.opts().salt,
    nftContract: program.opts().nftContractAddress,
    paymentToken: program.opts().paymentToken,
    paymentAmount: program.opts().paymentAmount,
    expiryToken: program.opts().expiryToken,
};

const abi = JSON.parse(fs.readFileSync(program.opts().abiPath, "utf-8"));
const provider = new ethers.providers.JsonRpcProvider(program.opts().rpcUrl);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY || "", provider);

if (program.opts().mode === "offchain") {
    console.log(`Hash: ${hashMessage(getHash(params))}`);
} else {
    const contract = new ethers.Contract(
        program.opts().contractAddress,
        abi,
        wallet
    );

    /// call getHash contract function.
    await contract.getHash(params).then((hash: any) => {
        console.log(`Hash: ${hash}`);
    })
    .catch((err: any) => {
        console.log("FAILED");
        console.log(err);
    });
}

console.log(`Signature: ${await wallet.signMessage(getHash(params))}`);
