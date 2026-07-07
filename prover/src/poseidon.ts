import { buildPoseidon } from "circomlibjs";
import { FIELD_PRIME, reduceToField } from "./constants.js";

let poseidonPromise: ReturnType<typeof buildPoseidon> | undefined;

export async function poseidonHash(inputs: readonly bigint[]): Promise<bigint> {
  poseidonPromise ??= buildPoseidon();
  const poseidon = await poseidonPromise;
  return poseidon.F.toObject(poseidon(inputs.map((value) => reduceToField(value))));
}

export async function commitmentFor(secret: bigint, salt: bigint): Promise<bigint> {
  return poseidonHash([secret, salt]);
}

export function randomFieldElement(): bigint {
  const bytes = new Uint8Array(32);
  globalThis.crypto.getRandomValues(bytes);

  let value = 0n;
  for (const byte of bytes) {
    value = (value << 8n) + BigInt(byte);
  }
  return value % FIELD_PRIME;
}
