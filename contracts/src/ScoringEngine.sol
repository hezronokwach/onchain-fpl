// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/DataStructures.sol";
import "./libraries/ValidationLibrary.sol";
import "./TeamManager.sol";

/**
 * @title ScoringEngine
 * @dev Implements the official FPL scoring system with auto-substitution
 */
contract ScoringEngine is Ownable, ReentrancyGuard {
    using ValidationLibrary for *;
    
    TeamManager public teamManager;
    
    // Matchweek scores: matchweek => owner => TeamScore
    mapping(uint256 => mapping(address => DataStructures.TeamScore)) public teamScores;
    
    // Player performances: matchweek => playerId => PlayerPerformance
    mapping(uint256 => mapping(uint256 => DataStructures.PlayerPerformance)) public playerPerformances;
    
    // Track calculated scores: matchweek => owner => calculated
    mapping(uint256 => mapping(address => bool)) public isScoreCalculated;
    
    // Events
    event PlayerPerformanceUpdated(uint256 indexed matchweek, uint256 indexed playerId, uint256 points);
    event TeamScoreCalculated(uint256 indexed matchweek, address indexed owner, uint256 totalPoints);
    event AutoSubstitutionMade(uint256 indexed matchweek, address indexed owner, uint256 benchIndex, uint256 startingIndex);
    
    constructor(address _teamManager) {
        teamManager = TeamManager(_teamManager);
    }

    /**
     * @notice Update player performance data for a matchweek (Owner only)
     * @param matchweek The matchweek number
     * @param playerId The player ID
     * @param performance The player performance data
     */
    function updatePlayerPerformance(
        uint256 matchweek,
        uint256 playerId,
        DataStructures.PlayerPerformance memory performance
    ) external onlyOwner {
        require(ValidationLibrary.isValidMatchweek(matchweek), "Invalid matchweek");
        require(playerId > 0, "Invalid player ID");
        require(performance.playerId == playerId, "Player ID mismatch");
        require(performance.matchweek == matchweek, "Matchweek mismatch");
        
        playerPerformances[matchweek][playerId] = performance;
        
        uint256 points = calculatePlayerPoints(performance);
        emit PlayerPerformanceUpdated(matchweek, playerId, points);
    }

    /**
     * @notice Calculate team score for a matchweek
     * @param matchweek The matchweek number
     * @param owner The team owner
     */
    function calculateTeamScore(uint256 matchweek, address owner) external nonReentrant {
        require(ValidationLibrary.isValidMatchweek(matchweek), "Invalid matchweek");
        require(teamManager.hasUserSubmittedTeam(matchweek, owner), "No team submitted");
        require(!isScoreCalculated[matchweek][owner], "Score already calculated");
        
        DataStructures.Team memory team = teamManager.getTeam(matchweek, owner);
        uint256[11] memory finalLineup = _performAutoSubstitutions(matchweek, team);
        
        (uint256[11] memory playerPoints, uint256 totalPoints) = _calculateLineupPoints(matchweek, team, finalLineup);
        uint256 captainPoints = _calculateCaptainPoints(matchweek, team, finalLineup);
        uint256 benchPoints = _calculateBenchPoints(matchweek, team, finalLineup);
        
        totalPoints += captainPoints;
        
        teamScores[matchweek][owner] = DataStructures.TeamScore({
            owner: owner,
            matchweek: matchweek,
            totalPoints: totalPoints,
            playerPoints: playerPoints,
            benchPoints: benchPoints,
            captainPoints: captainPoints,
            isCalculated: true,
            calculationTime: block.timestamp
        });
        
        isScoreCalculated[matchweek][owner] = true;
        emit TeamScoreCalculated(matchweek, owner, totalPoints);
    }
    
    /**
     * @dev Calculate points for lineup players
     */
    function _calculateLineupPoints(uint256 matchweek, DataStructures.Team memory team, uint256[11] memory finalLineup) 
        internal view returns (uint256[11] memory playerPoints, uint256 totalPoints) {
        for (uint256 i = 0; i < 11; i++) {
            uint256 playerId = team.playerIds[finalLineup[i]];
            uint256 points = calculatePlayerPoints(playerPerformances[matchweek][playerId]);
            playerPoints[i] = points;
            totalPoints += points;
        }
    }
    
    /**
     * @dev Calculate captain bonus points
     */
    function _calculateCaptainPoints(uint256 matchweek, DataStructures.Team memory team, uint256[11] memory finalLineup) 
        internal view returns (uint256 captainPoints) {
        uint256 captainIndex = team.startingLineup[team.captainIndex];
        uint256 viceCaptainIndex = team.startingLineup[team.viceCaptainIndex];
        
        if (_isPlayerInFinalLineup(finalLineup, captainIndex)) {
            uint256 playerId = team.playerIds[captainIndex];
            captainPoints = calculatePlayerPoints(playerPerformances[matchweek][playerId]);
        } else if (_isPlayerInFinalLineup(finalLineup, viceCaptainIndex)) {
            uint256 playerId = team.playerIds[viceCaptainIndex];
            captainPoints = calculatePlayerPoints(playerPerformances[matchweek][playerId]);
        }
    }
    
    /**
     * @dev Calculate bench points for tie-breaking
     */
    function _calculateBenchPoints(uint256 matchweek, DataStructures.Team memory team, uint256[11] memory finalLineup) 
        internal view returns (uint256 benchPoints) {
        for (uint256 i = 0; i < 15; i++) {
            if (!_isPlayerInFinalLineup(finalLineup, i)) {
                uint256 playerId = team.playerIds[i];
                benchPoints += calculatePlayerPoints(playerPerformances[matchweek][playerId]);
            }
        }
    }

    /**
     * @notice Calculate points for a single player performance
     * @param performance The player performance data
     * @return points Total points earned
     */
    function calculatePlayerPoints(DataStructures.PlayerPerformance memory performance) 
        public 
        view 
        returns (uint256 points) 
    {
        if (!performance.isValidated || performance.minutesPlayed == 0) {
            return 0;
        }
        
        // Playing time points
        if (performance.minutesPlayed >= 60) {
            points += DataStructures.MINUTES_PLAYED_FULL; // 2 points
        } else {
            points += DataStructures.MINUTES_PLAYED_PARTIAL; // 1 point
        }
        
        // Get player position
        DataStructures.Player memory player = teamManager.getPlayer(performance.playerId);
        
        // Goal points (position-based)
        if (performance.goals > 0) {
            if (player.position == Position.GK || player.position == Position.DEF) {
                points += performance.goals * DataStructures.GOAL_POINTS_GK_DEF; // 6 points each
            } else if (player.position == Position.MID) {
                points += performance.goals * DataStructures.GOAL_POINTS_MID; // 5 points each
            } else if (player.position == Position.FWD) {
                points += performance.goals * DataStructures.GOAL_POINTS_FWD; // 4 points each
            }
        }
        
        // Assist points
        points += performance.assists * DataStructures.ASSIST_POINTS; // 3 points each
        
        // Clean sheet points (only if played 60+ minutes)
        if (performance.cleanSheet && performance.minutesPlayed >= 60) {
            if (player.position == Position.GK || player.position == Position.DEF) {
                points += DataStructures.CLEAN_SHEET_GK_DEF; // 4 points
            } else if (player.position == Position.MID) {
                points += DataStructures.CLEAN_SHEET_MID; // 1 point
            }
        }
        
        // Goalkeeper saves (every 3 saves = 1 point)
        if (player.position == Position.GK && performance.saves > 0) {
            points += performance.saves / DataStructures.SAVES_PER_POINT; // Every 3 saves
        }
        
        // Penalty saves (goalkeepers only)
        if (player.position == Position.GK) {
            // Assuming penalty saves are tracked separately in bonus points
            // This would need to be added to PlayerPerformance struct
        }
        
        // Bonus points
        points += performance.bonusPoints;
        
        // Negative points (cards, own goals, penalty misses)
        if (performance.cards < 0) {
            points = points > uint256(-performance.cards) ? points - uint256(-performance.cards) : 0;
        }
        
        if (performance.ownGoal) {
            points = points > 2 ? points - 2 : 0; // -2 points for own goal
        }
        
        if (performance.penaltyMiss) {
            points = points > 2 ? points - 2 : 0; // -2 points for penalty miss
        }
        
        return points;
    }

    /**
     * @notice Get team score for a matchweek
     * @param matchweek The matchweek number
     * @param owner The team owner
     * @return score The team score data
     */
    function getTeamScore(uint256 matchweek, address owner) 
        external 
        view 
        returns (DataStructures.TeamScore memory score) 
    {
        return teamScores[matchweek][owner];
    }

    /**
     * @notice Get player performance for a matchweek
     * @param matchweek The matchweek number
     * @param playerId The player ID
     * @return performance The player performance data
     */
    function getPlayerPerformance(uint256 matchweek, uint256 playerId) 
        external 
        view 
        returns (DataStructures.PlayerPerformance memory performance) 
    {
        return playerPerformances[matchweek][playerId];
    }

    /**
     * @dev Perform auto-substitutions based on player availability
     * @param matchweek The matchweek number
     * @param team The team data
     * @return finalLineup The final starting lineup after substitutions
     */
    function _performAutoSubstitutions(uint256 matchweek, DataStructures.Team memory team) 
        internal 
        returns (uint256[11] memory finalLineup) 
    {
        // Start with original lineup
        for (uint256 i = 0; i < 11; i++) {
            finalLineup[i] = team.startingLineup[i];
        }
        
        // Check each starting player and substitute if didn't play
        for (uint256 i = 0; i < 11; i++) {
            uint256 playerIndex = finalLineup[i];
            uint256 playerId = team.playerIds[playerIndex];
            
            // If player didn't play, try to substitute
            if (playerPerformances[matchweek][playerId].minutesPlayed == 0) {
                uint256 substituteIndex = _findValidSubstitute(matchweek, team, finalLineup, playerIndex);
                if (substituteIndex != type(uint256).max) {
                    finalLineup[i] = substituteIndex;
                    emit AutoSubstitutionMade(matchweek, team.owner, substituteIndex, playerIndex);
                }
            }
        }
        
        return finalLineup;
    }

    /**
     * @dev Find a valid substitute from the bench
     * @param matchweek The matchweek number
     * @param team The team data
     * @param currentLineup The current lineup
     * @param playerToReplace Index of player to replace
     * @return substituteIndex Index of substitute player, or type(uint256).max if none found
     */
    function _findValidSubstitute(
        uint256 matchweek,
        DataStructures.Team memory team,
        uint256[11] memory currentLineup,
        uint256 playerToReplace
    ) internal view returns (uint256 substituteIndex) {
        DataStructures.Player memory playerOut = teamManager.getPlayer(team.playerIds[playerToReplace]);
        
        // Check bench players (indices 11-14 in squad)
        for (uint256 i = 11; i < 15; i++) {
            if (_isPlayerInFinalLineup(currentLineup, i)) continue; // Already in lineup
            
            uint256 playerId = team.playerIds[i];
            DataStructures.Player memory benchPlayer = teamManager.getPlayer(playerId);
            
            // Check if substitute played and can maintain formation
            if (playerPerformances[matchweek][playerId].minutesPlayed > 0) {
                if (_canMaintainFormation(team, currentLineup, playerToReplace, i, playerOut.position, benchPlayer.position)) {
                    return i;
                }
            }
        }
        
        return type(uint256).max; // No valid substitute found
    }

    /**
     * @dev Check if substitution maintains valid formation
     * @param team The team data
     * @param currentLineup Current starting lineup
     * @param outIndex Index of player going out
     * @param inIndex Index of player coming in
     * @param outPosition Position of player going out
     * @param inPosition Position of player coming in
     * @return canSubstitute Whether substitution maintains formation
     */
    function _canMaintainFormation(
        DataStructures.Team memory team,
        uint256[11] memory currentLineup,
        uint256 outIndex,
        uint256 inIndex,
        Position outPosition,
        Position inPosition
    ) internal view returns (bool canSubstitute) {
        // Same position substitution is always valid
        if (outPosition == inPosition) {
            return true;
        }
        
        // Get formation requirements
        DataStructures.FormationCount memory required = ValidationLibrary.getFormationCounts(team.formation);
        
        // Count current positions in lineup (excluding player going out)
        uint256[4] memory positionCounts;
        for (uint256 i = 0; i < 11; i++) {
            if (i != outIndex) {
                uint256 playerIndex = currentLineup[i];
                uint256 playerId = team.playerIds[playerIndex];
                DataStructures.Player memory player = teamManager.getPlayer(playerId);
                positionCounts[uint256(player.position)]++;
            }
        }
        
        // Add incoming player position
        positionCounts[uint256(inPosition)]++;
        
        // Check if formation is maintained
        return (positionCounts[0] == required.goalkeepers &&
                positionCounts[1] == required.defenders &&
                positionCounts[2] == required.midfielders &&
                positionCounts[3] == required.forwards);
    }

    /**
     * @dev Check if a player index is in the starting lineup
     * @param lineup The starting lineup indices
     * @param playerIndex The player index to check
     * @return isInLineup Whether player is in lineup
     */
    function _isPlayerInLineup(uint256[11] memory lineup, uint256 playerIndex) 
        internal 
        pure 
        returns (bool isInLineup) 
    {
        for (uint256 i = 0; i < 11; i++) {
            if (lineup[i] == playerIndex) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Check if a player index is in the final lineup
     * @param finalLineup The final lineup indices
     * @param playerIndex The player index to check
     * @return isInLineup Whether player is in final lineup
     */
    function _isPlayerInFinalLineup(uint256[11] memory finalLineup, uint256 playerIndex) 
        internal 
        pure 
        returns (bool isInLineup) 
    {
        for (uint256 i = 0; i < 11; i++) {
            if (finalLineup[i] == playerIndex) {
                return true;
            }
        }
        return false;
    }
}