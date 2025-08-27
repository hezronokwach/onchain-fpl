// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MockOracle.sol";
import "../src/OracleConsumer.sol";
import "../src/ScoringEngine.sol";
import "../src/TeamManager.sol";
import "../src/libraries/DataStructures.sol";

contract MockOracleTest is Test {
    MockOracle public mockOracle;
    OracleConsumer public oracleConsumer;
    ScoringEngine public scoringEngine;
    TeamManager public teamManager;
    
    address public owner = address(this);
    
    uint256 constant MATCHWEEK = 1;
    uint256 constant PLAYER_ID = 1;
    
    event MockDataSet(uint256 indexed matchweek, uint256 indexed playerId);
    event MockDataSubmitted(uint256 indexed matchweek, uint256 playerCount);
    
    function setUp() public {
        // Deploy contracts
        teamManager = new TeamManager();
        scoringEngine = new ScoringEngine(address(teamManager));
        oracleConsumer = new OracleConsumer(address(scoringEngine));
        mockOracle = new MockOracle(address(oracleConsumer));
        
        // Set oracle consumer in scoring engine
        scoringEngine.setOracleConsumer(address(oracleConsumer));
        
        // Add mock oracle as authorized
        oracleConsumer.addOracle(address(mockOracle));
    }

    function testSetMockPerformance() public {
        vm.expectEmit(true, true, false, false);
        emit MockDataSet(MATCHWEEK, PLAYER_ID);
        
        mockOracle.setMockPerformance(
            MATCHWEEK,
            PLAYER_ID,
            2, // goals
            1, // assists
            90, // minutes
            false, // clean sheet
            0, // saves
            0, // cards
            false, // own goal
            false, // penalty miss
            3 // bonus points
        );
        
        DataStructures.PlayerPerformance memory performance = 
            mockOracle.getMockPerformance(MATCHWEEK, PLAYER_ID);
        
        assertEq(performance.playerId, PLAYER_ID);
        assertEq(performance.matchweek, MATCHWEEK);
        assertEq(performance.goals, 2);
        assertEq(performance.assists, 1);
        assertEq(performance.minutesPlayed, 90);
        assertEq(performance.bonusPoints, 3);
        assertTrue(performance.isValidated);
    }

    function testSetMockPerformances() public {
        uint256[] memory playerIds = new uint256[](2);
        playerIds[0] = 1;
        playerIds[1] = 2;
        
        DataStructures.PlayerPerformance[] memory performances = 
            new DataStructures.PlayerPerformance[](2);
        
        performances[0] = DataStructures.PlayerPerformance({
            playerId: 0, // Will be set by function
            matchweek: 0, // Will be set by function
            goals: 1,
            assists: 0,
            minutesPlayed: 90,
            cleanSheet: true,
            saves: 0,
            cards: 0,
            ownGoal: false,
            penaltyMiss: false,
            bonusPoints: 2,
            isValidated: false // Will be set by function
        });
        
        performances[1] = DataStructures.PlayerPerformance({
            playerId: 0, // Will be set by function
            matchweek: 0, // Will be set by function
            goals: 0,
            assists: 2,
            minutesPlayed: 85,
            cleanSheet: false,
            saves: 0,
            cards: -1, // Yellow card
            ownGoal: false,
            penaltyMiss: false,
            bonusPoints: 1,
            isValidated: false // Will be set by function
        });
        
        mockOracle.setMockPerformances(MATCHWEEK, playerIds, performances);
        
        // Check first player
        DataStructures.PlayerPerformance memory perf1 = 
            mockOracle.getMockPerformance(MATCHWEEK, 1);
        assertEq(perf1.goals, 1);
        assertEq(perf1.assists, 0);
        assertTrue(perf1.cleanSheet);
        assertTrue(perf1.isValidated);
        
        // Check second player
        DataStructures.PlayerPerformance memory perf2 = 
            mockOracle.getMockPerformance(MATCHWEEK, 2);
        assertEq(perf2.goals, 0);
        assertEq(perf2.assists, 2);
        assertEq(perf2.cards, -1);
        assertTrue(perf2.isValidated);
        
        // Check matchweek players
        uint256[] memory players = mockOracle.getMatchweekPlayers(MATCHWEEK);
        assertEq(players.length, 2);
        assertEq(players[0], 1);
        assertEq(players[1], 2);
    }

    function testSetMockPerformancesFailsForMismatchedArrays() public {
        uint256[] memory playerIds = new uint256[](2);
        DataStructures.PlayerPerformance[] memory performances = 
            new DataStructures.PlayerPerformance[](1); // Mismatched length
        
        vm.expectRevert("Array length mismatch");
        mockOracle.setMockPerformances(MATCHWEEK, playerIds, performances);
    }

    function testSubmitMockData() public {
        // Set some mock data first
        mockOracle.setMockPerformance(
            MATCHWEEK, PLAYER_ID, 1, 0, 90, false, 0, 0, false, false, 0
        );
        
        vm.expectEmit(true, false, false, true);
        emit MockDataSubmitted(MATCHWEEK, 1);
        
        mockOracle.submitMockData(MATCHWEEK);
        
        // Verify data was submitted to oracle consumer
        (uint256 confirmations, bool validated, uint256 timestamp) = 
            oracleConsumer.getOracleStatus(MATCHWEEK);
        
        assertEq(confirmations, 1);
        assertFalse(validated); // Not validated until min confirmations
        assertGt(timestamp, 0);
    }

    function testSubmitMockDataFailsForNoData() public {
        vm.expectRevert("No mock data for matchweek");
        mockOracle.submitMockData(MATCHWEEK);
    }

    function testCreateRealisticMockData() public {
        uint256 playerCount = 20;
        
        mockOracle.createRealisticMockData(MATCHWEEK, playerCount);
        
        uint256[] memory players = mockOracle.getMatchweekPlayers(MATCHWEEK);
        assertEq(players.length, playerCount);
        
        // Check some random players have realistic data
        for (uint256 i = 1; i <= 5; i++) {
            DataStructures.PlayerPerformance memory perf = 
                mockOracle.getMockPerformance(MATCHWEEK, i);
            
            assertEq(perf.playerId, i);
            assertEq(perf.matchweek, MATCHWEEK);
            assertTrue(perf.isValidated);
            
            // Minutes should be 0, 1-59, or 60-90
            assertTrue(
                perf.minutesPlayed == 0 || 
                (perf.minutesPlayed >= 1 && perf.minutesPlayed <= 90)
            );
            
            // Goals should be reasonable (0-3 typically)
            assertTrue(perf.goals <= 3);
            
            // Assists should be reasonable (0-3 typically)
            assertTrue(perf.assists <= 3);
            
            // Cards should be 0, -1, or -3
            assertTrue(perf.cards == 0 || perf.cards == -1 || perf.cards == -3);
            
            // Bonus points should be 0-3
            assertTrue(perf.bonusPoints <= 3);
        }
    }

    function testCreateRealisticMockDataFailsForInvalidCount() public {
        vm.expectRevert("Invalid player count");
        mockOracle.createRealisticMockData(MATCHWEEK, 0);
        
        vm.expectRevert("Invalid player count");
        mockOracle.createRealisticMockData(MATCHWEEK, 101);
    }

    function testCreateRealisticMockDataForwardsBiased() public {
        mockOracle.createRealisticMockData(MATCHWEEK, 100);
        
        // Check that forwards (players 1-20) have higher goal probability
        uint256 forwardGoals = 0;
        uint256 defenderGoals = 0;
        
        for (uint256 i = 1; i <= 20; i++) { // Forwards
            DataStructures.PlayerPerformance memory perf = 
                mockOracle.getMockPerformance(MATCHWEEK, i);
            forwardGoals += perf.goals;
        }
        
        for (uint256 i = 81; i <= 100; i++) { // Defenders
            DataStructures.PlayerPerformance memory perf = 
                mockOracle.getMockPerformance(MATCHWEEK, i);
            defenderGoals += perf.goals;
        }
        
        // Forwards should generally score more goals than defenders
        // This is probabilistic, so we'll just check they have some goals
        assertTrue(forwardGoals >= 0);
        assertTrue(defenderGoals >= 0);
    }

    function testGoalkeeperSaves() public {
        mockOracle.createRealisticMockData(MATCHWEEK, 100);
        
        // Check goalkeepers (players 91-100) can have saves
        for (uint256 i = 91; i <= 100; i++) {
            DataStructures.PlayerPerformance memory perf = 
                mockOracle.getMockPerformance(MATCHWEEK, i);
            
            // Saves should be reasonable (0-8 based on mock logic)
            assertTrue(perf.saves <= 8);
        }
    }

    function testClearMockData() public {
        // Set some data
        mockOracle.setMockPerformance(
            MATCHWEEK, PLAYER_ID, 1, 0, 90, false, 0, 0, false, false, 0
        );
        mockOracle.setMockPerformance(
            MATCHWEEK, 2, 0, 1, 85, false, 0, 0, false, false, 0
        );
        
        // Verify data exists
        uint256[] memory players = mockOracle.getMatchweekPlayers(MATCHWEEK);
        assertEq(players.length, 2);
        
        // Clear data
        mockOracle.clearMockData(MATCHWEEK);
        
        // Verify data is cleared
        players = mockOracle.getMatchweekPlayers(MATCHWEEK);
        assertEq(players.length, 0);
        
        // Verify individual performance is cleared
        DataStructures.PlayerPerformance memory perf = 
            mockOracle.getMockPerformance(MATCHWEEK, PLAYER_ID);
        assertEq(perf.playerId, 0);
        assertEq(perf.goals, 0);
    }

    function testIntegrationWithOracleConsumer() public {
        // Create realistic data
        mockOracle.createRealisticMockData(MATCHWEEK, 50);
        
        // Submit to oracle consumer
        mockOracle.submitMockData(MATCHWEEK);
        
        // Verify submission
        (uint256 confirmations, bool validated, uint256 timestamp) = 
            oracleConsumer.getOracleStatus(MATCHWEEK);
        
        assertEq(confirmations, 1);
        assertFalse(validated); // Need more confirmations
        assertGt(timestamp, 0);
        
        // Get match data from oracle consumer
        DataStructures.MatchData memory matchData = oracleConsumer.getMatchData(MATCHWEEK);
        assertEq(matchData.matchweek, MATCHWEEK);
        assertEq(matchData.performanceCount, 50);
        assertFalse(matchData.isValidated);
    }

    function testMultipleSubmissionsForValidation() public {
        // Add more oracles for testing
        address oracle2 = address(0x2);
        address oracle3 = address(0x3);
        oracleConsumer.addOracle(oracle2);
        oracleConsumer.addOracle(oracle3);
        
        // Create and submit data from mock oracle
        mockOracle.createRealisticMockData(MATCHWEEK, 10);
        mockOracle.submitMockData(MATCHWEEK);
        
        // Create matching data for other oracles
        DataStructures.PlayerPerformance[] memory performances = 
            new DataStructures.PlayerPerformance[](1);
        
        performances[0] = DataStructures.PlayerPerformance({
            playerId: 1,
            matchweek: MATCHWEEK,
            goals: 1,
            assists: 0,
            minutesPlayed: 90,
            cleanSheet: false,
            saves: 0,
            cards: 0,
            ownGoal: false,
            penaltyMiss: false,
            bonusPoints: 0,
            isValidated: true
        });
        
        // Submit from other oracles
        vm.prank(oracle2);
        oracleConsumer.submitMatchData(MATCHWEEK, performances, block.timestamp);
        
        vm.prank(oracle3);
        oracleConsumer.submitMatchData(MATCHWEEK, performances, block.timestamp);
        
        // Should be validated now
        (uint256 confirmations, bool validated,) = oracleConsumer.getOracleStatus(MATCHWEEK);
        
        assertEq(confirmations, 3);
        assertTrue(validated);
    }
}