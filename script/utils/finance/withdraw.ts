/**
 * Withdraw funds.
 */
import fs from "fs";
import { program } from "commander";
import { ethers } from "ethers";

program
    .name("withdraw.ts")
    .description("Withdraw funds.")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/ERC20HoldingDeposit.sol/ERC20HoldingDeposit.abi.json"
    )
    .requiredOption("-c, --contract-address <address>", "Contract address")
    .requiredOption("-r, --recipient <address>", "Address to withdraw to")
    .requiredOption("-a, --amount <amount>", "Amount to withdraw")
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
    `Withdrawing: ${program.opts().amount} to address: ${
        program.opts().recipient
    }`
);

await contract
    .withdraw(
        program.opts().recipient,
        program.opts().amount
    )
    .then((tx: any) => {
        console.log("SUCCESS");
        console.log(tx);
    })
    .catch((err: any) => {
        console.log("FAILED");
        console.log(err);
    });
