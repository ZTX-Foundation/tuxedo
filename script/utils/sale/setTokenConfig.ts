/**
 * Set token config.
 */
import fs from "fs";
import { program } from "commander";
import { ethers } from "ethers";
import {hashMessage} from "@ethersproject/hash";

program
    .name("setTokenConfig.ts")
    .description("Set token config.")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/ERC1155Sale.sol/ERC1155Sale.abi.json"
    )
    .requiredOption(
        "-c, --contract-address <address>",
        "ERC1155Sale contract"
    )
    .requiredOption("-t, --token-id <token id>", "Token Id")
    .requiredOption("-n, --payment-token <address>", "Payment token contract address")
    .requiredOption("-s, --start-time <timestamp>", "Sale start time timestamp")
    .requiredOption("-p, --price <amount>", "Price")
    .requiredOption("-f, --fee <amount>", "Fee")
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

await contract.setTokenConfig(
    program.opts().tokenId,
    program.opts().paymentToken,
    program.opts().startTime,
    program.opts().price,
    program.opts().fee,
    true,
    ethers.utils.formatBytes32String("")
).then((tx: any) => {
    console.log("SUCCESS");
    console.log(tx);
}).catch((err: any) => {
    console.log("FAILED");
    console.log(err);
});
