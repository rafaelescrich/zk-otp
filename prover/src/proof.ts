export interface SolidityProof {
  a: [bigint, bigint];
  b: [[bigint, bigint], [bigint, bigint]];
  c: [bigint, bigint];
}

export type AuthPublicSignals = [bigint, bigint, bigint, bigint, bigint, bigint, bigint];
export type RegisterPublicSignals = [bigint, bigint];

export interface AuthProof extends SolidityProof {
  publicSignals: AuthPublicSignals;
}

export interface RegisterProof extends SolidityProof {
  publicSignals: RegisterPublicSignals;
}

export interface RotateProof extends SolidityProof {
  publicSignals: AuthPublicSignals;
}

export function formatSolidityProof(proof: {
  pi_a: [string, string, string?];
  pi_b: [[string, string], [string, string], [string, string]?];
  pi_c: [string, string, string?];
}): SolidityProof {
  return {
    a: [BigInt(proof.pi_a[0]), BigInt(proof.pi_a[1])],
    b: [
      [BigInt(proof.pi_b[0][1]), BigInt(proof.pi_b[0][0])],
      [BigInt(proof.pi_b[1][1]), BigInt(proof.pi_b[1][0])]
    ],
    c: [BigInt(proof.pi_c[0]), BigInt(proof.pi_c[1])]
  };
}

export function tuple<T extends bigint[], N extends number>(
  values: string[],
  expectedLength: N
): T {
  if (values.length !== expectedLength) {
    throw new Error(`expected ${expectedLength} public signals, got ${values.length}`);
  }
  return values.map(BigInt) as T;
}
