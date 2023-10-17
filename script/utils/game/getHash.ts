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
        "./out/GameConsumer.sol/GameConsumer.abi.json"
    )
    .requiredOption(
        "-c, --contract-address <address>",
        "GameConsumer contract"
    )
    .requiredOption("-j, --job-id <job id>", "Job ID")
    .requiredOption("-p, --payment-token <address>", "Payment token contract")
    .requiredOption("-f, --job-fee <amount>", "Job fee")
    .requiredOption("-t, --hash-timestamp <timestamp>", "Hash (expiry) timestamp")
    .requiredOption("-s, --salt <salt>", "Salt")
    .requiredOption("-m, --mode <mode>", "Mode [onchain|offchain])", "onchain")
    .requiredOption(
        "-u, --rpc-url <url>",
        "RPC URL",
        process.env.TESTNET_RPC_URL || ""
    );

program.parse();

function getHash() {
    // Convert the input to the required encoded format
    const encodedInput = ethers.utils.defaultAbiCoder.encode(
        [
            "uint256",
            "address",
            "uint256",
            "uint256",
            "uint256",
        ],
        [
            program.opts().jobId,
            program.opts().paymentToken,
            program.opts().jobFee,
            program.opts().hashTimestamp,
            program.opts().salt
        ]
    );

    // Calculate the keccak256 hash of the encoded input
    const hash = ethers.utils.keccak256(encodedInput);
    return ethers.utils.arrayify(hash);
}

if (program.opts().mode === "offchain") {
    console.log(`Hash: ${hashMessage(getHash())}`);
} else {
    const abi = JSON.parse(fs.readFileSync(program.opts().abiPath, "utf-8"));
    const provider = new ethers.providers.JsonRpcProvider(program.opts().rpcUrl);

    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY || "", provider);
    const contract = new ethers.Contract(
        program.opts().contractAddress,
        abi,
        wallet
    );

    /// call getHash contract function.
    await contract.getHash(
        program.opts().jobId,
        program.opts().paymentToken,
        program.opts().jobFee,
        program.opts().hashTimestamp,
        program.opts().salt
    ).then((hash: any) => {
        console.log(`Hash: ${hash}`);
    })
    .catch((err: any) => {
        console.log("FAILED");
        console.log(err);
    });
}

