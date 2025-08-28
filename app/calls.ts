import { CONTRACTS } from './config/contracts';
import { POOL_MANAGER_ABI } from './config/abis';

// OnChain FPL contract calls
export const calls = [
  {
    to: CONTRACTS.POOL_MANAGER,
    abi: POOL_MANAGER_ABI,
    functionName: 'joinPool',
    args: [1], // Join matchweek 1 pool
    value: BigInt('150000000000000'), // 0.00015 ETH in wei
  },
];