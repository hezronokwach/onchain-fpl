'use client';

import { Wallet, ConnectWallet } from '@coinbase/onchainkit/wallet';
import { PoolManager } from './components/PoolManager';

export default function Home() {
  return (
    <main className="min-h-screen bg-gray-100">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">OnChain FPL</h1>
          <p className="text-gray-600">Fantasy Premier League on Base Blockchain</p>
        </div>

        {/* Wallet Connection */}
        <div className="flex justify-center mb-8">
          <Wallet>
            <ConnectWallet />
          </Wallet>
        </div>

        {/* Pool Manager */}
        <PoolManager />

        {/* Status */}
        <div className="mt-8 text-center text-sm text-gray-500">
          <p>Connected to Base Sepolia Testnet</p>
          <p>Contracts deployed and ready for testing</p>
        </div>
      </div>
    </main>
  );
}