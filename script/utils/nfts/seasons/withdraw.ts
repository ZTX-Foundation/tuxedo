/**
 * Withdraw funds from a season.
 */
import fs from "fs";
import { program } from "commander";
import { ethers } from "ethers";

program
    .name("withdraw.ts")
    .description("Withdraw funds from a season")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/ERC1155SeasonOne.sol/ERC1155SeasonOne.abi.json"
    )
    .requiredOption(
        "-c, --contract-address <address>",
        "Contract address"
    )
    .requiredOption("-r, --recipient <recipient>", "Recipient")
    .requiredOption("-a, --amount <amount>", "Amount")
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

/// Initialize
await contract
    .withdraw(
        program.opts().recipient,
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
