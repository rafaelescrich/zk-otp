import { execFileSync } from "node:child_process";

const expected = "2.1.6";

let output;
try {
  output = execFileSync("circom", ["--version"], { encoding: "utf8" }).trim();
} catch {
  console.error("circom is not installed. Install the Rust compiler with:");
  console.error("cargo install --git https://github.com/iden3/circom.git --tag v2.1.6 --locked");
  process.exit(1);
}

if (!output.includes(expected)) {
  console.error(`expected circom ${expected}, got: ${output}`);
  process.exit(1);
}

console.log(output);
