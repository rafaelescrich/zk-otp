import {
  type Address,
  type Chain,
  type Hex,
  createPublicClient,
  createWalletClient,
  encodeFunctionData,
  http
} from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { delegateAbi, safeModuleAbi } from "./abi.js";
import type { Call } from "./actionHash.js";
import { proveAuth, proveAuthForSafe } from "./prove.js";
import type { SecretStore } from "./secretStore.js";

export interface Execute7702Args {
  eoaPrivateKey: Hex;
  eoa: Address;
  delegate: Address;
  store: SecretStore;
  calls: readonly Call[];
  chain: Chain;
  rpcUrl: string;
  relayerPrivateKey?: Hex;
  deadlineSeconds?: number;
}

export async function executeWithProof7702(args: Execute7702Args): Promise<Hex> {
  if (!args.chain.id) {
    throw new Error("EIP-7702 authorization must use an explicit non-zero chainId");
  }

  const eoaAccount = privateKeyToAccount(args.eoaPrivateKey);
  const relayerAccount = privateKeyToAccount(
    args.relayerPrivateKey ?? (process.env.RELAYER_KEY as Hex)
  );
  const transport = http(args.rpcUrl);
  const publicClient = createPublicClient({ chain: args.chain, transport });
  const walletClient = createWalletClient({
    account: relayerAccount,
    chain: args.chain,
    transport
  });

  const nonce = await publicClient.readContract({
    address: args.eoa,
    abi: delegateAbi,
    functionName: "nonce"
  });
  const commitmentHex = await publicClient.readContract({
    address: args.eoa,
    abi: delegateAbi,
    functionName: "commitment"
  });
  const deadline = BigInt(Math.floor(Date.now() / 1000) + (args.deadlineSeconds ?? 300));

  const proof = await proveAuth({
    store: args.store,
    chainId: BigInt(args.chain.id),
    verifyingContract: args.eoa,
    calls: args.calls,
    nonce,
    deadline,
    commitment: BigInt(commitmentHex)
  });

  const authorization = await walletClient.signAuthorization({
    account: eoaAccount,
    contractAddress: args.delegate,
    chainId: args.chain.id
  });

  const data = encodeFunctionData({
    abi: delegateAbi,
    functionName: "executeWithProof",
    args: [args.calls, deadline, proof, proof.publicSignals]
  });

  return walletClient.sendTransaction({
    authorizationList: [authorization],
    to: args.eoa,
    data
  });
}

export interface ExecuteSafeModuleArgs {
  safe: Address;
  module: Address;
  target: Address;
  value: bigint;
  data: Hex;
  store: SecretStore;
  chain: Chain;
  rpcUrl: string;
  relayerPrivateKey: Hex;
  deadlineSeconds?: number;
}

export async function executeViaSafeModule(args: ExecuteSafeModuleArgs): Promise<Hex> {
  const relayerAccount = privateKeyToAccount(args.relayerPrivateKey);
  const transport = http(args.rpcUrl);
  const publicClient = createPublicClient({ chain: args.chain, transport });
  const walletClient = createWalletClient({
    account: relayerAccount,
    chain: args.chain,
    transport
  });

  const nonce = await publicClient.readContract({
    address: args.module,
    abi: safeModuleAbi,
    functionName: "nonceOf",
    args: [args.safe]
  });
  const commitmentHex = await publicClient.readContract({
    address: args.module,
    abi: safeModuleAbi,
    functionName: "commitmentOf",
    args: [args.safe]
  });
  const deadline = BigInt(Math.floor(Date.now() / 1000) + (args.deadlineSeconds ?? 300));

  const proof = await proveAuthForSafe({
    store: args.store,
    chainId: BigInt(args.chain.id),
    safe: args.safe,
    module: args.module,
    target: args.target,
    value: args.value,
    data: args.data,
    nonce,
    deadline,
    commitment: BigInt(commitmentHex)
  });

  const callData = encodeFunctionData({
    abi: safeModuleAbi,
    functionName: "executeWithProof",
    args: [
      args.safe,
      args.target,
      args.value,
      args.data,
      deadline,
      proof,
      proof.publicSignals
    ]
  });

  return walletClient.sendTransaction({ to: args.module, data: callData });
}
