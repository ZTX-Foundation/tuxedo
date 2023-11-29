/**
 * Initialize a season distribution for season one
 */
import fs from "fs";
import { program } from "commander";
import { ethers } from "ethers";

program
    .name("initializeSeasonDistribution.ts")
    .description("Initialize a season distribution for season one")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/ERC1155SeasonOne.sol/ERC1155SeasonOne.abi.json"
    )
    .requiredOption(
        "-c, --contract-address <address>",
        "Contract address"
    )
    .requiredOption("-t, --token-ids <id,id..>", "Token IDs (comma separated)")
    .requiredOption("-r, --reward-amounts <amount,amount..>", "Reward amounts (comma separated)")
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

const tokenIds = program.opts().tokenIds.split(",");
const rewardAmounts = program.opts().rewardAmounts.split(",");
const distribution: { tokenId: string; rewardAmount: string }[] = [];
for (let i = 0; i < tokenIds.length; i++) {
    distribution.push({
        tokenId: tokenIds[i],
        rewardAmount: rewardAmounts[i]
    });
}

/// Initialize
await contract
    .initalizeSeasonDistribution(
        distribution,
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
