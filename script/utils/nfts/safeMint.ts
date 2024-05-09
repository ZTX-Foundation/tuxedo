/**
 * Mint a token.
 */
import fs from "fs";
import { program } from "commander";
import { ethers } from "ethers";

program
    .name("safeMint.ts")
    .description("Mint a token.")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/PlayTest.sol/PlayTest.abi.json"
    )
    .requiredOption(
        "-c, --contract-address <address>",
        "Admin minter contract"
    )
    .requiredOption("-r, --recipient <address>", "Recipient address to mint to")
    .requiredOption("-m, --metadata-uri <uri>", "Token metadata URI")
    .requiredOption(
        "-u, --rpc-url <url>",
        "RPC URL",
        process.env.RPC_URL || ""
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

await contract
    .safeMint(
        program.opts().recipient,
        program.opts().metadataUri
    )
    .then((tx: any) => {
        console.log("SUCCESS");
        console.log(tx);
    })
    .catch((err: any) => {
        console.log("FAILED");
        console.log(err);
    });
