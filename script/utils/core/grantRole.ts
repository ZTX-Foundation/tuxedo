/**
 * Grant a role to an address.
 */
import fs from "fs";
import { program } from "commander";
import { ethers } from "ethers";
import { keccak256 } from "@ethersproject/keccak256";
import { toUtf8Bytes } from "@ethersproject/strings";

program
    .name("grantRole.ts")
    .description("Grant a role to an address.")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/Core.sol/Core.abi.json"
    )
    .requiredOption("-c, --contract-address <address>", "Contract address")
    .requiredOption("-r, --role <role>", "Role to grant")
    .requiredOption("-a, --address <address>", "Address to grant the role to")
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
    `Granting role: ${program.opts().role} to address: ${
        program.opts().address
    }`
);

await contract
    .grantRole(
        keccak256(toUtf8Bytes(program.opts().role)),
        program.opts().address
    )
    .then((tx: any) => {
        console.log("SUCCESS");
        console.log(tx);
    })
    .catch((err: any) => {
        console.log("FAILED");
        console.log(err);
    });
