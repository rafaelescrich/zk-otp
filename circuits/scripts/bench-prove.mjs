// In-process proving benchmark: witness generation + Groth16 proof, N iterations.
// Reports min/median/mean/stdev per circuit. More faithful than CLI wall-clock
// (no per-call process/npx startup). Run: node scripts/bench-prove.mjs
import * as snarkjs from "snarkjs";
import { readFileSync, writeFileSync } from "node:fs";

const N = Number(process.env.BENCH_N ?? 25);
const results = {};

for (const c of ["auth", "register", "rotate"]) {
  const wasm = `build/${c}/otp_${c}_js/otp_${c}.wasm`;
  const zkey = `build/${c}/otp_${c}_final.zkey`;
  const input = JSON.parse(readFileSync(`build/input_${c}.json`, "utf8"));

  await snarkjs.groth16.fullProve(input, wasm, zkey); // warmup (JIT, caches)

  const t = [];
  for (let i = 0; i < N; i++) {
    const t0 = performance.now();
    await snarkjs.groth16.fullProve(input, wasm, zkey);
    t.push(performance.now() - t0);
  }
  t.sort((a, b) => a - b);
  const mean = t.reduce((a, b) => a + b, 0) / N;
  const sd = Math.sqrt(t.reduce((a, b) => a + (b - mean) ** 2, 0) / N);
  const r = { n: N, min: +t[0].toFixed(1), median: +t[(N / 2) | 0].toFixed(1),
              mean: +mean.toFixed(1), sd: +sd.toFixed(1) };
  results[c] = r;
  console.log(`${c}: min=${r.min} median=${r.median} mean=${r.mean} sd=${r.sd} ms (N=${N})`);
}

writeFileSync("build/prove-bench.json", JSON.stringify(results, null, 2));
process.exit(0);
