# Foundry Development Guide for OnChain FPL

## Overview

This guide covers Foundry setup, usage, and interaction patterns specifically for OnChain FPL development on Base Sepolia and Base Mainnet.

## Installation & Setup

### Install Foundry
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Verify installation
forge --version
cast --version
anvil --version
```

### Project Structure
```
contracts/
├── src/                    # Smart contracts
│   ├── PoolManager.sol
│   ├── TeamManager.sol
│   ├── ScoringEngine.sol
│   └── libraries/
├── test/                   # Test files
├── script/                 # Deployment scripts
├── lib/                    # Dependencies
├── foundry.toml           # Configuration
└── .env                   # Environment variables
```

## Configuration

### foundry.toml
```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc_version = "0.8.19"
optimizer = true
optimizer_runs = 200
via_ir = true

[rpc_endpoints]
base_sepolia = "https://sepolia.base.org"
base_mainnet = "https://mainnet.base.org"

[etherscan]
base_sepolia = { key = "${BASESCAN_API_KEY}", url = "https://api-sepolia.basescan.org/api" }
base_mainnet = { key = "${BASESCAN_API_KEY}", url = "https://api.basescan.org/api" }
```

### Environment Variables (.env)
```bash
# Network Configuration
BASE_SEPOLIA_RPC_URL="https://sepolia.base.org"
BASE_MAINNET_RPC_URL="https://mainnet.base.org"

# Private Keys (NEVER COMMIT REAL KEYS)
PRIVATE_KEY="0x..."
DEPLOYER_PRIVATE_KEY="0x..."

# API Keys
BASESCAN_API_KEY="your_basescan_api_key"

# Contract Addresses (filled after deployment)
POOL_MANAGER_ADDRESS=""
TEAM_MANAGER_ADDRESS=""
SCORING_ENGINE_ADDRESS=""
```

## Core Foundry Commands

### Compilation
```bash
# Compile all contracts
forge build

# Compile with specific Solidity version
forge build --use 0.8.19

# Clean and rebuild
forge clean && forge build
```

### Testing
```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/PoolManager.t.sol

# Run specific test function
forge test --match-test testCreatePool

# Run tests with gas reporting
forge test --gas-report

# Run tests with verbosity (see console.log)
forge test -vvv

# Run tests with coverage
forge coverage
```

### Deployment

#### Deploy to Base Sepolia
```bash
# Deploy single contract
forge create src/PoolManager.sol:PoolManager \
  --rpc-url base_sepolia \
  --private-key $PRIVATE_KEY \
  --constructor-args 50000000000000000 \
  --verify

# Deploy using script
forge script script/Deploy.s.sol \
  --rpc-url base_sepolia \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

#### Deploy to Base Mainnet
```bash
# Deploy to mainnet (use with caution)
forge script script/Deploy.s.sol \
  --rpc-url base_mainnet \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --slow
```

### Contract Verification
```bash
# Verify contract on Basescan
forge verify-contract \
  0x1234567890123456789012345678901234567890 \
  src/PoolManager.sol:PoolManager \
  --chain base-sepolia \
  --constructor-args $(cast abi-encode "constructor(uint256)" 50000000000000000)

# Verify with libraries
forge verify-contract \
  0x1234567890123456789012345678901234567890 \
  src/PoolManager.sol:PoolManager \
  --chain base-sepolia \
  --libraries src/libraries/DataStructures.sol:DataStructures:0xLibraryAddress
```

## Contract Interaction with Cast

### Reading Contract Data
```bash
# Get pool information
cast call $POOL_MANAGER_ADDRESS \
  "getPool(uint256)(uint256,uint256,uint256,uint256,address[],bool,bool)" \
  1 \
  --rpc-url base_sepolia

# Get team information
cast call $TEAM_MANAGER_ADDRESS \
  "getTeam(uint256,address)" \
  1 0x742d35Cc6634C0532925a3b8D4C9db96590c6C87 \
  --rpc-url base_sepolia

# Check if user has entered pool
cast call $POOL_MANAGER_ADDRESS \
  "hasUserEntered(uint256,address)(bool)" \
  1 0x742d35Cc6634C0532925a3b8D4C9db96590c6C87 \
  --rpc-url base_sepolia
```

### Writing to Contracts
```bash
# Create a new pool (owner only)
cast send $POOL_MANAGER_ADDRESS \
  "createPool(uint256,uint256)" \
  1 1640995200 \
  --private-key $PRIVATE_KEY \
  --rpc-url base_sepolia

# Join a pool
cast send $POOL_MANAGER_ADDRESS \
  "joinPool(uint256)" \
  1 \
  --value 50000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url base_sepolia

# Submit team
cast send $TEAM_MANAGER_ADDRESS \
  "submitTeam(uint256,(uint256[15],uint256[11],uint256,uint256,uint8,uint256,bool,uint256))" \
  1 \
  "[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]" \
  "[0,1,2,3,4,5,6,7,8,9,10]" \
  0 1 0 100000000 true $(date +%s) \
  --private-key $PRIVATE_KEY \
  --rpc-url base_sepolia
```

### Utility Commands
```bash
# Convert ETH to Wei
cast --to-wei 0.05 ether
# Output: 50000000000000000

# Convert Wei to ETH
cast --from-wei 50000000000000000
# Output: 0.050000000000000000

# Get current block number
cast block-number --rpc-url base_sepolia

# Get transaction receipt
cast receipt 0x1234... --rpc-url base_sepolia

# Estimate gas for transaction
cast estimate $CONTRACT_ADDRESS "functionName()" --rpc-url base_sepolia
```

## Deployment Scripts

### Basic Deployment Script
```solidity
// script/Deploy.s.sol
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/PoolManager.sol";
import "../src/TeamManager.sol";
import "../src/ScoringEngine.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy contracts
        PoolManager poolManager = new PoolManager(0.05 ether);
        TeamManager teamManager = new TeamManager();
        ScoringEngine scoringEngine = new ScoringEngine();

        // Set up contract relationships
        poolManager.setTeamManager(address(teamManager));
        poolManager.setScoringEngine(address(scoringEngine));

        console.log("PoolManager deployed to:", address(poolManager));
        console.log("TeamManager deployed to:", address(teamManager));
        console.log("ScoringEngine deployed to:", address(scoringEngine));

        vm.stopBroadcast();
    }
}
```

### Run Deployment Script
```bash
# Deploy to Base Sepolia
forge script script/Deploy.s.sol \
  --rpc-url base_sepolia \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  -vvvv
```

## Testing Patterns

### Basic Test Structure
```solidity
// test/PoolManager.t.sol
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/PoolManager.sol";

contract PoolManagerTest is Test {
    PoolManager public poolManager;
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    function setUp() public {
        vm.prank(owner);
        poolManager = new PoolManager(0.05 ether);
    }

    function testCreatePool() public {
        vm.prank(owner);
        poolManager.createPool(1, block.timestamp + 3600);
        
        (uint256 matchweek, uint256 entryFee, uint256 deadline,,,,,) = 
            poolManager.getPool(1);
        
        assertEq(matchweek, 1);
        assertEq(entryFee, 0.05 ether);
        assertEq(deadline, block.timestamp + 3600);
    }

    function testJoinPool() public {
        // Setup
        vm.prank(owner);
        poolManager.createPool(1, block.timestamp + 3600);
        
        // Test
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        poolManager.joinPool{value: 0.05 ether}(1);
        
        // Assert
        assertTrue(poolManager.hasUserEntered(1, user1));
    }
}
```

### Advanced Testing Techniques
```solidity
// Test with time manipulation
function testDeadlineEnforcement() public {
    vm.prank(owner);
    poolManager.createPool(1, block.timestamp + 3600);
    
    // Fast forward past deadline
    vm.warp(block.timestamp + 3601);
    
    vm.deal(user1, 1 ether);
    vm.prank(user1);
    vm.expectRevert("Pool deadline has passed");
    poolManager.joinPool{value: 0.05 ether}(1);
}

// Test with events
function testPoolCreationEvent() public {
    vm.expectEmit(true, true, false, true);
    emit PoolCreated(1, 0.05 ether, block.timestamp + 3600);
    
    vm.prank(owner);
    poolManager.createPool(1, block.timestamp + 3600);
}

// Fuzz testing
function testJoinPoolFuzz(uint256 matchweek, uint256 deadline) public {
    vm.assume(matchweek > 0 && matchweek <= 38);
    vm.assume(deadline > block.timestamp);
    
    vm.prank(owner);
    poolManager.createPool(matchweek, deadline);
    
    vm.deal(user1, 1 ether);
    vm.prank(user1);
    poolManager.joinPool{value: 0.05 ether}(matchweek);
    
    assertTrue(poolManager.hasUserEntered(matchweek, user1));
}
```

## Debugging & Troubleshooting

### Common Issues

#### 1. Compilation Errors
```bash
# Check Solidity version compatibility
forge build --use 0.8.19

# Clear cache and rebuild
forge clean && forge build

# Check for missing dependencies
forge install
```

#### 2. Deployment Issues
```bash
# Check gas estimation
cast estimate $CONTRACT_ADDRESS "functionName()" --rpc-url base_sepolia

# Check account balance
cast balance $YOUR_ADDRESS --rpc-url base_sepolia

# Increase gas limit
forge create ... --gas-limit 3000000
```

#### 3. Test Failures
```bash
# Run with maximum verbosity
forge test -vvvv

# Run specific failing test
forge test --match-test testFailingFunction -vvvv

# Check test coverage
forge coverage --report lcov
```

### Debugging with Console Logs
```solidity
import "forge-std/console.sol";

function debugFunction() public {
    console.log("Debug: value is", someValue);
    console.log("Debug: address is", someAddress);
    console.logBytes32(someBytes32);
}
```

## Gas Optimization Tips

### 1. Use Packed Structs
```solidity
// Bad - uses multiple storage slots
struct Player {
    uint256 id;
    bool isActive;
    uint256 price;
}

// Good - packed into fewer slots
struct Player {
    uint256 id;
    uint256 price;
    bool isActive;  // Packed with price
}
```

### 2. Use Events for Data Storage
```solidity
// Store frequently accessed data in events
event TeamSubmitted(
    address indexed user,
    uint256 indexed matchweek,
    uint256[15] playerIds
);
```

### 3. Batch Operations
```solidity
// Batch multiple operations
function batchSubmitTeams(
    uint256[] calldata matchweeks,
    Team[] calldata teams
) external {
    for (uint i = 0; i < matchweeks.length; i++) {
        _submitTeam(matchweeks[i], teams[i]);
    }
}
```

## Security Best Practices

### 1. Access Control
```solidity
import "@openzeppelin/contracts/access/Ownable.sol";

contract PoolManager is Ownable {
    modifier onlyBeforeDeadline(uint256 matchweek) {
        require(block.timestamp < pools[matchweek].deadline, "Deadline passed");
        _;
    }
}
```

### 2. Reentrancy Protection
```solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PoolManager is ReentrancyGuard {
    function joinPool(uint256 matchweek) external payable nonReentrant {
        // Safe from reentrancy attacks
    }
}
```

### 3. Input Validation
```solidity
function createPool(uint256 matchweek, uint256 deadline) external onlyOwner {
    require(matchweek > 0 && matchweek <= 38, "Invalid matchweek");
    require(deadline > block.timestamp, "Invalid deadline");
    require(!pools[matchweek].isActive, "Pool already exists");
    
    // Create pool logic
}
```

## Useful Scripts

### Deploy Script
```bash
#!/bin/bash
# scripts/deploy.sh

set -e

echo "Deploying OnChain FPL contracts to Base Sepolia..."

forge script script/Deploy.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  -vvvv

echo "Deployment complete!"
```

### Interaction Script
```bash
#!/bin/bash
# scripts/interact.sh

POOL_MANAGER="0x..."
MATCHWEEK=1
DEADLINE=$(($(date +%s) + 3600))

echo "Creating pool for matchweek $MATCHWEEK..."

cast send $POOL_MANAGER \
  "createPool(uint256,uint256)" \
  $MATCHWEEK $DEADLINE \
  --private-key $PRIVATE_KEY \
  --rpc-url $BASE_SEPOLIA_RPC_URL

echo "Pool created successfully!"
```

## Resources

### Documentation
- [Foundry Book](https://book.getfoundry.sh/)
- [Forge Commands](https://book.getfoundry.sh/reference/forge/)
- [Cast Commands](https://book.getfoundry.sh/reference/cast/)

### Base Network
- [Base Docs](https://docs.base.org/)
- [Base Sepolia Explorer](https://sepolia.basescan.org/)
- [Base Sepolia Faucet](https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet)

### Testing
- [Foundry Testing](https://book.getfoundry.sh/forge/tests)
- [Forge Standard Library](https://github.com/foundry-rs/forge-std)

This guide provides everything needed to develop, test, and deploy OnChain FPL smart contracts using Foundry on Base network.