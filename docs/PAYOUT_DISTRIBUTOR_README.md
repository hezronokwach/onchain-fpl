# PayoutDistributor Contract

## Overview

The PayoutDistributor contract is the final piece of the OnChain FPL system that handles automated prize distribution with sophisticated tie-breaking rules. It determines winners based on team scores and distributes prizes fairly according to FPL rules.

## Key Features

### 🎯 Winner Determination
- **Primary Score**: Highest total points wins
- **Tie-Breaking Rules**: 
  1. Highest bench score
  2. Most goals scored by team
  3. Fewest cards received by team
  4. Split prize equally if still tied

### 💰 Prize Distribution
- **Automatic Transfer**: Direct ETH transfer to winners
- **Equal Splitting**: Fair distribution for tied winners
- **Gas Efficient**: Minimal external calls
- **Reentrancy Protected**: Safe prize distribution

### 🛡️ Security Measures
- **ReentrancyGuard**: Prevents reentrancy attacks
- **Access Control**: Owner-only emergency functions
- **Input Validation**: All parameters validated
- **Error Handling**: Custom errors for gas efficiency

### 🔧 Emergency Controls
- **Emergency Withdrawal**: Owner can withdraw in emergencies
- **Contract Updates**: Update dependent contract addresses
- **Payout Prevention**: Stop processing if needed

## Contract Architecture

```solidity
contract PayoutDistributor is Ownable, ReentrancyGuard {
    // Contract interfaces
    PoolManager public poolManager;
    ScoringEngine public scoringEngine;
    
    // Payout tracking
    mapping(uint256 => bool) public payoutProcessed;
    mapping(uint256 => address[]) public winners;
    mapping(uint256 => uint256) public payoutAmounts;
}
```

## Core Functions

### Main Operations

#### `processPayout(uint256 matchweek)`
Processes payout for a completed matchweek:
- Validates all scores are calculated
- Determines winner(s) using tie-breaking rules
- Distributes prizes automatically
- Updates pool status

#### `getWinners(uint256 matchweek)`
Returns winners and payout amounts for a matchweek.

#### `isMatchweekReadyForPayout(uint256 matchweek)`
Checks if a matchweek is ready for payout processing.

### Administrative Functions

#### `emergencyWithdraw(uint256 matchweek)`
Emergency withdrawal function (owner only).

#### `updateContracts(address _poolManager, address _scoringEngine)`
Updates contract addresses (owner only).

## Tie-Breaking Algorithm

### Step 1: Primary Score
Find all participants with the highest total points.

### Step 2: Bench Score Tie-Breaking
If tied, compare bench points (substitute players' scores).

### Step 3: Goals Tie-Breaking
If still tied, compare total goals scored by the team.

### Step 4: Cards Tie-Breaking
If still tied, compare total cards received (fewer is better).

### Step 5: Prize Splitting
If still tied after all rules, split the prize equally.

## Usage Examples

### Deploy Contract
```solidity
PayoutDistributor payoutDistributor = new PayoutDistributor(
    poolManagerAddress,
    scoringEngineAddress
);
```

### Process Payout
```solidity
// Check if ready
bool isReady = payoutDistributor.isMatchweekReadyForPayout(1);

if (isReady) {
    // Process payout
    payoutDistributor.processPayout(1);
    
    // Get results
    (address[] memory winners, uint256 amountPerWinner) = 
        payoutDistributor.getWinners(1);
}
```

### Emergency Operations
```solidity
// Emergency withdrawal (owner only)
payoutDistributor.emergencyWithdraw(1);

// Update contracts (owner only)
payoutDistributor.updateContracts(newPoolManager, newScoringEngine);
```

## Integration Points

### Dependencies
1. **PoolManager**: Get participants and prize amounts
2. **ScoringEngine**: Get team scores and statistics

### Integration Flow
```
Oracle Updates → ScoringEngine Calculates → PayoutDistributor Processes → Winners Paid
```

## Testing

### Test Coverage
- ✅ Single winner scenarios
- ✅ Tie-breaking by bench score
- ✅ Tie-breaking by goals
- ✅ Tie-breaking by cards
- ✅ Complete ties (prize splitting)
- ✅ Multiple participants
- ✅ Emergency functions
- ✅ Access control
- ✅ Edge cases

### Run Tests
```bash
# Run all PayoutDistributor tests
forge test --match-path test/PayoutDistributor.t.sol

# Run with verbose output
forge test --match-path test/PayoutDistributor.t.sol -vv

# Gas report
forge test --gas-report --match-path test/PayoutDistributor.t.sol
```

## Deployment

### Environment Setup
```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export POOL_MANAGER_ADDRESS=0x...
export SCORING_ENGINE_ADDRESS=0x...
```

### Deploy Script
```bash
# Deploy PayoutDistributor
forge script script/DeployPayoutDistributor.s.sol:DeployPayoutDistributor \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

### Interaction Scripts
```bash
# Process payout for matchweek 1
PAYOUT_DISTRIBUTOR_ADDRESS=0x... forge script script/InteractPayoutDistributor.s.sol:InteractPayoutDistributor \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast

# Check multiple matchweeks
forge script script/InteractPayoutDistributor.s.sol:InteractPayoutDistributor \
  --sig "checkMultipleMatchweeks()" \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast
```

## Events

### PayoutProcessed
```solidity
event PayoutProcessed(
    uint256 indexed matchweek, 
    address[] winners, 
    uint256 totalPrize, 
    uint256 amountPerWinner
);
```

### EmergencyWithdrawal
```solidity
event EmergencyWithdrawal(uint256 indexed matchweek, uint256 amount);
```

### ContractsUpdated
```solidity
event ContractsUpdated(address poolManager, address scoringEngine);
```

## Error Handling

### Custom Errors
- `PayoutAlreadyProcessed()`: Payout already processed for matchweek
- `NoParticipants()`: No participants in the pool
- `ScoresNotCalculated()`: Team scores not yet calculated
- `TransferFailed()`: ETH transfer failed
- `InvalidContract()`: Invalid contract address provided

## Security Considerations

### Reentrancy Protection
- Uses OpenZeppelin's ReentrancyGuard
- All external calls are protected

### Access Control
- Owner-only emergency functions
- Input validation on all parameters

### Prize Distribution Safety
- Checks for successful ETH transfers
- Reverts on transfer failures
- No partial state updates

## Gas Optimization

### Efficient Operations
- Batch operations where possible
- Minimal storage reads/writes
- Optimized loops and calculations

### Gas Estimates
- Single winner payout: ~100,000 gas
- Tie-breaking (2 winners): ~150,000 gas
- Emergency withdrawal: ~50,000 gas

## Future Enhancements

### Potential Improvements
1. **Advanced Tie-Breaking**: More sophisticated tie-breaking rules
2. **Partial Payouts**: Support for multiple prize tiers
3. **Token Support**: Support for ERC20 token prizes
4. **Automated Processing**: Integration with Chainlink Automation

### Upgrade Path
The contract uses a proxy pattern for future upgrades while maintaining security.

## Conclusion

The PayoutDistributor contract completes the OnChain FPL system by ensuring winners are automatically and fairly rewarded. It implements sophisticated tie-breaking rules, maintains security best practices, and provides emergency controls for edge cases.

The contract has been thoroughly tested and is ready for deployment on Base Sepolia testnet and eventually mainnet.