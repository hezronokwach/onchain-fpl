# OnChain FPL Development Work Plan

## Project Overview

**OnChain FPL** is a blockchain-based Fantasy Premier League miniapp built on Base Layer 2, targeting Kenyan users. Players join weekly pools for each EPL matchweek by paying 50 KSh (~0.00015 ETH), select FPL-style teams, and compete for the entire prize pool based on real-world player performance.

### Key Features
- **Weekly Pools**: One pool per EPL matchweek (1-38 per season)
- **FPL Team Selection**: 15 players, 11 starting, following official FPL rules
- **Entry Fee**: Fixed 50 KSh per matchweek via M-Pesa integration
- **Winner-Takes-All**: Highest scoring team wins entire pool
- **Real-Time Scoring**: Chainlink oracles fetch EPL performance data
- **Kenyan Focus**: M-Pesa to ETH conversion for seamless payments

## Technical Architecture

### Core Stack
- **Blockchain**: Base Mainnet (L2 Ethereum)
- **Smart Contracts**: Solidity ^0.8.19 with Foundry
- **Frontend**: Next.js 14 + React 18 + Tailwind CSS
- **Web3**: wagmi v2 + viem for Ethereum interactions
- **Oracles**: Chainlink for EPL data feeds
- **Payments**: Ramp Network for KSh-to-ETH conversion

### Smart Contract Components
1. **PoolManager**: Creates and manages matchweek pools
2. **TeamManager**: Handles team selection and validation
3. **ScoringEngine**: Implements FPL scoring system
4. **PayoutDistributor**: Manages prize distribution
5. **OracleConsumer**: Integrates Chainlink data feeds

## Development Phases

### Phase 1: Smart Contract Foundation (Days 1-4)

#### Day 1: Environment Setup & Core Contracts
**Morning (4 hours)**
- [ ] Set up Foundry development environment
- [ ] Configure Base Sepolia testnet
- [ ] Create project structure with proper folder organization
- [ ] Initialize core contract files (PoolManager, TeamManager)

**Afternoon (4 hours)**
- [ ] Implement basic data structures:
  ```solidity
  struct Player {
      uint256 id;
      string name;
      Position position;
      uint256 price;
      uint256 teamId;
  }
  
  struct Team {
      address owner;
      uint256[15] playerIds;
      uint256[11] startingLineup;
      uint256 captainId;
      uint256 viceCaptainId;
      Formation formation;
  }
  
  struct Pool {
      uint256 matchweek;
      uint256 entryFee;
      uint256 deadline;
      uint256 totalPrize;
      address[] participants;
      bool isActive;
  }
  ```

#### Day 2: Pool Management Logic
**Morning (4 hours)**
- [ ] Implement pool creation and management
- [ ] Entry fee payment processing
- [ ] Participant registration system
- [ ] Deadline enforcement mechanisms

**Afternoon (4 hours)**
- [ ] Team submission validation:
  - Budget constraints (£100M total)
  - Formation rules (GK:1, DEF:3-5, MID:2-5, FWD:1-3)
  - Max 3 players per EPL team
  - Captain/vice-captain selection
- [ ] Write comprehensive unit tests

#### Day 3: FPL Scoring System
**Morning (4 hours)**
- [ ] Implement FPL point calculation:
  ```solidity
  function calculatePoints(uint256 playerId, MatchData memory data) 
      external pure returns (uint256) {
      // Goals: GK/DEF: 6pts, MID: 5pts, FWD: 4pts
      // Assists: 3pts all positions
      // Clean sheets: GK/DEF: 4pts, MID: 1pt
      // Playing time: >60min: 2pts, <60min: 1pt
      // Cards: Yellow: -1pt, Red: -3pts
      // Own goals: -2pts, Penalty miss: -2pts
  }
  ```

**Afternoon (4 hours)**
- [ ] Captain/vice-captain point multipliers
- [ ] Bonus point system integration
- [ ] Auto-substitution logic for non-playing players
- [ ] Edge case handling (ties, invalid formations)

#### Day 4: Oracle Integration & Payouts
**Morning (4 hours)**
- [ ] Chainlink oracle integration for EPL data
- [ ] Mock oracle for testing purposes
- [ ] Data validation and error handling
- [ ] Automated scoring triggers post-matchweek

**Afternoon (4 hours)**
- [ ] Winner determination algorithm
- [ ] Automated payout distribution
- [ ] Emergency functions and circuit breakers
- [ ] Deploy to Base Sepolia testnet

### Phase 2: Frontend Development (Days 5-8)

#### Day 5: Frontend Foundation
**Morning (4 hours)**
- [ ] Create Next.js project with TypeScript
- [ ] Set up Tailwind CSS and component library
- [ ] Configure wagmi and viem for Base network
- [ ] Implement wallet connection component

**Afternoon (4 hours)**
- [ ] Design responsive layout structure
- [ ] Create navigation and routing
- [ ] Implement user authentication flow
- [ ] Set up state management (Zustand/Context)

#### Day 6: Team Selection Interface
**Morning (4 hours)**
- [ ] Player database integration and display
- [ ] Interactive team builder with drag-and-drop
- [ ] Real-time budget tracking
- [ ] Formation selector component

**Afternoon (4 hours)**
- [ ] Player search and filtering
- [ ] Position-based player lists
- [ ] Team validation feedback
- [ ] Captain/vice-captain selection UI

#### Day 7: Pool Management & Payments
**Morning (4 hours)**
- [ ] Matchweek pool display and selection
- [ ] Countdown timer to deadline
- [ ] Participant counter and leaderboard
- [ ] Pool entry confirmation flow

**Afternoon (4 hours)**
- [ ] Ramp Network integration for M-Pesa payments
- [ ] Payment confirmation screens
- [ ] Transaction status tracking
- [ ] Error handling and user feedback

#### Day 8: Dashboard & Analytics
**Morning (4 hours)**
- [ ] User dashboard with team performance
- [ ] Live scoring during matchweeks
- [ ] Historical performance tracking
- [ ] Earnings and withdrawal interface

**Afternoon (4 hours)**
- [ ] Mobile optimization and PWA features
- [ ] Performance optimization
- [ ] Accessibility improvements (WCAG 2.1)
- [ ] Cross-browser testing

### Phase 3: Integration & Testing (Days 9-10)

#### Day 9: Full Integration Testing
**Morning (4 hours)**
- [ ] End-to-end testing on Base Sepolia
- [ ] Oracle integration testing with mock data
- [ ] Payment flow validation
- [ ] User journey optimization

**Afternoon (4 hours)**
- [ ] Security audit and penetration testing
- [ ] Gas optimization and cost analysis
- [ ] Performance benchmarking
- [ ] Bug fixing and refinements

#### Day 10: Production Deployment
**Morning (4 hours)**
- [ ] Final security review and audit
- [ ] Smart contract deployment to Base Mainnet
- [ ] Frontend deployment (Vercel)
- [ ] Domain setup and SSL configuration

**Afternoon (4 hours)**
- [ ] Production testing with small amounts
- [ ] Monitoring and alerting setup
- [ ] Documentation and user guides
- [ ] Launch preparation and marketing materials

## Smart Contract Architecture Details

### Core Contracts

#### 1. PoolManager.sol
```solidity
contract PoolManager {
    struct Pool {
        uint256 matchweek;
        uint256 entryFee;
        uint256 deadline;
        uint256 totalPrize;
        address[] participants;
        mapping(address => bool) hasEntered;
        bool isActive;
        bool isFinalized;
    }
    
    mapping(uint256 => Pool) public pools;
    
    function createPool(uint256 matchweek, uint256 deadline) external onlyOwner;
    function enterPool(uint256 matchweek) external payable;
    function finalizePool(uint256 matchweek) external;
}
```

#### 2. TeamManager.sol
```solidity
contract TeamManager {
    struct Team {
        uint256[15] playerIds;
        uint256[11] startingLineup;
        uint256 captainId;
        uint256 viceCaptainId;
        Formation formation;
        bool isSubmitted;
    }
    
    mapping(uint256 => mapping(address => Team)) public teams; // matchweek => user => team
    
    function submitTeam(uint256 matchweek, Team memory team) external;
    function validateTeam(Team memory team) public view returns (bool);
    function getTeam(uint256 matchweek, address user) external view returns (Team memory);
}
```

#### 3. ScoringEngine.sol
```solidity
contract ScoringEngine {
    struct PlayerPerformance {
        uint256 goals;
        uint256 assists;
        uint256 minutesPlayed;
        bool cleanSheet;
        uint256 saves;
        int256 cards; // -1 for yellow, -3 for red
        bool ownGoal;
        bool penaltyMiss;
        uint256 bonusPoints;
    }
    
    function calculateTeamScore(
        uint256 matchweek, 
        address user
    ) external view returns (uint256);
    
    function updatePlayerPerformance(
        uint256 playerId, 
        PlayerPerformance memory performance
    ) external onlyOracle;
}
```

## Frontend Component Structure

### Core Components
```
src/
├── components/
│   ├── wallet/
│   │   ├── ConnectWallet.tsx
│   │   └── WalletInfo.tsx
│   ├── team/
│   │   ├── TeamBuilder.tsx
│   │   ├── PlayerSelector.tsx
│   │   ├── FormationPicker.tsx
│   │   └── TeamValidation.tsx
│   ├── pool/
│   │   ├── PoolList.tsx
│   │   ├── PoolEntry.tsx
│   │   └── Leaderboard.tsx
│   ├── payment/
│   │   ├── PaymentModal.tsx
│   │   └── TransactionStatus.tsx
│   └── dashboard/
│       ├── UserDashboard.tsx
│       ├── PerformanceChart.tsx
│       └── EarningsHistory.tsx
├── hooks/
│   ├── useContract.ts
│   ├── useTeamBuilder.ts
│   ├── usePayment.ts
│   └── useScoring.ts
├── utils/
│   ├── validation.ts
│   ├── scoring.ts
│   └── formatting.ts
└── types/
    ├── contracts.ts
    ├── team.ts
    └── player.ts
```

## Key Implementation Details

### FPL Scoring System Implementation
```typescript
const calculatePlayerPoints = (player: Player, performance: Performance): number => {
  let points = 0;
  
  // Playing time
  if (performance.minutesPlayed >= 60) points += 2;
  else if (performance.minutesPlayed > 0) points += 1;
  
  // Goals
  if (performance.goals > 0) {
    const goalPoints = player.position === 'GK' || player.position === 'DEF' ? 6 :
                     player.position === 'MID' ? 5 : 4;
    points += performance.goals * goalPoints;
  }
  
  // Assists
  points += performance.assists * 3;
  
  // Clean sheets
  if (performance.cleanSheet && performance.minutesPlayed >= 60) {
    points += player.position === 'GK' || player.position === 'DEF' ? 4 :
              player.position === 'MID' ? 1 : 0;
  }
  
  // Goalkeeper saves (every 3 saves = 1 point)
  if (player.position === 'GK') {
    points += Math.floor(performance.saves / 3);
    points += performance.penaltySaves * 5;
  }
  
  // Penalties
  points += performance.cards; // Already negative values
  points += performance.ownGoals * -2;
  points += performance.penaltyMisses * -2;
  
  // Bonus points
  points += performance.bonusPoints;
  
  return points;
};
```

### Team Validation Logic
```typescript
const validateTeam = (team: Team, players: Player[]): ValidationResult => {
  const errors: string[] = [];
  
  // Check player count
  if (team.playerIds.length !== 15) {
    errors.push("Team must have exactly 15 players");
  }
  
  // Check starting lineup
  if (team.startingLineup.length !== 11) {
    errors.push("Starting lineup must have exactly 11 players");
  }
  
  // Check budget
  const totalCost = team.playerIds.reduce((sum, id) => {
    const player = players.find(p => p.id === id);
    return sum + (player?.price || 0);
  }, 0);
  
  if (totalCost > 100_000_000) { // £100M in pence
    errors.push("Team cost exceeds £100M budget");
  }
  
  // Check formation constraints
  const formation = analyzeFormation(team.startingLineup, players);
  if (!isValidFormation(formation)) {
    errors.push("Invalid formation");
  }
  
  // Check team limits (max 3 players per EPL team)
  const teamCounts = countPlayersPerTeam(team.playerIds, players);
  const violations = Object.entries(teamCounts).filter(([_, count]) => count > 3);
  if (violations.length > 0) {
    errors.push("Maximum 3 players allowed from any EPL team");
  }
  
  return {
    isValid: errors.length === 0,
    errors
  };
};
```

## Risk Mitigation & Security

### Smart Contract Security
- [ ] Reentrancy protection on all external calls
- [ ] Integer overflow/underflow protection
- [ ] Access control with role-based permissions
- [ ] Emergency pause functionality
- [ ] Multi-signature wallet for admin functions

### Oracle Security
- [ ] Multiple data source validation
- [ ] Delay mechanisms for data disputes
- [ ] Manual override capability for emergencies
- [ ] Fallback data sources (API-Football, FPL API)

### Payment Security
- [ ] Escrow mechanisms for user funds
- [ ] Automated payout distribution
- [ ] Transaction monitoring and alerting
- [ ] Refund mechanisms for failed conversions

## Success Metrics

### Technical Metrics
- [ ] Smart contract gas efficiency (<200k gas per transaction)
- [ ] Frontend load time (<3 seconds)
- [ ] 99.9% uptime during matchweeks
- [ ] Zero critical security vulnerabilities

### Business Metrics
- [ ] 100+ users in first matchweek
- [ ] 1000+ users within first month
- [ ] 50%+ user retention rate
- [ ] Average pool size of 20+ participants

## Post-Launch Roadmap

### Phase 4: Enhancement (Weeks 3-4)
- [ ] Advanced analytics and statistics
- [ ] Social features (leagues, friends)
- [ ] Mobile app development (React Native)
- [ ] Multi-language support (Swahili)

### Phase 5: Expansion (Months 2-3)
- [ ] Other football leagues (La Liga, Serie A)
- [ ] Tournament modes (Champions League)
- [ ] NFT integration for achievements
- [ ] Governance token for community decisions

## Conclusion

This work plan provides a comprehensive roadmap for building OnChain FPL in 10 days. The modular approach allows for parallel development and ensures each component can be thoroughly tested before integration. The focus on security, user experience, and Kenyan market needs positions the project for successful launch and adoption.

Key success factors:
1. **Strict adherence to FPL rules** for familiar user experience
2. **Seamless M-Pesa integration** for Kenyan market penetration
3. **Robust oracle integration** for accurate scoring
4. **Mobile-first design** for accessibility
5. **Security-first approach** for user trust and fund safety