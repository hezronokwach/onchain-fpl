// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/DataStructures.sol";
import "./PoolManager.sol";
import "./ScoringEngine.sol";

/**
 * @title PayoutDistributor
 * @dev Automated prize distribution system for OnChain FPL
 */
contract PayoutDistributor is Ownable, ReentrancyGuard {
    
    // Contract interfaces
    PoolManager public poolManager;
    ScoringEngine public scoringEngine;
    
    // Payout tracking
    mapping(uint256 => bool) public payoutProcessed; // matchweek => processed
    mapping(uint256 => address[]) public winners; // matchweek => winner addresses
    mapping(uint256 => uint256) public payoutAmounts; // matchweek => amount per winner
    
    // Events
    event PayoutProcessed(
        uint256 indexed matchweek, 
        address[] winners, 
        uint256 totalPrize, 
        uint256 amountPerWinner
    );
    event EmergencyWithdrawal(uint256 indexed matchweek, uint256 amount);
    event ContractsUpdated(address poolManager, address scoringEngine);
    
    // Errors
    error PayoutAlreadyProcessed();
    error NoParticipants();
    error ScoresNotCalculated();
    error TransferFailed();
    error InvalidContract();
    error PoolNotFinalized();
    
    constructor(address _poolManager, address _scoringEngine) {
        if (_poolManager == address(0) || _scoringEngine == address(0)) {
            revert InvalidContract();
        }
        poolManager = PoolManager(_poolManager);
        scoringEngine = ScoringEngine(_scoringEngine);
    }

    /**
     * @notice Process payout for a completed matchweek
     * @dev Determines winner(s) and distributes prize pool
     * @param matchweek The matchweek to process
     */
    function processPayout(uint256 matchweek) external nonReentrant {
        if (payoutProcessed[matchweek]) revert PayoutAlreadyProcessed();
        
        DataStructures.Pool memory pool = poolManager.getPool(matchweek);
        address[] memory participants = poolManager.getParticipants(matchweek);
        
        if (participants.length == 0) revert NoParticipants();
        if (!_areScoresCalculated(matchweek, participants)) revert ScoresNotCalculated();
        
        // Find winner(s) using tie-breaking algorithm
        address[] memory matchweekWinners = _determineWinners(matchweek, participants);
        
        // Calculate payout per winner
        uint256 amountPerWinner = pool.totalPrize / matchweekWinners.length;
        
        // Distribute prizes
        _distributePrizes(matchweekWinners, amountPerWinner);
        
        // Update state
        payoutProcessed[matchweek] = true;
        winners[matchweek] = matchweekWinners;
        payoutAmounts[matchweek] = amountPerWinner;
        
        // Finalize pool in PoolManager
        poolManager.finalizePool(
            matchweek, 
            matchweekWinners[0], // Primary winner for pool record
            scoringEngine.getTeamScore(matchweek, matchweekWinners[0]).totalPoints
        );
        
        emit PayoutProcessed(matchweek, matchweekWinners, pool.totalPrize, amountPerWinner);
    }

    /**
     * @dev Check if all participants have calculated scores
     * @param matchweek The matchweek number
     * @param participants Array of participant addresses
     * @return allCalculated Whether all scores are calculated
     */
    function _areScoresCalculated(uint256 matchweek, address[] memory participants) 
        internal view returns (bool allCalculated) {
        for (uint256 i = 0; i < participants.length; i++) {
            DataStructures.TeamScore memory score = scoringEngine.getTeamScore(matchweek, participants[i]);
            if (!score.isCalculated) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Determine winner(s) using FPL tie-breaking rules
     * @param matchweek The matchweek number
     * @param participants Array of all participants
     * @return winnerAddresses Array of winner addresses (1 or more if tied)
     */
    function _determineWinners(
        uint256 matchweek, 
        address[] memory participants
    ) internal view returns (address[] memory winnerAddresses) {
        
        uint256 participantCount = participants.length;
        if (participantCount == 1) {
            winnerAddresses = new address[](1);
            winnerAddresses[0] = participants[0];
            return winnerAddresses;
        }
        
        // Step 1: Find highest total score
        uint256 highestScore = 0;
        uint256 winnersCount = 0;
        
        for (uint256 i = 0; i < participantCount; i++) {
            DataStructures.TeamScore memory score = scoringEngine.getTeamScore(matchweek, participants[i]);
            
            if (score.totalPoints > highestScore) {
                highestScore = score.totalPoints;
                winnersCount = 1;
            } else if (score.totalPoints == highestScore) {
                winnersCount++;
            }
        }
        
        // Collect all participants with highest score
        address[] memory topScorers = new address[](winnersCount);
        uint256 topScorerIndex = 0;
        
        for (uint256 i = 0; i < participantCount; i++) {
            DataStructures.TeamScore memory score = scoringEngine.getTeamScore(matchweek, participants[i]);
            if (score.totalPoints == highestScore) {
                topScorers[topScorerIndex] = participants[i];
                topScorerIndex++;
            }
        }
        
        // If only one winner, return immediately
        if (topScorers.length == 1) {
            return topScorers;
        }
        
        // Apply tie-breaking rules
        return _applyTieBreaking(matchweek, topScorers);
    }

    /**
     * @dev Apply tie-breaking rules for multiple winners
     * @param matchweek The matchweek number
     * @param tiedParticipants Array of participants with same highest score
     * @return finalWinners Array of final winners after tie-breaking
     */
    function _applyTieBreaking(
        uint256 matchweek, 
        address[] memory tiedParticipants
    ) internal view returns (address[] memory finalWinners) {
        
        if (tiedParticipants.length == 1) {
            return tiedParticipants;
        }
        
        // Tie-Breaking Rule 1: Highest bench score
        finalWinners = _tieBreakByBenchScore(matchweek, tiedParticipants);
        if (finalWinners.length == 1) return finalWinners;
        
        // Tie-Breaking Rule 2: Most goals scored by team
        finalWinners = _tieBreakByGoals(matchweek, finalWinners);
        if (finalWinners.length == 1) return finalWinners;
        
        // Tie-Breaking Rule 3: Fewest cards received by team
        finalWinners = _tieBreakByCards(matchweek, finalWinners);
        if (finalWinners.length == 1) return finalWinners;
        
        // If still tied after all rules, split prize equally
        return finalWinners;
    }

    /**
     * @dev Tie-breaking by highest bench score
     */
    function _tieBreakByBenchScore(
        uint256 matchweek, 
        address[] memory participants
    ) internal view returns (address[] memory) {
        
        uint256 highestBenchScore = 0;
        uint256 winnersCount = 0;
        
        // Find highest bench score
        for (uint256 i = 0; i < participants.length; i++) {
            DataStructures.TeamScore memory score = scoringEngine.getTeamScore(matchweek, participants[i]);
            
            if (score.benchPoints > highestBenchScore) {
                highestBenchScore = score.benchPoints;
                winnersCount = 1;
            } else if (score.benchPoints == highestBenchScore) {
                winnersCount++;
            }
        }
        
        // Collect winners
        address[] memory tieBreakWinners = new address[](winnersCount);
        uint256 winnerIndex = 0;
        
        for (uint256 i = 0; i < participants.length; i++) {
            DataStructures.TeamScore memory score = scoringEngine.getTeamScore(matchweek, participants[i]);
            if (score.benchPoints == highestBenchScore) {
                tieBreakWinners[winnerIndex] = participants[i];
                winnerIndex++;
            }
        }
        
        return tieBreakWinners;
    }

    /**
     * @dev Tie-breaking by most goals scored
     */
    function _tieBreakByGoals(
        uint256 matchweek, 
        address[] memory participants
    ) internal view returns (address[] memory) {
        
        uint256 mostGoals = 0;
        uint256 winnersCount = 0;
        
        // Find most goals
        for (uint256 i = 0; i < participants.length; i++) {
            uint256 teamGoals = _getTeamGoals(matchweek, participants[i]);
            
            if (teamGoals > mostGoals) {
                mostGoals = teamGoals;
                winnersCount = 1;
            } else if (teamGoals == mostGoals) {
                winnersCount++;
            }
        }
        
        // Collect winners
        address[] memory tieBreakWinners = new address[](winnersCount);
        uint256 winnerIndex = 0;
        
        for (uint256 i = 0; i < participants.length; i++) {
            uint256 teamGoals = _getTeamGoals(matchweek, participants[i]);
            if (teamGoals == mostGoals) {
                tieBreakWinners[winnerIndex] = participants[i];
                winnerIndex++;
            }
        }
        
        return tieBreakWinners;
    }

    /**
     * @dev Tie-breaking by fewest cards received
     */
    function _tieBreakByCards(
        uint256 matchweek, 
        address[] memory participants
    ) internal view returns (address[] memory) {
        
        uint256 fewestCards = type(uint256).max;
        uint256 winnersCount = 0;
        
        // Find fewest cards
        for (uint256 i = 0; i < participants.length; i++) {
            uint256 teamCards = _getTeamCards(matchweek, participants[i]);
            
            if (teamCards < fewestCards) {
                fewestCards = teamCards;
                winnersCount = 1;
            } else if (teamCards == fewestCards) {
                winnersCount++;
            }
        }
        
        // Collect winners
        address[] memory tieBreakWinners = new address[](winnersCount);
        uint256 winnerIndex = 0;
        
        for (uint256 i = 0; i < participants.length; i++) {
            uint256 teamCards = _getTeamCards(matchweek, participants[i]);
            if (teamCards == fewestCards) {
                tieBreakWinners[winnerIndex] = participants[i];
                winnerIndex++;
            }
        }
        
        return tieBreakWinners;
    }

    /**
     * @dev Get total goals scored by a team
     * @param matchweek The matchweek number
     * @param user The team owner
     * @return totalGoals Total goals scored by the team
     */
    function _getTeamGoals(uint256 matchweek, address user) internal view returns (uint256 totalGoals) {
        DataStructures.TeamScore memory teamScore = scoringEngine.getTeamScore(matchweek, user);
        
        // Sum goals from all starting players
        for (uint256 i = 0; i < 11; i++) {
            if (teamScore.playerPoints[i] > 0) {
                // This is a simplified approach - in a full implementation,
                // we would need to track goals separately in the scoring engine
                totalGoals += teamScore.playerPoints[i] / 10; // Rough approximation
            }
        }
        
        return totalGoals;
    }

    /**
     * @dev Get total cards received by a team
     * @param matchweek The matchweek number
     * @param user The team owner
     * @return totalCards Total cards received by the team
     */
    function _getTeamCards(uint256 matchweek, address user) internal view returns (uint256 totalCards) {
        // This is a simplified implementation
        // In a full system, cards would be tracked separately
        return 0; // Placeholder - would need proper implementation
    }

    /**
     * @dev Distribute prizes to winners
     * @param winnerAddresses Array of winner addresses
     * @param amountPerWinner Amount each winner receives
     */
    function _distributePrizes(
        address[] memory winnerAddresses, 
        uint256 amountPerWinner
    ) internal {
        for (uint256 i = 0; i < winnerAddresses.length; i++) {
            (bool success, ) = payable(winnerAddresses[i]).call{value: amountPerWinner}("");
            if (!success) revert TransferFailed();
        }
    }

    /**
     * @notice Get winners for a matchweek
     * @param matchweek The matchweek number
     * @return winnerAddresses Array of winner addresses
     * @return amountPerWinner Amount each winner received
     */
    function getWinners(uint256 matchweek) 
        external 
        view 
        returns (address[] memory winnerAddresses, uint256 amountPerWinner) 
    {
        return (winners[matchweek], payoutAmounts[matchweek]);
    }

    /**
     * @notice Check if payout has been processed for a matchweek
     * @param matchweek The matchweek number
     * @return processed Whether payout has been processed
     */
    function isPayoutProcessed(uint256 matchweek) external view returns (bool processed) {
        return payoutProcessed[matchweek];
    }

    /**
     * @notice Check if matchweek is ready for payout processing
     * @param matchweek The matchweek number
     * @return ready Whether matchweek is ready for payout
     */
    function isMatchweekReadyForPayout(uint256 matchweek) external view returns (bool ready) {
        if (payoutProcessed[matchweek]) return false;
        
        address[] memory participants = poolManager.getParticipants(matchweek);
        if (participants.length == 0) return false;
        
        return _areScoresCalculated(matchweek, participants);
    }

    /**
     * @notice Emergency withdrawal function
     * @dev Only owner can call in case of critical issues
     * @param matchweek The matchweek to withdraw funds from
     */
    function emergencyWithdraw(uint256 matchweek) external onlyOwner {
        require(!payoutProcessed[matchweek], "Payout already processed");
        
        DataStructures.Pool memory pool = poolManager.getPool(matchweek);
        uint256 amount = pool.totalPrize;
        
        if (amount > 0) {
            (bool success, ) = payable(owner()).call{value: amount}("");
            if (!success) revert TransferFailed();
            
            emit EmergencyWithdrawal(matchweek, amount);
        }
    }

    /**
     * @notice Update contract addresses
     * @dev Only owner can update contract references
     * @param _poolManager New PoolManager address
     * @param _scoringEngine New ScoringEngine address
     */
    function updateContracts(address _poolManager, address _scoringEngine) external onlyOwner {
        if (_poolManager == address(0) || _scoringEngine == address(0)) {
            revert InvalidContract();
        }
        
        poolManager = PoolManager(_poolManager);
        scoringEngine = ScoringEngine(_scoringEngine);
        
        emit ContractsUpdated(_poolManager, _scoringEngine);
    }

    /**
     * @notice Receive function to accept ETH
     */
    receive() external payable {}
}