'use client';

import { useReadContract, useWriteContract } from 'wagmi';
import { parseEther, formatEther } from 'viem';
import { CONTRACTS, ENTRY_FEE } from '../config/contracts';
import { POOL_MANAGER_ABI } from '../config/abis';

interface Pool {
  matchweek: bigint;
  entryFee: bigint;
  deadline: bigint;
  totalPrize: bigint;
  participants: string[];
  isActive: boolean;
  isFinalized: boolean;
  winner: string;
  winningScore: bigint;
}

export function PoolManager() {
  const { writeContract, isPending } = useWriteContract();
  
  // Read pool data for matchweek 1
  const { data: pool, isLoading } = useReadContract({
    address: CONTRACTS.POOL_MANAGER,
    abi: POOL_MANAGER_ABI,
    functionName: 'getPool',
    args: [1n],
  }) as { data: Pool | undefined, isLoading: boolean };

  const joinPool = async (matchweek: number) => {
    try {
      await writeContract({
        address: CONTRACTS.POOL_MANAGER,
        abi: POOL_MANAGER_ABI,
        functionName: 'joinPool',
        args: [BigInt(matchweek)],
        value: parseEther(ENTRY_FEE)
      });
    } catch (error) {
      console.error('Failed to join pool:', error);
    }
  };

  if (isLoading) {
    return <div className="p-4">Loading pool data...</div>;
  }

  return (
    <div className="max-w-2xl mx-auto p-6 bg-white rounded-lg shadow-lg">
      <h2 className="text-2xl font-bold mb-6 text-center">OnChain FPL Pools</h2>
      
      {pool && (
        <div className="space-y-4">
          <div className="bg-gray-50 p-4 rounded-lg">
            <h3 className="text-lg font-semibold mb-2">Matchweek {pool.matchweek.toString()}</h3>
            
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="font-medium">Entry Fee:</span>
                <div>{formatEther(pool.entryFee)} ETH</div>
              </div>
              
              <div>
                <span className="font-medium">Total Prize:</span>
                <div>{formatEther(pool.totalPrize)} ETH</div>
              </div>
              
              <div>
                <span className="font-medium">Participants:</span>
                <div>{pool.participants.length}</div>
              </div>
              
              <div>
                <span className="font-medium">Status:</span>
                <div className={pool.isActive ? 'text-green-600' : 'text-red-600'}>
                  {pool.isActive ? 'Active' : 'Closed'}
                </div>
              </div>
            </div>
            
            <div className="mt-4">
              <span className="font-medium">Deadline:</span>
              <div className="text-sm text-gray-600">
                {new Date(Number(pool.deadline) * 1000).toLocaleString()}
              </div>
            </div>
          </div>

          {pool.isActive && (
            <button
              onClick={() => joinPool(1)}
              disabled={isPending}
              className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white font-semibold py-3 px-6 rounded-lg transition-colors"
            >
              {isPending ? 'Joining Pool...' : `Join Pool (${ENTRY_FEE} ETH)`}
            </button>
          )}

          {pool.isFinalized && pool.winner !== '0x0000000000000000000000000000000000000000' && (
            <div className="bg-green-50 p-4 rounded-lg">
              <h4 className="font-semibold text-green-800">Pool Complete!</h4>
              <div className="text-sm text-green-700">
                Winner: {pool.winner}
              </div>
              <div className="text-sm text-green-700">
                Winning Score: {pool.winningScore.toString()} points
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}