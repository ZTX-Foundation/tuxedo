/**
 * NFT transfers.
 */
import { program } from "commander";
import Moralis from "moralis";
import { EvmChain } from "@moralisweb3/common-evm-utils";
import fs from "fs";

program
    .name("getNFTContractTransfers.ts")
    .description("Get transfers of an NFT.")
    .requiredOption("-c, --contract-address <address>", "Contract address")
    .requiredOption("-o, --output <path>", "Output file path");

program.parse();

try {
    await Moralis.start({
        apiKey: process.env.MORALIS_API_KEY || "",
    });

    let cursor;
    let owners = [];

    do {
        const response = await Moralis.EvmApi.nft.getNFTContractTransfers({
            address: program.opts().contractAddress,
            chain: EvmChain.ARBITRUM,
            limit: 100,
            cursor: cursor,
            disableTotal: false,
        });
        if (response.pagination.total == undefined) {
            console.log("No transfers");
            break;
        } else {
            console.log(
                `Got page ${response.pagination.page} of ${Math.ceil(
                    response.pagination.total / response.pagination.pageSize
                )}, ${response.pagination.total} total`
            );
        }
        for (const nft of response.raw.result) {
            if (owners.indexOf(nft.to_address) == -1) {
                owners.push(nft.to_address);
            }
        }
        cursor = response.pagination.cursor;
    } while (cursor != "" && cursor != null);

    // Stream to a file
    let stream = fs.createWriteStream(program.opts().output);
    owners.forEach((owner) => {
        stream.write(owner + "\n", (err) => {
            if (err) {
                console.error(err);
            }
        });
    });
    stream.end();
} catch (e) {
    console.error(e);
}
