export const delegateAbi = [
  {
    type: "function",
    name: "commitment",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "bytes32" }]
  },
  {
    type: "function",
    name: "nonce",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    type: "function",
    name: "executeWithProof",
    stateMutability: "payable",
    inputs: [
      {
        name: "calls",
        type: "tuple[]",
        components: [
          { name: "target", type: "address" },
          { name: "value", type: "uint256" },
          { name: "data", type: "bytes" }
        ]
      },
      { name: "deadline", type: "uint256" },
      {
        name: "proof",
        type: "tuple",
        components: [
          { name: "a", type: "uint256[2]" },
          { name: "b", type: "uint256[2][2]" },
          { name: "c", type: "uint256[2]" }
        ]
      },
      { name: "publicSignals", type: "uint256[7]" }
    ],
    outputs: []
  },
  {
    type: "function",
    name: "register",
    stateMutability: "nonpayable",
    inputs: [
      { name: "commitment", type: "bytes32" },
      {
        name: "proof",
        type: "tuple",
        components: [
          { name: "a", type: "uint256[2]" },
          { name: "b", type: "uint256[2][2]" },
          { name: "c", type: "uint256[2]" }
        ]
      },
      { name: "publicSignals", type: "uint256[2]" }
    ],
    outputs: []
  }
] as const;

export const safeModuleAbi = [
  {
    type: "function",
    name: "commitmentOf",
    stateMutability: "view",
    inputs: [{ name: "safe", type: "address" }],
    outputs: [{ name: "", type: "bytes32" }]
  },
  {
    type: "function",
    name: "nonceOf",
    stateMutability: "view",
    inputs: [{ name: "safe", type: "address" }],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    type: "function",
    name: "executeWithProof",
    stateMutability: "nonpayable",
    inputs: [
      { name: "safe", type: "address" },
      { name: "target", type: "address" },
      { name: "value", type: "uint256" },
      { name: "data", type: "bytes" },
      { name: "deadline", type: "uint256" },
      {
        name: "proof",
        type: "tuple",
        components: [
          { name: "a", type: "uint256[2]" },
          { name: "b", type: "uint256[2][2]" },
          { name: "c", type: "uint256[2]" }
        ]
      },
      { name: "publicSignals", type: "uint256[7]" }
    ],
    outputs: [{ name: "", type: "bool" }]
  }
] as const;
