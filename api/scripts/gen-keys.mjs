// Prints fresh secrets for .dev.vars (or `wrangler secret put`). Usage: npm run keys -- [kid]
// Rotation: set the new key as JWT_PRIVATE_KEY/JWT_KEY_ID and APPEND its public key to
// JWT_PUBLIC_KEYS ("k1=...||k2=..."); drop the old public key after the longest token lifetime.
import { generateKeyPairSync, randomBytes } from "node:crypto";

const kid = process.argv[2] ?? "k1";
const { privateKey, publicKey } = generateKeyPairSync("ec", { namedCurve: "P-256" });
const oneLine = (pem) => pem.trim().replaceAll("\n", "\\n");
console.log(`JWT_KEY_ID="${kid}"   # set in wrangler.jsonc vars`);
console.log(`JWT_PRIVATE_KEY="${oneLine(privateKey.export({ type: "pkcs8", format: "pem" }).toString())}"`);
console.log(`JWT_PUBLIC_KEYS="${kid}=${oneLine(publicKey.export({ type: "spki", format: "pem" }).toString())}"`);
console.log(`TOTP_ENCRYPTION_KEY="${randomBytes(32).toString("base64")}"`);
