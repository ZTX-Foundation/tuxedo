/**
 * Mint a token.
 */
import fs from "fs";
import { program } from "commander";
import { ethers } from "ethers";

program
    .name("mintToken.ts")
    .description("Mint a token.")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/ERC1155AdminMinter.sol/ERC1155AdminMinter.abi.json"
    )
    .requiredOption(
        "-c, --contract-address <address>",
        "Admin minter contract"
    )
    .requiredOption("-n, --nft-contract-address <address>", "NFT contract")
    .requiredOption("-r, --recipient <address>", "Recipient address to mint to")
    .requiredOption("-t, --token-id <id>", "Token ID")
    .requiredOption("-a, --units <amount>", "Number of NFTs to mint")
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

const adminMinter = new ethers.Contract(
    program.opts().contractAddress,
    abi,
    wallet
);

/// call mintToken contract function.
await adminMinter
    .mintToken(
        program.opts().nftContractAddress,
        program.opts().recipient,
        program.opts().tokenId,
        program.opts().units,
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
