# Threat Model

## In Scope

- Replay of previously valid ZK proofs.
- Public input substitution.
- Cross-chain misuse of EIP-7702 authorizations.
- Delegate storage collision.
- Safe module execution against the wrong Safe.
- Rotation to a commitment whose preimage is unknown.

## Out of Scope

- Compromise of the EOA private key.
- Malware extracting local secret material.
- Malicious frontends presenting one action while proving another.
- Rollup, bridge, RPC, or validator compromise.
- Guardian or social recovery systems.

## Core Assumptions

- The generated verifier contracts match the exact circuit artifacts used by the prover.
- The trusted setup has at least one honest contributor.
- The wallet or dApp displays the decoded action before proving.
- EIP-7702 authorization signing is explicit about `chainId`.
