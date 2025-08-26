# Manual GitHub Issues Creation

Since the automated script is having API issues, here are the issues to create manually on GitHub:

## How to Create Issues Manually

1. Go to: https://github.com/hezronokwach/onchain-fpl/issues
2. Click "New Issue"
3. Copy and paste the title and description below
4. Add labels if desired
5. Click "Submit new issue"

---

## Issue 1: 📚 Create Foundry Documentation and Interaction Guide

**Labels:** `documentation`, `foundry`, `setup`

**Description:**
```
## Description
Create comprehensive documentation for Foundry setup, usage, and interaction patterns for OnChain FPL development.

## Tasks
- [ ] Create FOUNDRY_GUIDE.md with setup instructions
- [ ] Document all forge commands and usage
- [ ] Create deployment scripts and examples
- [ ] Document testing patterns and best practices
- [ ] Add contract interaction examples with cast

## Status
✅ **COMPLETED** - Documentation already created in docs/FOUNDRY_GUIDE.md

## Files Created
- docs/FOUNDRY_GUIDE.md
- scripts/deploy.sh
- scripts/interact.sh
```

---

## Issue 2: 📊 Implement Core Data Structures

**Labels:** `smart-contracts`, `data-structures`, `phase-1`

**Description:**
```
## Description
Create the fundamental data structures for players, teams, pools, and scoring.

## Tasks
- [ ] Create libraries directory structure
- [ ] Define Player struct (id, name, position, price, teamId)
- [ ] Define Team struct (owner, playerIds, formation, captain)
- [ ] Define Pool struct (matchweek, entryFee, deadline, participants)
- [ ] Define Performance struct (goals, assists, minutes, cards)
- [ ] Create enums for Position and Formation
- [ ] Add comprehensive NatSpec documentation

## Files to Create
- src/libraries/DataStructures.sol
- src/libraries/Enums.sol

## Acceptance Criteria
- [ ] All structs properly defined with correct data types
- [ ] Enums cover all valid positions and formations
- [ ] Structs are gas-optimized (packed efficiently)
- [ ] Full NatSpec documentation
```

---

## Issue 3: 🏊 Implement Pool Management Contract

**Labels:** `smart-contracts`, `pool-management`, `phase-1`

**Description:**
```
## Description
Create the PoolManager contract to handle matchweek pool creation, entry, and lifecycle management.

## Tasks
- [ ] Create PoolManager.sol contract
- [ ] Implement createPool function (owner only)
- [ ] Implement joinPool function with payment validation
- [ ] Add deadline enforcement mechanisms
- [ ] Implement participant tracking
- [ ] Add pool status management (active, finalized)
- [ ] Write comprehensive unit tests

## Smart Contract Functions
```solidity
function createPool(uint256 matchweek, uint256 deadline) external onlyOwner;
function joinPool(uint256 matchweek) external payable;
function getPool(uint256 matchweek) external view returns (Pool memory);
function getParticipants(uint256 matchweek) external view returns (address[] memory);
```

## Acceptance Criteria
- [ ] Pools can be created with proper validation
- [ ] Users can join pools by paying correct entry fee
- [ ] Deadline enforcement prevents late entries
- [ ] Proper event emission for all actions
- [ ] 100% test coverage
```

---

## Issue 4: ⚽ Implement Team Management Contract

**Labels:** `smart-contracts`, `team-management`, `phase-1`

**Description:**
```
## Description
Create the TeamManager contract for team selection, validation, and storage.

## Tasks
- [ ] Create TeamManager.sol contract
- [ ] Implement team submission with validation
- [ ] Add FPL constraint validation (budget, formation, team limits)
- [ ] Implement captain/vice-captain selection
- [ ] Add team modification before deadline
- [ ] Write validation helper functions
- [ ] Create comprehensive test suite

## Validation Rules
- Budget: ≤ £100M total cost
- Formation: Valid FPL formations (3-4-3, 4-3-3, etc.)
- Team limits: Max 3 players from same EPL team
- Squad: Exactly 15 players (2 GK, 5 DEF, 5 MID, 3 FWD)
- Starting XI: Exactly 11 players in valid formation

## Acceptance Criteria
- [ ] Teams validated against all FPL rules
- [ ] Budget constraint enforced (£100M max)
- [ ] Formation validation (valid FPL formations)
- [ ] Max 3 players per EPL team enforced
- [ ] Captain/vice-captain properly designated
- [ ] Teams can be modified before deadline
```

---

## Issue 5: 🎯 Implement FPL Scoring Engine

**Labels:** `smart-contracts`, `scoring-engine`, `phase-1`

**Description:**
```
## Description
Create the ScoringEngine contract that implements the official FPL scoring system.

## Tasks
- [ ] Create ScoringEngine.sol contract
- [ ] Implement point calculation for all player actions
- [ ] Add position-based scoring (goals, assists, clean sheets)
- [ ] Implement captain/vice-captain multipliers
- [ ] Add bonus point system integration
- [ ] Create auto-substitution logic
- [ ] Write extensive test cases for all scoring scenarios

## Scoring Rules Implementation
- Goals: GK/DEF: 6pts, MID: 5pts, FWD: 4pts
- Assists: 3pts all positions
- Clean sheets: GK/DEF: 4pts, MID: 1pt
- Playing time: >60min: 2pts, <60min: 1pt
- Cards: Yellow: -1pt, Red: -3pts
- Own goals: -2pts, Penalty miss: -2pts

## Acceptance Criteria
- [ ] Accurate FPL point calculation for all scenarios
- [ ] Captain receives double points
- [ ] Vice-captain activated if captain doesn't play
- [ ] Auto-substitution maintains valid formation
- [ ] Handles edge cases (red cards, own goals, etc.)
```

---

## Issue 6: 🔗 Integrate Chainlink Oracle for EPL Data

**Labels:** `smart-contracts`, `oracle-integration`, `phase-1`

**Description:**
```
## Description
Integrate Chainlink oracles to fetch real-world EPL player performance data.

## Tasks
- [ ] Create OracleConsumer.sol contract
- [ ] Set up Chainlink Functions for EPL data
- [ ] Implement data validation and error handling
- [ ] Create mock oracle for testing
- [ ] Add automated scoring triggers
- [ ] Test oracle integration on Base Sepolia

## Oracle Data Structure
```solidity
struct MatchData {
    uint256 matchweek;
    PlayerPerformance[] performances;
    uint256 timestamp;
    bool isValidated;
}
```

## Acceptance Criteria
- [ ] Oracle successfully fetches EPL match data
- [ ] Data validation prevents invalid submissions
- [ ] Fallback mechanisms for oracle failures
- [ ] Automated scoring after matchweek completion
- [ ] Comprehensive error handling
```

---

## Issue 7: 💰 Implement Automated Payout System

**Labels:** `smart-contracts`, `payout-system`, `phase-1`

**Description:**
```
## Description
Create the PayoutDistributor contract for automated prize distribution to winners.

## Tasks
- [ ] Create PayoutDistributor.sol contract
- [ ] Implement winner determination algorithm
- [ ] Add automated payout distribution
- [ ] Handle tie-breaking scenarios
- [ ] Implement emergency withdrawal functions
- [ ] Add comprehensive security measures

## Tie-Breaking Rules
1. Highest bench score (non-playing players)
2. Most goals scored by team
3. Fewest cards received by team
4. If still tied, split prize pool equally

## Acceptance Criteria
- [ ] Correctly identifies highest scoring team
- [ ] Automatically distributes full prize pool to winner
- [ ] Handles ties with proper tie-breaking rules
- [ ] Emergency functions for edge cases
- [ ] Secure against reentrancy and other attacks
```

---

## Issue 8: 🎨 Setup Next.js Frontend Foundation

**Labels:** `frontend`, `setup`, `phase-2`

**Description:**
```
## Description
Set up the Next.js frontend application with all necessary dependencies and configuration.

## Tasks
- [ ] Create Next.js 14 project with TypeScript
- [ ] Install and configure Tailwind CSS
- [ ] Set up wagmi and viem for Web3 integration
- [ ] Configure Base network connection
- [ ] Set up project structure and routing
- [ ] Create basic layout and navigation

## Dependencies
- Next.js 14, React 18, TypeScript
- wagmi v2, viem, @coinbase/onchainkit
- Tailwind CSS, Headless UI
- React Hook Form, Zod validation

## Acceptance Criteria
- [ ] Next.js app runs successfully
- [ ] Tailwind CSS properly configured
- [ ] Web3 connection to Base network works
- [ ] Responsive layout structure in place
- [ ] TypeScript properly configured
```

---

## Quick Start

**Instead of the script, just create the first 3 issues manually:**

1. **Issue #1**: ✅ Already completed (Foundry docs)
2. **Issue #2**: 📊 Implement Core Data Structures ← **START HERE**
3. **Issue #3**: 🏊 Implement Pool Management Contract

This will get you started with the core smart contract development!