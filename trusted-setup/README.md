# Trusted Setup Workspace

Groth16 requires a per-circuit Phase 2 ceremony. Do not commit large `.ptau`, `.r1cs`, `.wasm`, or `.zkey` files unless you intentionally want them in source control.

Expected final outputs:

- `ceremony/otp_auth_final.zkey`
- `ceremony/otp_register_final.zkey`
- `ceremony/otp_rotate_final.zkey`
- generated Solidity verifiers copied into `../contracts/src/verifiers/`
- generated WASM and final zkey files copied into the prover artifact bundle

## Phase 1

Use a public Powers of Tau transcript such as Hermez `powersOfTau28_hez_final_15.ptau`.

```bash
cd zkp-2fa/trusted-setup
curl -L \
  https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_15.ptau \
  -o ptau/powersOfTau28_hez_final_15.ptau
```

## Phase 2

```bash
./phase2.sh otp_auth
./phase2.sh otp_register
./phase2.sh otp_rotate
```

Each contributor should archive:

- input zkey hash
- output zkey hash
- name or pseudonym
- command transcript
- final beacon transcript

For production, run a public ceremony with external contributors and publish transcripts before deploying verifier contracts.
