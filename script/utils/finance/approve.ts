/**
 * Approve the spending of funds.
 */
import fs from "fs";
import { program } from "commander";
import { ethers } from "ethers";

program
    .name("approve.ts")
    .description("Approve the spending of funds.")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/Token.sol/Token.abi.json"
    )
    .requiredOption("-c, --contract-address <address>", "Contract address")
    .requiredOption("-s, --spender <address>", "Spender address")
    .requiredOption("-a, --amount <amount>", "Amount to approve")
    .requiredOption(
        "-u, --rpc-url <url>",
        "RPC URL",
        process.env.TESTNET_RPC_URL || ""
    );

program.parse();

const abi = JSON.parse(fs.readFileSync(program.opts().abiPath, "utf-8"));
const provider = new ethers.providers.JsonRpcProvider(program.opts().rpcUrl);

const wallet = new ethers.Wallet(process.env.PRIVATE_KEY || "", provider);
console.log(wallet.address);

const contract = new ethers.Contract(
    program.opts().contractAddress,
    abi,
    wallet
);
console.log(
    `Approving: ${program.opts().amount} to be spent by: ${
        program.opts().spender
    }`
);

await contract
    .approve(
        program.opts().spender,
        program.opts().amount,
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
