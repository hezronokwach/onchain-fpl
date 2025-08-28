#!/bin/bash

# OnChain FPL Contract Interaction Script
# Usage: ./script/interact.sh [command] [args...]

set -e

# Load environment variables
if [ -f ".env" ]; then
    source .env
else
    echo "❌ .env file not found"
    exit 1
fi

RPC_URL=${BASE_SEPOLIA_RPC_URL:-"https://sepolia.base.org"}

# Check if contracts are deployed
if [ -z "$POOL_MANAGER_ADDRESS" ]; then
    echo "❌ Contract addresses not set in .env"
    echo "Please deploy contracts first with: ./script/deploy-all.sh"
    exit 1
fi

case "$1" in
    "create-pool")
        MATCHWEEK=${2:-1}
        DEADLINE=${3:-$(($(date +%s) + 3600))}
        
        echo "🏊 Creating pool for matchweek $MATCHWEEK..."
        cast send $POOL_MANAGER_ADDRESS \
          "createPool(uint256,uint256)" \
          $MATCHWEEK $DEADLINE \
          --private-key $PRIVATE_KEY \
          --rpc-url $RPC_URL
        echo "✅ Pool created!"
        ;;
        
    "join-pool")
        MATCHWEEK=${2:-1}
        ENTRY_FEE="0.00015ether"  # 0.00015 ETH
        
        echo "🎫 Joining pool for matchweek $MATCHWEEK..."
        cast send $POOL_MANAGER_ADDRESS \
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
        cast call $POOL_MANAGER_ADDRESS \
          "getPool(uint256)" \
          $MATCHWEEK \
          --rpc-url $RPC_URL
        ;;
        
    "get-participants")
        MATCHWEEK=${2:-1}
        
        echo "👥 Getting participants for matchweek $MATCHWEEK..."
        cast call $POOL_MANAGER_ADDRESS \
          "getParticipants(uint256)" \
          $MATCHWEEK \
          --rpc-url $RPC_URL
        ;;
        
    "check-balance")
        ADDRESS=${2:-$(cast wallet address --private-key $PRIVATE_KEY)}
        
        echo "💰 Balance for $ADDRESS:"
        cast balance $ADDRESS --rpc-url $RPC_URL
        ;;
        
    "add-player")
        PLAYER_ID=${2:-1}
        PLAYER_NAME=${3:-"Test Player"}
        POSITION=${4:-3}  # Forward
        PRICE=${5:-8500000}  # £8.5M in pence
        TEAM_ID=${6:-1}
        
        echo "⚽ Adding player: $PLAYER_NAME..."
        cast send $TEAM_MANAGER_ADDRESS \
          "addPlayer(uint256,string,uint8,uint256,uint256)" \
          $PLAYER_ID "$PLAYER_NAME" $POSITION $PRICE $TEAM_ID \
          --private-key $PRIVATE_KEY \
          --rpc-url $RPC_URL
        echo "✅ Player added!"
        ;;
        
    "get-player")
        PLAYER_ID=${2:-1}
        
        echo "👤 Getting player info for ID $PLAYER_ID..."
        cast call $TEAM_MANAGER_ADDRESS \
          "getPlayer(uint256)" \
          $PLAYER_ID \
          --rpc-url $RPC_URL
        ;;
        
    "check-payout")
        MATCHWEEK=${2:-1}
        
        echo "💰 Checking payout status for matchweek $MATCHWEEK..."
        echo "Processed:" 
        cast call $PAYOUT_DISTRIBUTOR_ADDRESS \
          "isPayoutProcessed(uint256)" \
          $MATCHWEEK \
          --rpc-url $RPC_URL
        
        echo "Winners:"
        cast call $PAYOUT_DISTRIBUTOR_ADDRESS \
          "getWinners(uint256)" \
          $MATCHWEEK \
          --rpc-url $RPC_URL
        ;;
        
    "contract-info")
        echo "📋 OnChain FPL Contract Addresses:"
        echo "=================================="
        echo "TeamManager:      $TEAM_MANAGER_ADDRESS"
        echo "PoolManager:      $POOL_MANAGER_ADDRESS"
        echo "ScoringEngine:    $SCORING_ENGINE_ADDRESS"
        echo "OracleConsumer:   $ORACLE_CONSUMER_ADDRESS"
        echo "PayoutDistributor: $PAYOUT_DISTRIBUTOR_ADDRESS"
        echo ""
        echo "🔍 View on BaseScan:"
        echo "https://sepolia.basescan.org/address/$POOL_MANAGER_ADDRESS"
        ;;
        
    *)
        echo "🎮 OnChain FPL Contract Interaction Script"
        echo "=========================================="
        echo ""
        echo "Usage: $0 [command] [args...]"
        echo ""
        echo "📋 Available Commands:"
        echo ""
        echo "Pool Management:"
        echo "  create-pool [matchweek] [deadline]     Create a new pool"
        echo "  join-pool [matchweek]                  Join a pool (0.00015 ETH)"
        echo "  get-pool [matchweek]                   Get pool information"
        echo "  get-participants [matchweek]           Get pool participants"
        echo ""
        echo "Player Management:"
        echo "  add-player [id] [name] [pos] [price] [team]  Add a player"
        echo "  get-player [id]                        Get player information"
        echo ""
        echo "System Info:"
        echo "  check-balance [address]                Get ETH balance"
        echo "  check-payout [matchweek]               Check payout status"
        echo "  contract-info                          Show contract addresses"
        echo ""
        echo "📝 Examples:"
        echo "  $0 create-pool 1"
        echo "  $0 join-pool 1"
        echo "  $0 add-player 1 \"Erling Haaland\" 3 11500000 1"
        echo "  $0 contract-info"
        ;;
esac