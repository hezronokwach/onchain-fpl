// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ScoringEngine.sol";
import "../src/TeamManager.sol";

contract ScoringEngineTest is Test {
    ScoringEngine public scoringEngine;
    TeamManager public teamManager;
    
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    
    function setUp() public {
        vm.prank(owner);
        teamManager = new TeamManager();
        
        vm.prank(owner);
        scoringEngine = new ScoringEngine(address(teamManager));
        
        // Setup sample players and team
        _setupSampleData();
    }
    
    function _setupSampleData() internal {
        vm.startPrank(owner);
        
        // Add sample players (15 players for a valid team)
        // 2 Goalkeepers
        teamManager.addPlayer(1, "GK1", Position.GK, 4500000, 1);
        teamManager.addPlayer(2, "GK2", Position.GK, 4000000, 2);
        
        // 5 Defenders
        teamManager.addPlayer(3, "DEF1", Position.DEF, 5500000, 1);
        teamManager.addPlayer(4, "DEF2", Position.DEF, 5000000, 2);
        teamManager.addPlayer(5, "DEF3", Position.DEF, 4500000, 3);
        teamManager.addPlayer(6, "DEF4", Position.DEF, 4000000, 4);
        teamManager.addPlayer(7, "DEF5", Position.DEF, 4000000, 5);
        
        // 5 Midfielders
        teamManager.addPlayer(8, "MID1", Position.MID, 7000000, 1);
        teamManager.addPlayer(9, "MID2", Position.MID, 6500000, 6);
        teamManager.addPlayer(10, "MID3", Position.MID, 6000000, 7);
        teamManager.addPlayer(11, "MID4", Position.MID, 5500000, 8);
        teamManager.addPlayer(12, "MID5", Position.MID, 5000000, 9);
        
        // 3 Forwards
        teamManager.addPlayer(13, "FWD1", Position.FWD, 9000000, 10);
        teamManager.addPlayer(14, "FWD2", Position.FWD, 8500000, 11);
        teamManager.addPlayer(15, "FWD3", Position.FWD, 8000000, 12);
        
        // Set deadline for matchweek 1
        teamManager.setPoolDeadline(1, block.timestamp + 7 days);
        
        vm.stopPrank();
        
        // Submit a team for user1
        _submitSampleTeam();
    }
    
    function _submitSampleTeam() internal {
        uint256[15] memory playerIds = [uint256(1), 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
        uint256[11] memory startingLineup = [uint256(0), 2, 3, 4, 5, 7, 8, 9, 10, 12, 13]; // 4-4-2 formation
        uint256 captainIndex = 10; // FWD1
        uint256 viceCaptainIndex = 9; // MID4
        Formation formation = Formation.F_4_4_2;
        
        vm.prank(user1);
        teamManager.submitTeam(1, playerIds, startingLineup, captainIndex, viceCaptainIndex, formation);
    }
    
    function _createSamplePerformance(
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
    ) internal pure returns (DataStructures.PlayerPerformance memory) {
        return _createSamplePerformanceWithMatchweek(playerId, 1, goals, assists, minutesPlayed, cleanSheet, saves, cards, ownGoal, penaltyMiss, bonusPoints);
    }
    
    function _createSamplePerformanceWithMatchweek(
        uint256 playerId,
        uint256 matchweek,
        uint256 goals,
        uint256 assists,
        uint256 minutesPlayed,
        bool cleanSheet,
        uint256 saves,
        int256 cards,
        bool ownGoal,
        bool penaltyMiss,
        uint256 bonusPoints
    ) internal pure returns (DataStructures.PlayerPerformance memory) {
        return DataStructures.PlayerPerformance({
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
    }
    
    function testUpdatePlayerPerformance() public {
        DataStructures.PlayerPerformance memory performance = _createSamplePerformance(
            1, 0, 0, 90, true, 3, 0, false, false, 1
        );
        
        vm.prank(owner);
        scoringEngine.updatePlayerPerformance(1, 1, performance);
        
        DataStructures.PlayerPerformance memory stored = scoringEngine.getPlayerPerformance(1, 1);
        assertEq(stored.playerId, 1);
        assertEq(stored.minutesPlayed, 90);
        assertTrue(stored.cleanSheet);
        assertEq(stored.saves, 3);
    }
    
    function testCalculateGoalkeeperPoints() public {
        // Goalkeeper: 90 mins, clean sheet, 6 saves, 1 bonus point
        DataStructures.PlayerPerformance memory performance = _createSamplePerformance(
            1, 0, 0, 90, true, 6, 0, false, false, 1
        );
        
        uint256 points = scoringEngine.calculatePlayerPoints(performance);
        
        // Expected: 2 (playing) + 4 (clean sheet) + 2 (6 saves = 2 points) + 1 (bonus) = 9 points
        assertEq(points, 9);
    }
    
    function testCalculateDefenderPoints() public {
        // Defender: 90 mins, 1 goal, clean sheet, 2 bonus points
        DataStructures.PlayerPerformance memory performance = _createSamplePerformance(
            3, 1, 0, 90, true, 0, 0, false, false, 2
        );
        
        uint256 points = scoringEngine.calculatePlayerPoints(performance);
        
        // Expected: 2 (playing) + 6 (goal) + 4 (clean sheet) + 2 (bonus) = 14 points
        assertEq(points, 14);
    }
    
    function testCalculateMidfielderPoints() public {
        // Midfielder: 75 mins, 1 goal, 1 assist, clean sheet
        DataStructures.PlayerPerformance memory performance = _createSamplePerformance(
            8, 1, 1, 75, true, 0, 0, false, false, 0
        );
        
        uint256 points = scoringEngine.calculatePlayerPoints(performance);
        
        // Expected: 2 (playing) + 5 (goal) + 3 (assist) + 1 (clean sheet) = 11 points
        assertEq(points, 11);
    }
    
    function testCalculateForwardPoints() public {
        // Forward: 90 mins, 2 goals, 1 assist, yellow card
        DataStructures.PlayerPerformance memory performance = _createSamplePerformance(
            13, 2, 1, 90, false, 0, -1, false, false, 3
        );
        
        uint256 points = scoringEngine.calculatePlayerPoints(performance);
        
        // Expected: 2 (playing) + 8 (2 goals × 4) + 3 (assist) - 1 (yellow) + 3 (bonus) = 15 points
        assertEq(points, 15);
    }
    
    function testCalculatePointsWithNegatives() public {
        // Player: 90 mins, own goal, penalty miss, red card
        DataStructures.PlayerPerformance memory performance = _createSamplePerformance(
            13, 0, 0, 90, false, 0, -3, true, true, 0
        );
        
        uint256 points = scoringEngine.calculatePlayerPoints(performance);
        
        // Expected: 2 (playing) - 3 (red card) - 2 (own goal) - 2 (penalty miss) = 0 points (can't go negative)
        assertEq(points, 0);
    }
    
    function testCalculatePointsPartialMinutes() public {
        // Player: 45 mins (partial playing time)
        DataStructures.PlayerPerformance memory performance = _createSamplePerformance(
            13, 1, 0, 45, false, 0, 0, false, false, 0
        );
        
        uint256 points = scoringEngine.calculatePlayerPoints(performance);
        
        // Expected: 1 (partial playing) + 4 (forward goal) = 5 points
        assertEq(points, 5);
    }
    
    function testCalculatePointsNoPlayingTime() public {
        // Player: 0 mins (didn't play)
        DataStructures.PlayerPerformance memory performance = _createSamplePerformance(
            13, 1, 1, 0, false, 0, 0, false, false, 0
        );
        
        uint256 points = scoringEngine.calculatePlayerPoints(performance);
        
        // Expected: 0 points (didn't play)
        assertEq(points, 0);
    }
    
    function testCalculateTeamScore() public {
        // Set up performances for all starting players
        vm.startPrank(owner);
        
        // Starting lineup: [0, 2, 3, 4, 5, 7, 8, 9, 10, 12, 13]
        // Players: [1, 3, 4, 5, 6, 8, 9, 10, 11, 13, 14]
        
        // GK (player 1): 90 mins, clean sheet, 3 saves
        scoringEngine.updatePlayerPerformance(1, 1, _createSamplePerformance(1, 0, 0, 90, true, 3, 0, false, false, 0));
        
        // DEF (players 3,4,5,6): 90 mins, clean sheet
        scoringEngine.updatePlayerPerformance(1, 3, _createSamplePerformance(3, 0, 0, 90, true, 0, 0, false, false, 0));
        scoringEngine.updatePlayerPerformance(1, 4, _createSamplePerformance(4, 0, 0, 90, true, 0, 0, false, false, 0));
        scoringEngine.updatePlayerPerformance(1, 5, _createSamplePerformance(5, 0, 0, 90, true, 0, 0, false, false, 0));
        scoringEngine.updatePlayerPerformance(1, 6, _createSamplePerformance(6, 0, 0, 90, true, 0, 0, false, false, 0));
        
        // MID (players 8,9,10,11): 90 mins, clean sheet
        scoringEngine.updatePlayerPerformance(1, 8, _createSamplePerformance(8, 0, 0, 90, true, 0, 0, false, false, 0));
        scoringEngine.updatePlayerPerformance(1, 9, _createSamplePerformance(9, 0, 0, 90, true, 0, 0, false, false, 0));
        scoringEngine.updatePlayerPerformance(1, 10, _createSamplePerformance(10, 0, 0, 90, true, 0, 0, false, false, 0));
        scoringEngine.updatePlayerPerformance(1, 11, _createSamplePerformance(11, 0, 0, 90, true, 0, 0, false, false, 0));
        
        // FWD (players 13,14): 90 mins, captain scores 2 goals
        scoringEngine.updatePlayerPerformance(1, 13, _createSamplePerformance(13, 2, 0, 90, false, 0, 0, false, false, 3)); // Captain
        scoringEngine.updatePlayerPerformance(1, 14, _createSamplePerformance(14, 1, 0, 90, false, 0, 0, false, false, 0));
        
        // Bench players
        scoringEngine.updatePlayerPerformance(1, 2, _createSamplePerformance(2, 0, 0, 0, false, 0, 0, false, false, 0)); // Didn't play
        scoringEngine.updatePlayerPerformance(1, 7, _createSamplePerformance(7, 0, 0, 90, true, 0, 0, false, false, 0));
        scoringEngine.updatePlayerPerformance(1, 12, _createSamplePerformance(12, 0, 0, 90, true, 0, 0, false, false, 0));
        scoringEngine.updatePlayerPerformance(1, 15, _createSamplePerformance(15, 0, 0, 90, false, 0, 0, false, false, 0));
        
        vm.stopPrank();
        
        // Calculate team score
        scoringEngine.calculateTeamScore(1, user1);
        
        DataStructures.TeamScore memory score = scoringEngine.getTeamScore(1, user1);
        assertTrue(score.isCalculated);
        assertTrue(score.totalPoints > 0);
        assertEq(score.owner, user1);
        assertEq(score.matchweek, 1);
    }
    
    function testAutoSubstitution() public {
        vm.startPrank(owner);
        
        // Set up scenario where starting GK doesn't play, but bench GK does
        scoringEngine.updatePlayerPerformance(1, 1, _createSamplePerformance(1, 0, 0, 0, false, 0, 0, false, false, 0)); // Starting GK didn't play
        scoringEngine.updatePlayerPerformance(1, 2, _createSamplePerformance(2, 0, 0, 90, true, 2, 0, false, false, 0)); // Bench GK played
        
        // Set up other players normally
        for (uint256 i = 3; i <= 15; i++) {
            if (i != 7 && i != 12 && i != 15) { // Skip bench outfield players for now
                scoringEngine.updatePlayerPerformance(1, i, _createSamplePerformance(i, 0, 0, 90, true, 0, 0, false, false, 0));
            }
        }
        
        // Bench players
        scoringEngine.updatePlayerPerformance(1, 7, _createSamplePerformance(7, 0, 0, 90, true, 0, 0, false, false, 0));
        scoringEngine.updatePlayerPerformance(1, 12, _createSamplePerformance(12, 0, 0, 90, true, 0, 0, false, false, 0));
        scoringEngine.updatePlayerPerformance(1, 15, _createSamplePerformance(15, 0, 0, 90, false, 0, 0, false, false, 0));
        
        vm.stopPrank();
        
        // Calculate team score (should trigger auto-substitution)
        scoringEngine.calculateTeamScore(1, user1);
        
        DataStructures.TeamScore memory score = scoringEngine.getTeamScore(1, user1);
        assertTrue(score.isCalculated);
    }
    
    function testCaptainDoublePoints() public {
        vm.startPrank(owner);
        
        // Set up all players with basic performance
        for (uint256 i = 1; i <= 15; i++) {
            if (i == 14) {
                // Captain (FWD2) scores 2 goals - captain is at startingLineup[10] = 13, playerIds[13] = 14
                scoringEngine.updatePlayerPerformance(1, i, _createSamplePerformance(i, 2, 0, 90, false, 0, 0, false, false, 0));
            } else {
                scoringEngine.updatePlayerPerformance(1, i, _createSamplePerformance(i, 0, 0, 90, true, 0, 0, false, false, 0));
            }
        }
        
        vm.stopPrank();
        
        scoringEngine.calculateTeamScore(1, user1);
        
        DataStructures.TeamScore memory score = scoringEngine.getTeamScore(1, user1);
        
        // Captain should get double points: 2 (playing) + 8 (2 goals × 4) = 10 points
        // Captain bonus points = 10 additional points
        assertEq(score.captainPoints, 10);
    }
    
    function testViceCaptainActivation() public {
        vm.startPrank(owner);
        
        // Set up scenario where captain doesn't play but vice-captain does
        for (uint256 i = 1; i <= 15; i++) {
            if (i == 14) {
                // Captain (FWD2) doesn't play - captain is at startingLineup[10] = 13, playerIds[13] = 14
                scoringEngine.updatePlayerPerformance(1, i, _createSamplePerformance(i, 0, 0, 0, false, 0, 0, false, false, 0));
            } else if (i == 13) {
                // Vice-captain (FWD1) plays and scores - vice-captain is at startingLineup[9] = 12, playerIds[12] = 13
                scoringEngine.updatePlayerPerformance(1, i, _createSamplePerformance(i, 1, 1, 90, true, 0, 0, false, false, 0));
            } else {
                scoringEngine.updatePlayerPerformance(1, i, _createSamplePerformance(i, 0, 0, 90, true, 0, 0, false, false, 0));
            }
        }
        
        vm.stopPrank();
        
        scoringEngine.calculateTeamScore(1, user1);
        
        DataStructures.TeamScore memory score = scoringEngine.getTeamScore(1, user1);
        
        // Vice-captain should get captain points: 2 (playing) + 4 (forward goal) + 3 (assist) = 9 points
        assertEq(score.captainPoints, 9);
    }
    
    function testCannotCalculateScoreTwice() public {
        vm.startPrank(owner);
        
        // Set up basic performances
        for (uint256 i = 1; i <= 15; i++) {
            scoringEngine.updatePlayerPerformance(1, i, _createSamplePerformance(i, 0, 0, 90, true, 0, 0, false, false, 0));
        }
        
        vm.stopPrank();
        
        // Calculate score first time
        scoringEngine.calculateTeamScore(1, user1);
        
        // Try to calculate again - should fail
        vm.expectRevert("Score already calculated");
        scoringEngine.calculateTeamScore(1, user1);
    }
    
    function testCannotUpdatePerformanceAsNonOwner() public {
        DataStructures.PlayerPerformance memory performance = _createSamplePerformance(
            1, 0, 0, 90, true, 3, 0, false, false, 1
        );
        
        vm.prank(user1);
        vm.expectRevert("Not authorized");
        scoringEngine.updatePlayerPerformance(1, 1, performance);
    }
    
    function testInvalidPlayerPerformanceData() public {
        vm.startPrank(owner);
        
        // Invalid matchweek
        vm.expectRevert("Invalid matchweek");
        scoringEngine.updatePlayerPerformance(0, 1, _createSamplePerformance(1, 0, 0, 90, true, 3, 0, false, false, 1));
        
        // Invalid player ID
        vm.expectRevert("Invalid player ID");
        scoringEngine.updatePlayerPerformance(1, 0, _createSamplePerformance(0, 0, 0, 90, true, 3, 0, false, false, 1));
        
        vm.stopPrank();
    }
    
    function testPlayerDataMismatch() public {
        vm.startPrank(owner);
        
        // Player ID mismatch
        vm.expectRevert("Player ID mismatch");
        scoringEngine.updatePlayerPerformance(1, 1, _createSamplePerformance(2, 0, 0, 90, true, 3, 0, false, false, 1));
        
        // Matchweek mismatch
        vm.expectRevert("Matchweek mismatch");
        scoringEngine.updatePlayerPerformance(1, 1, _createSamplePerformanceWithMatchweek(1, 2, 0, 0, 90, true, 3, 0, false, false, 0));
        
        vm.stopPrank();
    }
}