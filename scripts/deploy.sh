#!/bin/bash

# OnChain FPL Deployment Script
# Usage: ./scripts/deploy.sh [network]
# Example: ./scripts/deploy.sh sepolia

set -e

NETWORK=${1:-sepolia}

if [ "$NETWORK" = "sepolia" ]; then
    RPC_URL=$BASE_SEPOLIA_RPC_URL
    echo "🚀 Deploying to Base Sepolia..."
elif [ "$NETWORK" = "mainnet" ]; then
    RPC_URL=$BASE_MAINNET_RPC_URL
    echo "🚀 Deploying to Base Mainnet..."
    read -p "Are you sure you want to deploy to mainnet? (y/N): " confirm
    if [ "$confirm" != "y" ]; then
        echo "Deployment cancelled"
        exit 1
    fi
else
    echo "❌ Invalid network. Use 'sepolia' or 'mainnet'"
    exit 1
fi

# Check environment variables
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ PRIVATE_KEY not set"
    exit 1
fi

if [ -z "$RPC_URL" ]; then
    echo "❌ RPC_URL not set for $NETWORK"
    exit 1
fi

cd contracts

echo "📦 Building contracts..."
forge build

echo "🧪 Running tests..."
forge test

echo "🚀 Deploying contracts..."
forge script script/Deploy.s.sol \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  -vvvv

echo "✅ Deployment complete!"
echo "📋 Check deployment details in contracts/broadcast/"