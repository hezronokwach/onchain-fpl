const counterContractAddress = '0x1fA8696683A43AA046e2fE4274CDc1a7C668691b' as `0x${string}`; // add your contract address here
const counterContractAbi = [
  {
    type: 'function',
    name: 'increment',
    inputs: [],
    outputs: [],
    stateMutability: 'nonpayable',
  },
] as const;

export const calls = [
  {
    to: counterContractAddress,
    abi: counterContractAbi,
    functionName: 'increment',
    args: [],
  },
];