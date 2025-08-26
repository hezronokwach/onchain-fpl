#!/bin/bash

# OnChain FPL Contract Interaction Script
# Usage: ./scripts/interact.sh [command] [args...]

set -e

RPC_URL=${BASE_SEPOLIA_RPC_URL:-"https://sepolia.base.org"}
POOL_MANAGER=${POOL_MANAGER_ADDRESS:-""}
TEAM_MANAGER=${TEAM_MANAGER_ADDRESS:-""}

if [ -z "$POOL_MANAGER" ]; then
    echo "❌ POOL_MANAGER_ADDRESS not set"
    exit 1
fi

case "$1" in
    "create-pool")
        MATCHWEEK=${2:-1}
        DEADLINE=${3:-$(($(date +%s) + 3600))}
        
        echo "🏊 Creating pool for matchweek $MATCHWEEK..."
        cast send $POOL_MANAGER \
          "createPool(uint256,uint256)" \
          $MATCHWEEK $DEADLINE \
          --private-key $PRIVATE_KEY \
          --rpc-url $RPC_URL
        echo "✅ Pool created!"
        ;;
        
    "join-pool")
        MATCHWEEK=${2:-1}
        ENTRY_FEE=${3:-50000000000000000}  # 0.05 ETH in wei
        
        echo "🎫 Joining pool for matchweek $MATCHWEEK..."
        cast send $POOL_MANAGER \
          "joinPool(uint256)" \
          $MATCHWEEK \
          --value $ENTRY_FEE \
          --private-key $PRIVATE_KEY \
          --rpc-url $RPC_URL
        echo "✅ Joined pool!"
        ;;
        
    "get-pool")
        MATCHWEEK=${2:-1}
        
        echo "📊 Getting pool info for matchweek $MATCHWEEK..."
        cast call $POOL_MANAGER \
          "getPool(uint256)" \
          $MATCHWEEK \
          --rpc-url $RPC_URL
        ;;
        
    "check-entry")
        MATCHWEEK=${2:-1}
        USER_ADDRESS=${3:-$(cast wallet address --private-key $PRIVATE_KEY)}
        
        echo "🔍 Checking if $USER_ADDRESS entered matchweek $MATCHWEEK..."
        cast call $POOL_MANAGER \
          "hasUserEntered(uint256,address)(bool)" \
          $MATCHWEEK $USER_ADDRESS \
          --rpc-url $RPC_URL
        ;;
        
    "get-balance")
        ADDRESS=${2:-$(cast wallet address --private-key $PRIVATE_KEY)}
        
        echo "💰 Balance for $ADDRESS:"
        cast balance $ADDRESS --rpc-url $RPC_URL
        ;;
        
    "convert-wei")
        WEI_AMOUNT=$2
        echo "Converting $WEI_AMOUNT wei to ETH:"
        cast --from-wei $WEI_AMOUNT
        ;;
        
    "convert-eth")
        ETH_AMOUNT=$2
        echo "Converting $ETH_AMOUNT ETH to wei:"
        cast --to-wei $ETH_AMOUNT ether
        ;;
        
    *)
        echo "OnChain FPL Contract Interaction Script"
        echo ""
        echo "Usage: $0 [command] [args...]"
        echo ""
        echo "Commands:"
        echo "  create-pool [matchweek] [deadline]     Create a new pool"
        echo "  join-pool [matchweek] [entry_fee]      Join a pool"
        echo "  get-pool [matchweek]                   Get pool information"
        echo "  check-entry [matchweek] [address]      Check if user entered pool"
        echo "  get-balance [address]                  Get ETH balance"
        echo "  convert-wei [amount]                   Convert wei to ETH"
        echo "  convert-eth [amount]                   Convert ETH to wei"
        echo ""
        echo "Examples:"
        echo "  $0 create-pool 1 1640995200"
        echo "  $0 join-pool 1"
        echo "  $0 get-pool 1"
        echo "  $0 check-entry 1 0x742d35Cc6634C0532925a3b8D4C9db96590c6C87"
        ;;
esac