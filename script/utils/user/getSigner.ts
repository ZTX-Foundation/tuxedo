/**
 * Get signer address.
 */
import { ethers } from 'ethers';
import { program } from "commander";
import fs from "fs";

program
    .name("getSigner.ts")
    .description("Get signer address")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/Auth.sol/Auth.abi.json"
    )
    .requiredOption(
        "-c, --contract-address <address>",
        "Auth contract"
    )
    .requiredOption("-s, --session-id <session id>", "Session ID")
    .requiredOption("-x, --signature <signature>", "Signature")
    .requiredOption(
        "-u, --rpc-url <url>",
        "RPC URL",
        process.env.TESTNET_RPC_URL || ""
    );

program.parse();

const abi = JSON.parse(fs.readFileSync(program.opts().abiPath, "utf-8"));
const provider = new ethers.providers.JsonRpcProvider(program.opts().rpcUrl);
const contract = new ethers.Contract(
    program.opts().contractAddress,
    abi,
    provider
);

await contract.getSigner(
    program.opts().sessionId,
    program.opts().signature,
    { gasLimit: 100000000, gasPrice: 100000000 }
).then((signer: any) => {
    console.log(signer);
}).catch((err: any) => {
    console.log(err);
});
