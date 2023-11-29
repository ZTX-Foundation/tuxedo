/**
 * Register a token ID for a given season.
 */
import fs from "fs";
import { program } from "commander";
import { ethers } from "ethers";

program
    .name("register.ts")
    .description("Generate a hash and claim a Zepeto NFT")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/SeasonsTokenIdRegistry.sol/SeasonsTokenIdRegistry.abi.json"
    )
    .requiredOption(
        "-c, --contract-address <address>",
        "Contract address"
    )
    .requiredOption("-t, --token-id <id>", "Token ID")
    .requiredOption("-s, --season-contract-address <address>", "Season contract address")
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

/// Register
await contract
    .register(
        program.opts().tokenId,
        program.opts().seasonContractAddress,
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
