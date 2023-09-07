/**
 * Generate a JWT token to use for calling Autograph.
 */
import { program } from "commander";
import * as jose from "jose";

program
    .name("generateJWTToken.ts")
    .description("Generate a JWT token to use for calling Autograph")
    .requiredOption("-s, --secret <secret>", "JWT Secret")
    .requiredOption("-a, --aud <audience>", "Audience", "ztx")
    .requiredOption("-i, --iss <issuer>", "Issuer", "ztx")
    .requiredOption("-e, --exp <expiration>", "Expiration", "2h")
    .requiredOption("-g, --algorithm <algorithm>", "Algorithm to use", "HS256");

program.parse();

const alg = program.opts().algorithm;
const token = await new jose.SignJWT({ "claim": true })
        .setProtectedHeader({ alg })
        .setIssuedAt()
        .setIssuer(program.opts().iss)
        .setAudience(program.opts().aud)
        .setExpirationTime(program.opts().exp)
        .sign(new TextEncoder().encode(program.opts().secret));

console.log(token);
