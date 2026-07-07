#!/usr/bin/env bash
# Reproducible Groth16 setup + real Solidity verifiers + proof measurements.
# Circuits max ~1074 constraints → Powers of Tau 2^12 (4096) is enough.
# NOTE: fixed entropy = reproducible measurement build, NOT a production ceremony.
set -euo pipefail
cd "$(dirname "$0")/.."   # circuits/
SNARKJS="npx --yes snarkjs"
PTAU=build/pot12_final.ptau
RESULTS=build/measurements.json

echo "== inputs =="; node scripts/gen-inputs.mjs

if [ ! -f "$PTAU" ]; then
  echo "== Powers of Tau (2^12) =="
  $SNARKJS powersoftau new bn128 12 build/pot12_0.ptau -v
  $SNARKJS powersoftau contribute build/pot12_0.ptau build/pot12_1.ptau --name="measure" -e="zkotp-measure-entropy"
  $SNARKJS powersoftau prepare phase2 build/pot12_1.ptau "$PTAU" -v
fi

echo "{" > "$RESULTS"
first=1
for c in auth register rotate; do
  D="build/$c"; R="$D/otp_$c.r1cs"; WASM="$D/otp_${c}_js/otp_$c.wasm"
  ZK="$D/otp_${c}_final.zkey"; VK="$D/otp_${c}_vkey.json"
  IN="build/input_$c.json"; PROOF="$D/proof.json"; PUB="$D/public.json"

  echo "== groth16 setup: $c =="
  $SNARKJS groth16 setup "$R" "$PTAU" "$D/otp_${c}_0.zkey"
  $SNARKJS zkey contribute "$D/otp_${c}_0.zkey" "$ZK" --name="measure" -e="zkotp-$c-entropy"
  $SNARKJS zkey export verificationkey "$ZK" "$VK"
  $SNARKJS zkey export solidityverifier "$ZK" "$D/Verifier_$c.sol"

  echo "== prove + measure: $c =="
  t0=$(node -e 'console.log(Date.now())')
  $SNARKJS groth16 fullprove "$IN" "$WASM" "$ZK" "$PROOF" "$PUB"
  t1=$(node -e 'console.log(Date.now())')
  $SNARKJS groth16 verify "$VK" "$PUB" "$PROOF" | grep -qi "OK" && ok=true || ok=false

  constraints=$($SNARKJS r1cs info "$R" 2>/dev/null \
    | sed $'s/\033\\[[0-9;]*m//g' \
    | awk '/# of Constraints/{print}' \
    | grep -Eo '[0-9]+$')
  proofbytes=$(wc -c < "$PROOF" | tr -d ' ')
  provems=$((t1 - t0))

  [ $first -eq 0 ] && echo "," >> "$RESULTS"; first=0
  printf '  "%s": {"constraints": %s, "prove_ms": %s, "proof_json_bytes": %s, "verify_ok": %s}' \
    "$c" "$constraints" "$provems" "$proofbytes" "$ok" >> "$RESULTS"
  echo "  -> $c: constraints=$constraints prove=${provems}ms proof=${proofbytes}B verify=$ok"
done
echo "" >> "$RESULTS"; echo "}" >> "$RESULTS"
echo "== measurements =="; cat "$RESULTS"

if [ -f scripts/install-verifiers.mjs ]; then
  echo "== installing real verifiers into contracts/ =="
  node scripts/install-verifiers.mjs
else
  echo "== verifier .sol exported to build/*/Verifier_*.sol (install step pending) =="
fi
