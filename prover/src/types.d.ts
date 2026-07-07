declare module "snarkjs" {
  export const groth16: {
    fullProve(
      input: Record<string, string>,
      wasmPath: string,
      zkeyPath: string
    ): Promise<{
      proof: {
        pi_a: [string, string, string?];
        pi_b: [[string, string], [string, string], [string, string]?];
        pi_c: [string, string, string?];
      };
      publicSignals: string[];
    }>;
  };
}

declare module "circomlibjs" {
  export function buildPoseidon(): Promise<{
    (inputs: Array<bigint | number | string>): unknown;
    F: { toObject(value: unknown): bigint };
  }>;
}
