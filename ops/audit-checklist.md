# Audit Checklist

## Critical

- [ ] Every public signal is checked against runtime state before proof verification.
- [ ] `nullifier` is a circuit output, not a prover-chosen public input.
- [ ] Delegate storage only uses the ERC-7201 namespace helper.
- [ ] Delegate state-changing functions are `onlySelf`.
- [ ] Relayer rejects EIP-7702 authorizations with `chainId = 0`.
- [ ] Rotation circuit proves knowledge of both old and new commitment preimages.
- [ ] Generated verifier public input ordering matches contracts and prover types.

## High

- [ ] Keccak-to-field reduction matches prover and Solidity exactly.
- [ ] G2 proof limb ordering is covered by an end-to-end proof test.
- [ ] Ceremony transcript hashes are published and independently reproducible.
- [ ] Deadline windows are short and configurable by policy.
- [ ] Registration requires proof of commitment preimage.
- [ ] Safe module proof binds `verifyingContract` to the Safe address, not the module.

## Medium

- [ ] Mobile and browser proving performance benchmarked.
- [ ] Verifier gas measured on target networks.
- [ ] Salt policy documented.
- [ ] Batch execution revert semantics documented.
- [ ] Safe module tested against a real Safe v1.4.1 deployment.

## Informational

- [ ] Event schema supports monitoring and incident response.
- [ ] Plonky3/SP1 migration path documented.
- [ ] User docs explain EOA key compromise limitations.
