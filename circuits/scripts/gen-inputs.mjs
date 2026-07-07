// Generate valid witnesses (input JSONs) for the three circuits, computing the
// Poseidon commitments the constraints require. Reproducible: fixed test values.
// Output: build/input_{auth,register,rotate}.json
import { buildPoseidon } from "circomlibjs";
import { writeFileSync, mkdirSync } from "node:fs";

const P = await buildPoseidon();
const F = P.F;
const h = (xs) => F.toObject(P(xs.map(BigInt))).toString();

// Fixed domain values (any values work; commitments must be Poseidon of the secrets).
const chainId = 137n;
const verifyingContract = BigInt("0x00000000000000000000000000000000000000C0");
const actionHash = 0x1234567890abcdefn;
const nonce = 1n;
const deadline = 9_999_999_999n;

const secret = 123456789n, salt = 987654321n;
const commitment = h([secret, salt]);

const newSecret = 111222333n, newSalt = 444555666n;
const newCommitment = h([newSecret, newSalt]);

mkdirSync("build", { recursive: true });

writeFileSync("build/input_auth.json", JSON.stringify({
  chainId: chainId.toString(), verifyingContract: verifyingContract.toString(),
  actionHash: actionHash.toString(), nonce: nonce.toString(), deadline: deadline.toString(),
  commitment, secret: secret.toString(), salt: salt.toString(),
}, null, 2));

writeFileSync("build/input_register.json", JSON.stringify({
  commitment, bindingHash: "0", // unconstrained in-circuit; real binding checked on-chain
  secret: secret.toString(), salt: salt.toString(),
}, null, 2));

writeFileSync("build/input_rotate.json", JSON.stringify({
  oldCommitment: commitment, newCommitment,
  chainId: chainId.toString(), verifyingContract: verifyingContract.toString(),
  nonce: nonce.toString(), deadline: deadline.toString(),
  oldSecret: secret.toString(), oldSalt: salt.toString(),
  newSecret: newSecret.toString(), newSalt: newSalt.toString(),
}, null, 2));

console.log("inputs written: build/input_{auth,register,rotate}.json");
