# ZK-OTP

Action-bound zero-knowledge two-factor authorization for EOAs via EIP-7702 and
for smart-contract wallets via a Safe module.

This repository contains the reference research prototype for the paper:

`ZK-OTP: Action-Bound Zero-Knowledge Two-Factor Authorization for EOAs (EIP-7702) and Smart-Contract Wallets`

## What is included

- `paper/` - LaTeX draft for IACR ePrint / workshop submission.
- `circuits/` - Circom 2.1.6 circuits for authentication, registration, and rotation.
- `contracts/` - Solidity contracts, real exported Groth16 verifiers, and Foundry tests.
- `prover/` - TypeScript helpers for action hashing, proof handling, and relayer integration.
- `trusted-setup/` - setup notes and Phase-2 ceremony script.
- `ops/` - deployment, audit, and threat-model notes.
- `eval/` - measured constraint/proving/gas artifacts used by the paper.

Large generated artifacts are intentionally excluded: `node_modules`, `build/`,
`.ptau`, `.zkey`, `.wasm`, `.r1cs`, Foundry `out/`, and cache directories.

## Status

Research prototype. The Groth16 verifiers in `contracts/src/verifiers/` are real
snarkjs-exported Solidity verifiers, and the gas test suite uses real proof calldata.
The included Phase-2 setup artifacts are not committed; production deployments require
a multi-contributor ceremony or a transparent proving backend.

This is not audited production infrastructure.

## Quick start

### Circuits

```bash
cd circuits
cargo install --git https://github.com/iden3/circom.git --tag v2.1.6 --locked
npm install
npm run compile
npm test
```

### Groth16 build and measurements

```bash
cd circuits
./scripts/build-groth16.sh
```

This regenerates proving/verifying keys, proofs, Solidity verifiers, and
measurement JSON under `circuits/build/`. Generated files are ignored by git.

### Install exported verifiers into contracts

```bash
cd circuits
node scripts/install-verifiers.mjs
```

### Contracts

Install Foundry and `forge-std` first:

```bash
cd contracts
forge install foundry-rs/forge-std
forge build
forge test
```

### Prover helpers

```bash
cd prover
npm install
npm run typecheck
```

## Measured prototype numbers

The current reproducible measurements are stored in `eval/measurements.json`.

| Circuit | Constraints | Proof | Verify gas | Prove time |
| --- | ---: | ---: | ---: | ---: |
| `otp_auth` | 834 | 256 B | 231,080 | 581 ms |
| `otp_register` | 240 | 256 B | 197,504 | 683 ms |
| `otp_rotate` | 1074 | 256 B | 231,080 | 887 ms |

## Security notes

- EIP-7702 authorizations must use explicit non-zero `chainId`.
- The delegate stores state in an ERC-7201 namespaced slot because delegated code
  executes in the EOA storage context.
- `executeWithProof` binds the full canonical call encoding: target, ETH value,
  calldata, chain, verifying contract, nonce, deadline, and commitment.
- The ZK factor is additive for EOAs: the base EOA key can replace or clear the
  delegate. Safe deployments have a different recovery and governance surface.
- The Groth16 path uses a trusted setup and is not post-quantum. Transparent
  FRI/STARK proving is treated as a migration path, not a measured implementation here.

## Paper

Compile the paper with:

```bash
cd paper
pdflatex zk-otp.tex
pdflatex zk-otp.tex
```

## License

MIT.
