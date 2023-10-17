/**
 * Sign a hash.
 */
import { program } from "commander";
import { ethers } from "ethers";

program
    .name("signHash.ts")
    .description("Sign a hash.")
    .requiredOption("-x, --hash <hash>", "Hash to sign")
    .requiredOption(
        "-u, --rpc-url <url>",
        "RPC URL",
        process.env.TESTNET_RPC_URL || ""
    );

program.parse();

const provider = new ethers.providers.JsonRpcProvider(program.opts().rpcUrl);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY || "", provider);

console.log(`Signature: ${await wallet.signMessage(program.opts().hash)}`);
