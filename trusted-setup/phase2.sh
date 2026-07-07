#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <otp_auth|otp_register|otp_rotate>" >&2
  exit 1
fi

CIRCUIT="$1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PTAU="$ROOT/trusted-setup/ptau/powersOfTau28_hez_final_15.ptau"
BUILD="$ROOT/circuits/build/${CIRCUIT#otp_}"
OUT="$ROOT/trusted-setup/ceremony"

mkdir -p "$OUT"

if [ ! -f "$PTAU" ]; then
  echo "missing Powers of Tau file: $PTAU" >&2
  exit 1
fi

if [ ! -f "$BUILD/${CIRCUIT}.r1cs" ]; then
  echo "missing circuit r1cs: $BUILD/${CIRCUIT}.r1cs" >&2
  echo "run the circuit compile step first" >&2
  exit 1
fi

snarkjs groth16 setup "$BUILD/${CIRCUIT}.r1cs" "$PTAU" "$OUT/${CIRCUIT}_0000.zkey"
snarkjs zkey contribute "$OUT/${CIRCUIT}_0000.zkey" "$OUT/${CIRCUIT}_0001.zkey" \
  --name="Contributor 1" \
  -v \
  -e="$(head -c 64 /dev/urandom | base64)"
snarkjs zkey beacon "$OUT/${CIRCUIT}_0001.zkey" "$OUT/${CIRCUIT}_final.zkey" \
  0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20 \
  10 \
  -n="Final beacon"
snarkjs zkey verify "$BUILD/${CIRCUIT}.r1cs" "$PTAU" "$OUT/${CIRCUIT}_final.zkey"
