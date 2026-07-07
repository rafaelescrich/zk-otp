// Install snarkjs-exported Groth16 verifiers into contracts/src/verifiers/,
// renaming the `Groth16Verifier` contract to the repo's interface-conformant names.
// snarkjs export signature: verifyProof(uint[2] a, uint[2][2] b, uint[2] c, uint[N] pub)
// which already matches IAuthVerifier/IRegisterVerifier/IRotateVerifier.
import { readFileSync, writeFileSync } from "node:fs";

const map = [
  { circuit: "auth", name: "AuthVerifier" },
  { circuit: "register", name: "RegisterVerifier" },
  { circuit: "rotate", name: "RotateVerifier" },
];

for (const { circuit, name } of map) {
  const src = readFileSync(`build/${circuit}/Verifier_${circuit}.sol`, "utf8");
  const renamed = src.replace(/contract\s+Groth16Verifier\b/, `contract ${name}`);
  const out = `../contracts/src/verifiers/${name}.sol`;
  writeFileSync(out, renamed);
  console.log(`installed ${out}`);
}
