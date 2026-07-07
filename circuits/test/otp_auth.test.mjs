import assert from "node:assert/strict";
import test from "node:test";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { wasm as wasmTester } from "circom_tester";
import { buildPoseidon } from "circomlibjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const circuitPath = path.join(__dirname, "..", "otp_auth.circom");
const hasCircom = spawnSync("circom", ["--version"], { stdio: "ignore" }).status === 0;

test("otp_auth derives a deterministic nullifier", { skip: !hasCircom }, async () => {
  const circuit = await wasmTester(circuitPath, {
    include: [path.join(__dirname, "..", "node_modules")]
  });
  const poseidon = await buildPoseidon();
  const F = poseidon.F;

  const secret = 123456789n;
  const salt = 987654321n;
  const commitment = F.toObject(poseidon([secret, salt]));
  const chainId = 1n;
  const verifyingContract = 0x1111111111111111111111111111111111111111n;
  const actionHash = 42n;
  const nonce = 7n;
  const deadline = 1800000000n;
  const challenge = F.toObject(
    poseidon([chainId, verifyingContract, actionHash, nonce, deadline, commitment])
  );
  const nullifier = F.toObject(poseidon([secret, challenge]));

  const witness = await circuit.calculateWitness({
    chainId,
    verifyingContract,
    actionHash,
    nonce,
    deadline,
    commitment,
    secret,
    salt
  });

  await circuit.checkConstraints(witness);
  assert.equal(witness[1].toString(), nullifier.toString());
});
