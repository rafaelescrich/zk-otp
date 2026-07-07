export const FIELD_PRIME = BigInt(
  "21888242871839275222246405745257275088548364400416034343698204186575808495617"
);

export const DEFAULT_AUTH_WASM_PATH = "./artifacts/otp_auth.wasm";
export const DEFAULT_AUTH_ZKEY_PATH = "./artifacts/otp_auth_final.zkey";
export const DEFAULT_REGISTER_WASM_PATH = "./artifacts/otp_register.wasm";
export const DEFAULT_REGISTER_ZKEY_PATH = "./artifacts/otp_register_final.zkey";
export const DEFAULT_ROTATE_WASM_PATH = "./artifacts/otp_rotate.wasm";
export const DEFAULT_ROTATE_ZKEY_PATH = "./artifacts/otp_rotate_final.zkey";

export function reduceToField(value: bigint): bigint {
  const reduced = value % FIELD_PRIME;
  return reduced >= 0n ? reduced : reduced + FIELD_PRIME;
}
