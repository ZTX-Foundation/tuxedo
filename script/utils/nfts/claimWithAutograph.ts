/**
 * Generate a hash and signature with Autograph, and then use those to claim a Zepeto NFT.
 */
import fs from "fs";
import axios from "axios";
import { program } from "commander";
import { ethers } from "ethers";
import * as jose from 'jose'

program
    .name("claimWithAutograph.ts")
    .description("Generate a hash with Autograph and claim a Zepeto NFT")
    .requiredOption(
        "-i, --abi-path <path>",
        "Path to the ABI file",
        "./out/ERC721ZepetoUA.sol/ERC721ZepetoUA.abi.json"
    )
    .requiredOption("-c, --contract-address <address>", "Contract address")
    .requiredOption("-r, --recipient <address>", "Recipient address to mint to")
    .requiredOption("-t, --token-id <id>", "Token ID")
    .requiredOption("-s, --salt <salt>", "Salt")
    .requiredOption(
        "-a, --autograph-service-url <url>",
        "Autograph service URL",
        "https://az7456uo6yqxdxax6i3bxg2liq0gftny.lambda-url.us-east-1.on.aws/zepeto"
    )
    .requiredOption(
        "-n, --autograph-signer <address>",
        "Autograph signer address",
        "0x254079270651fbf1408aa7a96746735974a087bf"
    )
    .requiredOption("-m, --metadata-url <url>", "Metadata URL")
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
const expiryToken = Math.floor(Date.now() / 1000) - 1000; // from whatever the expiryToken is you have 1 hour to process this request.

const params = {
    recipient: program.opts().recipient,
    tokenId: program.opts().tokenId,
    salt: program.opts().salt,
    expiryToken: expiryToken,
};

// Generate a JWT
const token = async () => {
    const secret = new TextEncoder().encode(process.env.JWT_SECRET)
    const alg = 'HS256'
    return await new jose.SignJWT({ 'ztx:zua:claim': true })
        .setProtectedHeader({ alg })
        .setIssuedAt()
        .setIssuer('ztx:zua:client')
        .setAudience('ztx:zua:claimants')
        .setExpirationTime('2h')
        .sign(secret)
}

axios.defaults.headers.common["x-ztx-authorization"] = `Bearer ${await token()}`;
const response = await axios.get(
    `${program.opts().autographServiceUrl}?recipient=${
        program.opts().recipient
    }&token_id=${program.opts().tokenId}&salt=${
        program.opts().salt
    }&expiry_token=${expiryToken}`
);

const hash = response.data.hash;
const onChainHash = await contract.getHash(params);

const signature = response.data.signature;
const recovered = await contract.recoverSigner(
    ethers.utils.arrayify(hash),
    signature
);

console.log(`Do the hashes match? ${hash == onChainHash}`);
console.log(
    `Is the recovered address equal to autograph signer address? ${
        recovered.toLowerCase() == program.opts().autographSigner
    }\n`
);

/// Claim NFT.
await contract
    .claim(
        program.opts().recipient,
        program.opts().tokenId,
        hash,
        program.opts().salt,
        signature,
        expiryToken,
        program.opts().metadataUrl,
        { gasLimit: 100000000, gasPrice: 100000000 }
    )
    .then((tx: any) => {
        console.log(tx);
    })
    .catch((err: any) => {
        console.log(err);
    });
