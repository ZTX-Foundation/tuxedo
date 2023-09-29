/**
 * Generate a hash and mint an NFT for free.
 */
import fs from "fs";
import { program } from "commander";
import { ethers } from "ethers";
import { hashMessage } from "@ethersproject/hash";

program
    .name("mintForFree.ts")
    .description("Generate a hash and mint an NFT for free.")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/ERC1155AutoGraphMinter.sol/ERC1155AutoGraphMinter.abi.json"
    )
    .requiredOption(
        "-c, --contract-address <address>",
        "Autograph minter contract"
    )
    .requiredOption("-n, --nft-contract-address <address>", "NFT contract")
    .requiredOption("-r, --recipient <address>", "Recipient address to mint to")
    .requiredOption("-j, --job-id <id>", "Job ID")
    .requiredOption("-t, --token-id <id>", "Token ID")
    .requiredOption("-a, --units <amount>", "Number of NFTs to mint")
    .requiredOption("-s, --salt <salt>", "Salt")
    .requiredOption("-e, --expiry-token <expiry>", "Expiry token")
    .requiredOption("-x, --hash <hash>", "Hash")
    .requiredOption("-g, --signature <signature>", "Signature")
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

const autoGraphMinterContract = new ethers.Contract(
    program.opts().contractAddress,
    abi,
    wallet
);

/// call mintForFree contract function.
await autoGraphMinterContract
    .mintForFree(
        program.opts().recipient,
        program.opts().jobId,
        program.opts().tokenId,
        program.opts().units,
        program.opts().hash,
        program.opts().salt,
        program.opts().signature,
        program.opts().nftContractAddress,
        program.opts().expiryToken,
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
