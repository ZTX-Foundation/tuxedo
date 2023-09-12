/**
 * Set contract claimable status.
 */
import fs from "fs";
import { program } from "commander";
import { ethers } from "ethers";

program
    .name("setClaimable.ts")
    .description("Set the isClaimable flag on the contract.")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/ERC721ZepetoUA.sol/ERC721ZepetoUA.abi.json"
    )
    .requiredOption(
        "-c, --contract-address <address>",
        "Contract"
    )
    .requiredOption(
        "-s, --status <address>",
        "status",
        false
    )
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

/// toggle minting status function.
await contract
    .setClaimable(
        JSON.parse(program.opts().status.toLowerCase()),
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
