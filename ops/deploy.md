# Deployment Runbook

## Prerequisites

- Circuits compiled.
- Phase 2 ceremony complete for auth, register, and rotate.
- Generated verifier contracts copied to `contracts/src/verifiers/`.
- `forge test` passing against the real verifiers or against known-good calldata exported from `snarkjs`.
- Deployment private key funded on the target chain.

## Deployment Order

1. Deploy generated `AuthVerifier`.
2. Deploy generated `RotateVerifier`.
3. Deploy generated `RegisterVerifier`.
4. Deploy `ZkOtpDelegate` with all three verifier addresses.
5. Deploy `ZkOtpSafeModule` with the auth and register verifier addresses.
6. Verify all source on the chain explorer.
7. Publish ABIs, addresses, ceremony transcripts, and artifact hashes.

## Foundry Example

```bash
cd zkp-2fa/contracts

export PRIVATE_KEY=...
export RPC_URL=...
export AUTH_VERIFIER=0x...
export ROTATE_VERIFIER=0x...
export REGISTER_VERIFIER=0x...

forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  --verify
```

## EIP-7702 Guardrail

Wallet and relayer code must reject `chainId: 0` authorizations. A chain-agnostic authorization is replayable wherever the delegate address can be made to exist.

## CREATE2

For production, deploy the delegate and module deterministically across chains. Publish:

- salt
- init code hash
- deployer address
- resulting address per chain
