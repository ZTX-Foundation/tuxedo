import fs from 'fs/promises';
import path from 'path';
import { create } from 'ipfs-http-client';

// Set up IPFS client
const ipfs = create({
    host: process.env.IPFS_HOST,
    port: 5001,
    protocol: 'http',
});

async function uploadFileToIPFS(filePath: string) {
    try {
        // Read the file
        const data = await fs.readFile(filePath);

        // Upload the file to IPFS
        const result = await ipfs.add(data);

        // Get the IPFS hash (CID)
        const ipfsHash = result.path;

        console.log(`File uploaded to IPFS with hash: ${ipfsHash}`);
        return ipfsHash;
    } catch (error) {
        console.error(`Failed to upload file to IPFS: ${error}`);
        throw error;
    }
}

async function uploadFilesInFolderToIPFS(
    folderPath: string,
    csvFilePath: string
) {
    try {
        // Read the contents of the folder
        const files = await fs.readdir(folderPath);

        // Write the header to the CSV file
        await fs.writeFile(csvFilePath, 'File Name,IPFS CID\n');

        // Upload each file in the folder to IPFS and save the CID to the CSV file
        for (const file of files) {
            const filePath = path.join(folderPath, file);
            const ipfsHash = await uploadFileToIPFS(filePath);
            const csvEntry = `${file},${ipfsHash}\n`;
            await fs.appendFile(csvFilePath, csvEntry);
        }
    } catch (error) {
        console.error(`Failed to upload folder to IPFS: ${error}`);
        throw error;
    }
}

// Get the folderPath from command-line arguments
const folderPath = process.argv[2];

if (!folderPath) {
    console.error('Usage: node <script_name> <folder_path> [csv_file_path]');
    process.exit(1);
}

// Get the csvFilePath from command-line arguments or use a default value
const csvFilePath = process.argv[3] || 'ipfs_hashes.csv';

// Example usage:
(async () => {
    await uploadFilesInFolderToIPFS(folderPath, csvFilePath);
})();
