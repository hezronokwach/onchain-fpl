'use client';

import { Transaction } from '@coinbase/onchainkit/transaction';
import { Wallet, ConnectWallet } from '@coinbase/onchainkit/wallet';
import { calls } from './calls';

export default function Home() {
  return (
    <main className="flex flex-grow items-center justify-center">
      <div className="w-full max-w-4xl p-4">
        <div className="mx-auto mb-6 w-1/3">
          <Wallet>
            <ConnectWallet />
            <Transaction calls={calls} />
          </Wallet>
        </div>
      </div>
    </main>
  );
}