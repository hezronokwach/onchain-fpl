# 🛠️ OnChain FPL Scripts Explained

## 📁 **Script Organization**

All deployment and interaction scripts are now in `contracts/script/`:

```
contracts/script/
├── deploy-all.sh           # Deploy all contracts
├── interact.sh             # Interact with deployed contracts
├── DeployAll.s.sol         # Foundry deployment script
└── [Other Foundry scripts] # Individual contract deployments
```

## 🚀 **Deployment Scripts**

### **deploy-all.sh**
**Purpose**: Deploy all OnChain FPL contracts to Base Sepolia

**Usage**:
```bash
cd contracts
./script/deploy-all.sh
```

**What it does**:
1. Checks for `.env` file and `PRIVATE_KEY`
2. Compiles all contracts with `forge build`
3. Runs `DeployAll.s.sol` Foundry script
4. Deploys all 5 contracts in correct order
5. Configures contract connections
6. Shows contract addresses for your `.env` file

**When to use**: First time deployment or redeployment

### **DeployAll.s.sol**
**Purpose**: Foundry script that handles the actual deployment logic

**What it does**:
```solidity
1. Deploy TeamManager
2. Deploy PoolManager  
3. Deploy ScoringEngine (with TeamManager address)
4. Deploy OracleConsumer (with ScoringEngine address)
5. Deploy PayoutDistributor (with PoolManager + ScoringEngine)
6. Configure: scoringEngine.setOracleConsumer(oracleConsumer)
```

**Deployment order matters** because contracts depend on each other!

## 🎮 **Interaction Scripts**

### **interact.sh**
**Purpose**: Interact with your deployed contracts without writing code

**Usage**:
```bash
cd contracts
./script/interact.sh [command] [args...]
```

### **Available Commands**:

#### **Pool Management**
```bash
# Create a pool for matchweek 1
./script/interact.sh create-pool 1

# Join a pool (costs 0.00015 ETH)
./script/interact.sh join-pool 1

# Get pool information
./script/interact.sh get-pool 1

# See who joined the pool
./script/interact.sh get-participants 1
```

#### **Player Management**
```bash
# Add Erling Haaland (ID: 1, Forward, £11.5M, Man City)
./script/interact.sh add-player 1 "Erling Haaland" 3 11500000 1

# Get player information
./script/interact.sh get-player 1
```

#### **System Info**
```bash
# Check your ETH balance
./script/interact.sh check-balance

# Check payout status for matchweek
./script/interact.sh check-payout 1

# Show all contract addresses
./script/interact.sh contract-info
```

## 🔧 **How Scripts Work**

### **Environment Variables**
Scripts read from `contracts/.env`:
```bash
PRIVATE_KEY=0x...                    # Your wallet private key
BASE_SEPOLIA_RPC_URL=https://...     # Base network endpoint
TEAM_MANAGER_ADDRESS=0x...           # Deployed contract addresses
POOL_MANAGER_ADDRESS=0x...
# ... etc
```

### **Cast Commands**
Scripts use Foundry's `cast` tool to interact with contracts:

```bash
# Send transaction (costs gas)
cast send $CONTRACT_ADDRESS "functionName(uint256)" 123 --private-key $PRIVATE_KEY

# Read data (free)
cast call $CONTRACT_ADDRESS "functionName(uint256)" 123 --rpc-url $RPC_URL
```

### **Transaction Flow**
```
Your Script → Cast Command → Base Sepolia → Contract Execution → Result
```

## 📊 **What Each Script Does**

### **deploy-all.sh**
```
1. Load .env variables
2. Compile Solidity → Bytecode
3. Create deployment transactions
4. Sign with your private key
5. Send to Base Sepolia
6. Wait for confirmations
7. Return contract addresses
```

### **interact.sh**
```
1. Load contract addresses from .env
2. Create function call transaction
3. Sign with your private key
4. Send to Base Sepolia
5. Execute contract function
6. Return result
```

## 🎯 **Real Examples**

### **Create and Join a Pool**
```bash
# 1. Create pool for matchweek 1 (owner only)
./script/interact.sh create-pool 1

# 2. Join the pool (any user)
./script/interact.sh join-pool 1

# 3. Check who joined
./script/interact.sh get-participants 1
```

### **Add Players and Check Data**
```bash
# Add some players
./script/interact.sh add-player 1 "Erling Haaland" 3 11500000 1
./script/interact.sh add-player 2 "Mohamed Salah" 3 13000000 2

# Check player data
./script/interact.sh get-player 1
./script/interact.sh get-player 2
```

## 🔍 **Debugging Scripts**

### **Common Issues**
1. **"Contract not found"** → Check contract addresses in `.env`
2. **"Insufficient funds"** → Get more test ETH from faucet
3. **"Transaction reverted"** → Check function parameters
4. **"Private key error"** → Ensure `PRIVATE_KEY` has `0x` prefix

### **Verbose Output**
Add `-vvvv` to see detailed transaction info:
```bash
cast send $CONTRACT "function()" --private-key $KEY -vvvv
```

## 🎉 **Summary**

### **deploy-all.sh**: 
- **One-time use** to deploy all contracts
- **Creates** your OnChain FPL system on blockchain
- **Costs** ~$0.03 in gas fees

### **interact.sh**: 
- **Daily use** to manage your system
- **Calls** contract functions
- **Tests** functionality before frontend integration

These scripts let you fully manage your OnChain FPL system from the command line!