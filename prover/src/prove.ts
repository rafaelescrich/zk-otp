import { groth16 } from "snarkjs";
import type { Address, Hex } from "viem";
import {
  DEFAULT_AUTH_WASM_PATH,
  DEFAULT_AUTH_ZKEY_PATH,
  DEFAULT_REGISTER_WASM_PATH,
  DEFAULT_REGISTER_ZKEY_PATH,
  DEFAULT_ROTATE_WASM_PATH,
  DEFAULT_ROTATE_ZKEY_PATH
} from "./constants.js";
import {
  type Call,
  delegateActionHash,
  registrationBinding,
  safeActionHash
} from "./actionHash.js";
import { commitmentFor } from "./poseidon.js";
import type { SecretStore } from "./secretStore.js";
import {
  type AuthProof,
  type AuthPublicSignals,
  type RegisterProof,
  type RegisterPublicSignals,
  type RotateProof,
  formatSolidityProof,
  tuple
} from "./proof.js";

export interface ArtifactPaths {
  wasmPath?: string;
  zkeyPath?: string;
}

export interface AuthProveInput extends ArtifactPaths {
  store: SecretStore;
  chainId: bigint;
  verifyingContract: Address;
  calls: readonly Call[];
  nonce: bigint;
  deadline: bigint;
  commitment: bigint;
}

export interface SafeAuthProveInput extends ArtifactPaths {
  store: SecretStore;
  chainId: bigint;
  safe: Address;
  module: Address;
  target: Address;
  value: bigint;
  data: Hex;
  nonce: bigint;
  deadline: bigint;
  commitment: bigint;
}

export interface RegisterProveInput extends ArtifactPaths {
  store: SecretStore;
  chainId: bigint;
  account: Address;
  commitment: bigint;
}

export interface RotateProveInput extends ArtifactPaths {
  store: SecretStore;
  chainId: bigint;
  verifyingContract: Address;
  oldCommitment: bigint;
  newSecret: bigint;
  newSalt: bigint;
  nonce: bigint;
  deadline: bigint;
}

export async function proveAuth(input: AuthProveInput): Promise<AuthProof> {
  const { secret, salt } = await input.store.getWitness();
  await assertCommitmentMatches(secret, salt, input.commitment);

  const actionHash = delegateActionHash(input.calls);
  const { proof, publicSignals } = await groth16.fullProve(
    {
      chainId: input.chainId.toString(),
      verifyingContract: BigInt(input.verifyingContract).toString(),
      actionHash: actionHash.toString(),
      nonce: input.nonce.toString(),
      deadline: input.deadline.toString(),
      commitment: input.commitment.toString(),
      secret: secret.toString(),
      salt: salt.toString()
    },
    input.wasmPath ?? DEFAULT_AUTH_WASM_PATH,
    input.zkeyPath ?? DEFAULT_AUTH_ZKEY_PATH
  );

  return {
    ...formatSolidityProof(proof),
    publicSignals: tuple<AuthPublicSignals, 7>(publicSignals, 7)
  };
}

export async function proveAuthForSafe(input: SafeAuthProveInput): Promise<AuthProof> {
  const { secret, salt } = await input.store.getWitness();
  await assertCommitmentMatches(secret, salt, input.commitment);

  const actionHash = safeActionHash(input);
  const { proof, publicSignals } = await groth16.fullProve(
    {
      chainId: input.chainId.toString(),
      verifyingContract: BigInt(input.safe).toString(),
      actionHash: actionHash.toString(),
      nonce: input.nonce.toString(),
      deadline: input.deadline.toString(),
      commitment: input.commitment.toString(),
      secret: secret.toString(),
      salt: salt.toString()
    },
    input.wasmPath ?? DEFAULT_AUTH_WASM_PATH,
    input.zkeyPath ?? DEFAULT_AUTH_ZKEY_PATH
  );

  return {
    ...formatSolidityProof(proof),
    publicSignals: tuple<AuthPublicSignals, 7>(publicSignals, 7)
  };
}

export async function proveRegister(input: RegisterProveInput): Promise<RegisterProof> {
  const { secret, salt } = await input.store.getWitness();
  await assertCommitmentMatches(secret, salt, input.commitment);
  const bindingHash = registrationBinding(input);

  const { proof, publicSignals } = await groth16.fullProve(
    {
      commitment: input.commitment.toString(),
      bindingHash: bindingHash.toString(),
      secret: secret.toString(),
      salt: salt.toString()
    },
    input.wasmPath ?? DEFAULT_REGISTER_WASM_PATH,
    input.zkeyPath ?? DEFAULT_REGISTER_ZKEY_PATH
  );

  return {
    ...formatSolidityProof(proof),
    publicSignals: tuple<RegisterPublicSignals, 2>(publicSignals, 2)
  };
}

export async function proveRotate(input: RotateProveInput): Promise<RotateProof> {
  const { secret: oldSecret, salt: oldSalt } = await input.store.getWitness();
  await assertCommitmentMatches(oldSecret, oldSalt, input.oldCommitment);
  const newCommitment = await commitmentFor(input.newSecret, input.newSalt);

  const { proof, publicSignals } = await groth16.fullProve(
    {
      oldCommitment: input.oldCommitment.toString(),
      newCommitment: newCommitment.toString(),
      chainId: input.chainId.toString(),
      verifyingContract: BigInt(input.verifyingContract).toString(),
      nonce: input.nonce.toString(),
      deadline: input.deadline.toString(),
      oldSecret: oldSecret.toString(),
      oldSalt: oldSalt.toString(),
      newSecret: input.newSecret.toString(),
      newSalt: input.newSalt.toString()
    },
    input.wasmPath ?? DEFAULT_ROTATE_WASM_PATH,
    input.zkeyPath ?? DEFAULT_ROTATE_ZKEY_PATH
  );

  return {
    ...formatSolidityProof(proof),
    publicSignals: tuple<AuthPublicSignals, 7>(publicSignals, 7)
  };
}

async function assertCommitmentMatches(
  secret: bigint,
  salt: bigint,
  expectedCommitment: bigint
): Promise<void> {
  const computedCommitment = await commitmentFor(secret, salt);
  if (computedCommitment !== expectedCommitment) {
    throw new Error("stored secret does not match on-chain commitment; refusing to prove");
  }
}
