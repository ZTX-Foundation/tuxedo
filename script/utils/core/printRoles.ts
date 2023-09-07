import { keccak256 } from "@ethersproject/keccak256";
import { toUtf8Bytes } from "@ethersproject/strings";

/**
 * Prints the bytes32 string of all the roles.
 */

const roles: string[] = [
    "ADMIN_ROLE",
    "TOKEN_GOVERNOR_ROLE",
    "GUARDIAN_ROLE",
    "MINTER_ROLE",
    "MINTER_NOTARY_ROLE",
    "FINANCIAL_CONTROLLER_ROLE",
    "FINANCIAL_GUARDIAN_ROLE",
    "LOCKER_ROLE",
    "GAME_CONSUMER_NOTARY_ROLE",
];
roles.forEach((role: string) => {
    console.log(`${role}: ${keccak256(toUtf8Bytes(role))}`);
});
