/**
 * Set URI on ERC1155MaxSupplyMintable.
 */
import fs from "fs";
import { program } from "commander";
import { ethers } from "ethers";
import { hashMessage } from "@ethersproject/hash";

program
    .name("claim.ts")
    .description("Generate a hash and claim a Zepeto NFT")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/ERC1155MaxSupplyMintable.sol/ERC1155MaxSupplyMintable.abi.json"
    )
    .requiredOption(
        "-c, --contract-address <address>",
        "Contract address"
    )
    .requiredOption("-r, --uri <uri>", "New URI for the contract")
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

/// Set URI.
await contract
    .setURI(
        program.opts().uri,
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
