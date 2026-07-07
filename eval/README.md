# Evaluation Artifacts

`measurements.json` contains the reproducible snarkjs/Foundry measurements reported
in the paper:

- R1CS constraint count
- Groth16 proof generation time
- proof JSON size
- verifier success flag

Generated proving keys, proofs, witnesses, R1CS files, WASM files, and `.ptau`
artifacts are intentionally excluded from git. Regenerate them with:

```bash
cd ../circuits
./scripts/build-groth16.sh
```
