import {
  type Address,
  type Hex,
  encodeAbiParameters,
  keccak256,
  parseAbiParameters
} from "viem";
import { reduceToField } from "./constants.js";

export interface Call {
  target: Address;
  value: bigint;
  data: Hex;
}

export function bigintFromHex(hex: Hex): bigint {
  return BigInt(hex);
}

export function delegateActionHash(calls: readonly Call[]): bigint {
  const encoded = encodeAbiParameters(
    parseAbiParameters("(address target, uint256 value, bytes data)[]"),
    [calls]
  );
  return reduceToField(bigintFromHex(keccak256(encoded)));
}

export function safeActionHash(input: {
  safe: Address;
  target: Address;
  value: bigint;
  data: Hex;
  module: Address;
}): bigint {
  const encoded = encodeAbiParameters(
    parseAbiParameters("address safe, address target, uint256 value, bytes data, address module"),
    [input.safe, input.target, input.value, input.data, input.module]
  );
  return reduceToField(bigintFromHex(keccak256(encoded)));
}

export function registrationBinding(input: {
  commitment: bigint;
  account: Address;
  chainId: bigint;
}): bigint {
  const encoded = encodeAbiParameters(
    parseAbiParameters("bytes32 commitment, address account, uint256 chainId"),
    [
      `0x${input.commitment.toString(16).padStart(64, "0")}` as Hex,
      input.account,
      input.chainId
    ]
  );
  return reduceToField(bigintFromHex(keccak256(encoded)));
}
