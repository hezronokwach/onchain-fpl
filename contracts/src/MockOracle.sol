// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./libraries/DataStructures.sol";
import "./OracleConsumer.sol";

/**
 * @title MockOracle
 * @dev Mock oracle for testing EPL data integration
 */
contract MockOracle {
    OracleConsumer public oracleConsumer;
    
    // Mock data storage
    mapping(uint256 => mapping(uint256 => DataStructures.PlayerPerformance)) public mockPerformances;
    mapping(uint256 => uint256[]) public matchweekPlayers;
    
    event MockDataSet(uint256 indexed matchweek, uint256 indexed playerId);
    event MockDataSubmitted(uint256 indexed matchweek, uint256 playerCount);
    
    constructor(address _oracleConsumer) {
        oracleConsumer = OracleConsumer(_oracleConsumer);
    }

    /**
     * @notice Set mock performance data for a player
     * @param matchweek The matchweek number
     * @param playerId The player ID
     * @param goals Goals scored
     * @param assists Assists made
     * @param minutesPlayed Minutes played
     * @param cleanSheet Whether player kept clean sheet
     * @param saves Saves made (goalkeepers)
     * @param cards Cards received (-1 yellow, -3 red)
     * @param ownGoal Whether player scored own goal
     * @param penaltyMiss Whether player missed penalty
     * @param bonusPoints Bonus points awarded
     */
    function setMockPerformance(
        uint256 matchweek,
        uint256 playerId,
        uint256 goals,
        uint256 assists,
        uint256 minutesPlayed,
        bool cleanSheet,
        uint256 saves,
        int256 cards,
        bool ownGoal,
        bool penaltyMiss,
        uint256 bonusPoints
    ) public {
        mockPerformances[matchweek][playerId] = DataStructures.PlayerPerformance({
            playerId: playerId,
            matchweek: matchweek,
            goals: goals,
            assists: assists,
            minutesPlayed: minutesPlayed,
            cleanSheet: cleanSheet,
            saves: saves,
            cards: cards,
            ownGoal: ownGoal,
            penaltyMiss: penaltyMiss,
            bonusPoints: bonusPoints,
            isValidated: true
        });
        
        // Add to matchweek players if not already present
        bool playerExists = false;
        uint256[] storage players = matchweekPlayers[matchweek];
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == playerId) {
                playerExists = true;
                break;
            }
        }
        
        if (!playerExists) {
            matchweekPlayers[matchweek].push(playerId);
        }
        
        emit MockDataSet(matchweek, playerId);
    }

    /**
     * @notice Set multiple mock performances at once
     * @param matchweek The matchweek number
     * @param playerIds Array of player IDs
     * @param performances Array of performance data
     */
    function setMockPerformances(
        uint256 matchweek,
        uint256[] memory playerIds,
        DataStructures.PlayerPerformance[] memory performances
    ) external {
        require(playerIds.length == performances.length, "Array length mismatch");
        
        for (uint256 i = 0; i < playerIds.length; i++) {
            performances[i].playerId = playerIds[i];
            performances[i].matchweek = matchweek;
            performances[i].isValidated = true;
            
            mockPerformances[matchweek][playerIds[i]] = performances[i];
            
            // Add to matchweek players if not already present
            bool playerExists = false;
            uint256[] storage players = matchweekPlayers[matchweek];
            for (uint256 j = 0; j < players.length; j++) {
                if (players[j] == playerIds[i]) {
                    playerExists = true;
                    break;
                }
            }
            
            if (!playerExists) {
                matchweekPlayers[matchweek].push(playerIds[i]);
            }
            
            emit MockDataSet(matchweek, playerIds[i]);
        }
    }

    /**
     * @notice Submit mock data to oracle consumer
     * @param matchweek The matchweek number
     */
    function submitMockData(uint256 matchweek) external {
        uint256[] memory players = matchweekPlayers[matchweek];
        require(players.length > 0, "No mock data for matchweek");
        
        DataStructures.PlayerPerformance[] memory performances = 
            new DataStructures.PlayerPerformance[](players.length);
        
        for (uint256 i = 0; i < players.length; i++) {
            performances[i] = mockPerformances[matchweek][players[i]];
        }
        
        oracleConsumer.submitMatchData(matchweek, performances, block.timestamp);
        emit MockDataSubmitted(matchweek, players.length);
    }

    /**
     * @notice Create realistic mock data for testing
     * @param matchweek The matchweek number
     * @param playerCount Number of players to create data for
     */
    function createRealisticMockData(uint256 matchweek, uint256 playerCount) external {
        require(playerCount > 0 && playerCount <= 100, "Invalid player count");
        
        for (uint256 i = 1; i <= playerCount; i++) {
            uint256 playerId = i;
            
            // Generate pseudo-random but realistic performance data
            uint256 seed = uint256(keccak256(abi.encodePacked(matchweek, playerId, block.timestamp)));
            
            // Minutes played (0, 1-59, 60-90)
            uint256 minutesPlayed;
            uint256 playedRand = seed % 100;
            if (playedRand < 15) {
                minutesPlayed = 0; // 15% didn't play
            } else if (playedRand < 25) {
                minutesPlayed = 1 + (seed % 59); // 10% played partial
            } else {
                minutesPlayed = 60 + (seed % 31); // 75% played full
            }
            
            // Goals (weighted by position - assuming player 1-20 are forwards, etc.)
            uint256 goals = 0;
            if (minutesPlayed > 0) {
                uint256 goalRand = (seed >> 8) % 100;
                if (playerId <= 20) { // Forwards
                    if (goalRand < 25) goals = 1;
                    else if (goalRand < 30) goals = 2;
                } else if (playerId <= 60) { // Midfielders
                    if (goalRand < 15) goals = 1;
                    else if (goalRand < 18) goals = 2;
                } else if (playerId <= 100) { // Defenders
                    if (goalRand < 8) goals = 1;
                }
            }
            
            // Assists
            uint256 assists = 0;
            if (minutesPlayed > 0) {
                uint256 assistRand = (seed >> 16) % 100;
                if (assistRand < 20) assists = 1;
                else if (assistRand < 25) assists = 2;
            }
            
            // Clean sheet (defenders and goalkeepers)
            bool cleanSheet = false;
            if (minutesPlayed >= 60 && playerId > 60) {
                cleanSheet = ((seed >> 24) % 100) < 40; // 40% chance
            }
            
            // Saves (goalkeepers only)
            uint256 saves = 0;
            if (playerId > 90 && minutesPlayed > 0) { // Last 10 are goalkeepers
                saves = (seed >> 32) % 8; // 0-7 saves
            }
            
            // Cards
            int256 cards = 0;
            if (minutesPlayed > 0) {
                uint256 cardRand = (seed >> 40) % 100;
                if (cardRand < 15) cards = -1; // Yellow card
                else if (cardRand < 17) cards = -3; // Red card
            }
            
            // Own goal (rare)
            bool ownGoal = minutesPlayed > 0 && ((seed >> 48) % 1000) < 5; // 0.5% chance
            
            // Penalty miss (rare)
            bool penaltyMiss = minutesPlayed > 0 && ((seed >> 56) % 1000) < 10; // 1% chance
            
            // Bonus points
            uint256 bonusPoints = 0;
            if (minutesPlayed >= 60) {
                uint256 bonusRand = (seed >> 64) % 100;
                if (bonusRand < 10) bonusPoints = 1;
                else if (bonusRand < 15) bonusPoints = 2;
                else if (bonusRand < 17) bonusPoints = 3;
            }
            
            setMockPerformance(
                matchweek,
                playerId,
                goals,
                assists,
                minutesPlayed,
                cleanSheet,
                saves,
                cards,
                ownGoal,
                penaltyMiss,
                bonusPoints
            );
        }
    }

    /**
     * @notice Get mock performance data
     * @param matchweek The matchweek number
     * @param playerId The player ID
     * @return performance The mock performance data
     */
    function getMockPerformance(uint256 matchweek, uint256 playerId) 
        external 
        view 
        returns (DataStructures.PlayerPerformance memory performance) 
    {
        return mockPerformances[matchweek][playerId];
    }

    /**
     * @notice Get all players for a matchweek
     * @param matchweek The matchweek number
     * @return players Array of player IDs
     */
    function getMatchweekPlayers(uint256 matchweek) external view returns (uint256[] memory players) {
        return matchweekPlayers[matchweek];
    }

    /**
     * @notice Clear mock data for a matchweek
     * @param matchweek The matchweek number
     */
    function clearMockData(uint256 matchweek) external {
        uint256[] memory players = matchweekPlayers[matchweek];
        
        for (uint256 i = 0; i < players.length; i++) {
            delete mockPerformances[matchweek][players[i]];
        }
        
        delete matchweekPlayers[matchweek];
    }
}