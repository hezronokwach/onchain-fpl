# OnChain FPL Smart Contracts

## Overview

This directory contains the smart contracts for the OnChain Fantasy Premier League (FPL) system built on Base network.

## Contracts

- **TeamManager**: Manages player data and team validation
- **PoolManager**: Handles pool creation and entry management
- **ScoringEngine**: Implements FPL scoring system with auto-substitution
- **OracleConsumer**: Integrates with Chainlink oracles for EPL data
- **PayoutDistributor**: Automated prize distribution with tie-breaking

## Deployed Contracts (Base Sepolia)

```
TeamManager:      0x2FE4D90a1C855299D91d52D8304D7459365e5937
PoolManager:      0x6b6461308df2d2B5D53448Ba641d171ccEf4a6f8
ScoringEngine:    0x766A085a8DC91D7b4A1502235852e1E32ea90B7c
OracleConsumer:   0x0bf9F843DF94D7C0c21674C236C82515367Fb969
PayoutDistributor: 0xb8542407f75543aE1d77b5De32Dd0A91B1826734
```

## Quick Start

### Build
```shell
forge build
```

### Test
```shell
forge test
```

### Deploy All Contracts
```shell
./script/deploy-all.sh
```

### Interact with Contracts
```shell
# Show contract addresses
./script/interact.sh contract-info

# Create a pool
./script/interact.sh create-pool 1

# Join a pool
./script/interact.sh join-pool 1
```

## Development

### Environment Setup
1. Copy `.env.example` to `.env`
2. Add your `PRIVATE_KEY` and `BASESCAN_API_KEY`
3. Ensure you have test ETH from Base Sepolia faucet

### Testing
```shell
# Run all tests
forge test

# Run specific test file
forge test --match-path test/PoolManager.t.sol

# Run with gas report
forge test --gas-report
```

### Deployment
```shell
# Deploy to Base Sepolia
./script/deploy-all.sh

# Deploy individual contract
forge script script/DeployPoolManager.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
```

## Architecture

The contracts work together as a complete FPL system:

```
Users → PoolManager (join pools) → TeamManager (submit teams) → ScoringEngine (calculate points) → PayoutDistributor (pay winners)
                                                                        ↑
                                                                OracleConsumer (EPL data)
```

## Documentation

- [Foundry Book](https://book.getfoundry.sh/)
- [Base Documentation](https://docs.base.org/)
- [Project Documentation](../docs/)

## Security

- All contracts use OpenZeppelin security patterns
- Comprehensive test coverage (83 tests)
- Owner-only administrative functions
- Reentrancy protection on critical functions