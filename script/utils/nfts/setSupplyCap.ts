/**
 * Set the supply cap of an NFT.
 */
import fs from "fs";
import { program } from "commander";
import { ethers } from "ethers";

program
    .name("setSupplyCap.ts")
    .description("Set the supply cap of an NFT.")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/ERC1155MaxSupplyMintable.sol/ERC1155MaxSupplyMintable.abi.json"
    )
    .requiredOption("-c, --contract-address <address>", "NFT contract")
    .requiredOption("-t, --token-id <id>", "Token ID")
    .requiredOption("-s, --supply-cap <max>", "Supply cap")
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

/// call set supply cap contract function.
const mintableContract = new ethers.Contract(
    program.opts().contractAddress,
    abi,
    wallet
);
await mintableContract
    .setSupplyCap(program.opts().tokenId, Number(program.opts().supplyCap))
    .then((tx: any) => {
        console.log("SUCCESS");
        console.log(tx);
    })
    .catch((err: any) => {
        console.log("FAILED");
        console.log(err);
    });
