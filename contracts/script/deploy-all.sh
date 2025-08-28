#!/bin/bash

# OnChain FPL - Deploy All Contracts to Base Sepolia
echo "🚀 Deploying OnChain FPL to Base Sepolia Testnet"
echo "================================================"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found"
    echo "Please create .env with your PRIVATE_KEY"
    exit 1
fi

# Load environment variables
source .env

# Check if private key is set
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set in .env file"
    exit 1
fi

echo "📋 Pre-deployment checks..."
echo "✅ Private key loaded"
echo "✅ Base Sepolia RPC: $BASE_SEPOLIA_RPC_URL"

echo ""
echo "🔨 Compiling contracts..."
forge build

if [ $? -ne 0 ]; then
    echo "❌ Compilation failed"
    exit 1
fi

echo "✅ Compilation successful"
echo ""
echo "🚀 Deploying all contracts..."

# Deploy all contracts
forge script script/DeployAll.s.sol:DeployAll \
    --rpc-url $BASE_SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    -vvvv

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Copy the contract addresses from the output above"
    echo "2. Add them to your .env file"
    echo "3. Update your frontend with the new addresses"
    echo ""
    echo "🔍 View your contracts on BaseScan:"
    echo "https://sepolia.basescan.org/"
else
    echo "❌ Deployment failed"
    exit 1
fi