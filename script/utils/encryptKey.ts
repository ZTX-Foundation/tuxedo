import { ethers } from 'ethers';
import * as dotenv from 'dotenv';
import fs from 'fs';

// One time script for encrypting private key
dotenv.config({ path: '.env.sepolia' });

// 1. Add private key and private key password locally to .env file
// 2. Run this script to encrypt your private key with password and output encryptedKey
// 3. Delete the private key and private key password from your .env file
// 4. Update all wallet constructors to use this encryptedKey with
// let wallet = ethers.Wallet.fromEncryptedJsonSync(encryptedJson, process.env.PRIVATE_KEY_PASSWORD);
// 5. Stay safe!

async function main() {
    const PRIVATE_KEY = process.env.PRIVATE_KEY || '';
    const PRIVATE_KEY_PASSWORD = process.env.PRIVATE_KEY_PASSWORD || '';
    const wallet = new ethers.Wallet(PRIVATE_KEY);
    const encryptedJsonKey = await wallet.encryptSync(PRIVATE_KEY_PASSWORD);
    console.log(encryptedJsonKey);
    fs.writeFileSync('./.encryptedKey.json', encryptedJsonKey);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
