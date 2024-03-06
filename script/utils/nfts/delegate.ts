/**
 * Delegate an NFT
 */
import fs from "fs";
import { program } from "commander";
import { ethers } from "ethers";
import {hashMessage} from "@ethersproject/hash";

program
    .name("dele.ts")
    .description("Delegate and NFT to another address.")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/DelegateRegistry.sol/DelegateRegistry.abi.json"
    )
    .requiredOption(
        "-c, --contract-address <address>",
        "DelegateRegistry contract"
    )
    .requiredOption("-n, --nft-contract-address <address>", "NFT contract")
    .requiredOption("-d, --delegatee <address>", "Delegatee address")
    .requiredOption("-t, --token-id <tokenId>", "NFT token ID")
    .requiredOption("-a, --amount <amount>", "Number of NFTs to delegate")
    .requiredOption("-p, --nft-type <type>", "NFT type (ERC1155|ERC721)", "ERC1155")
    .requiredOption(
        "-u, --rpc-url <url>",
        "RPC URL",
        process.env.TESTNET_RPC_URL || ""
    );

program.parse();

const abi = JSON.parse(fs.readFileSync(program.opts().abiPath, "utf-8"));
const provider = new ethers.providers.JsonRpcProvider(program.opts().rpcUrl);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY || "", provider);
const contract = new ethers.Contract(
    program.opts().contractAddress,
    abi,
    wallet
);

if (program.opts().nftType === "ERC1155") {
    await contract.delegateERC1155(
        program.opts().delegatee,
        program.opts().nftContractAddress,
        program.opts().tokenId,
        ethers.utils.formatBytes32String(""),
        program.opts().amount
    ).then((tx: any) => {
        console.log("SUCCESS");
        console.log(tx);
    }).catch((err: any) => {
        console.log("FAILED");
        console.log(err);
    });
} else {
    await contract.delegateERC721(
        program.opts().delegatee,
        program.opts().nftContractAddress,
        program.opts().tokenId,
        ethers.utils.formatBytes32String(""),
        false
    ).then((tx: any) => {
        console.log("SUCCESS");
        console.log(tx);
    }).catch((err: any) => {
        console.log("FAILED");
        console.log(err);
    });
}
