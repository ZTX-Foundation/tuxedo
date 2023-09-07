import fs from 'fs';
import path from 'path';
import { create } from 'ipfs-http-client';

// Initialize IPFS client
const ipfs = create({ host: process.env.IPFS_HOST, port: 5001 });

async function addDirectoryToIPFS(folderPath: string, outputCsvPath: string) {
    const files = await fs.promises.readdir(folderPath);
    const fileUploads = [];

    for (const file of files) {
        console.log(`Uploading file: ${file}`);
        const fullPath = path.join(folderPath, file);
        console.log(`Full path: ${fullPath}`);
        const fileStat = await fs.promises.stat(fullPath);

        if (fileStat.isFile()) {
            const fileContent = await fs.promises.readFile(fullPath);
            fileUploads.push({ path: fullPath, content: fileContent });
        }
    }

    for await (const result of ipfs.addAll(fileUploads, {
        wrapWithDirectory: true,
        timeout: 100000,
        pin: true,
    })) {
        console.log(result);

        const csvEntry = `${result.path},${result.cid}\n`;
        await fs.promises.appendFile(outputCsvPath, csvEntry);
    }

    return;
}

(async function main() {
    const args = process.argv.slice(2);
    if (args.length !== 2) {
        console.error(
            'Usage: ts-node updateFolderToIPFS.ts <folder-path> <csv-path>'
        );
        process.exit(1);
    }

    const folderPath = args[0];
    const outputCsvPath = args[1];

    await addDirectoryToIPFS(folderPath, outputCsvPath);
})();
