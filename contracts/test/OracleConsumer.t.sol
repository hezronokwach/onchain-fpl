// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/OracleConsumer.sol";
import "../src/ScoringEngine.sol";
import "../src/TeamManager.sol";
import "../src/MockOracle.sol";
import "../src/libraries/DataStructures.sol";

contract OracleConsumerTest is Test {
    OracleConsumer public oracleConsumer;
    ScoringEngine public scoringEngine;
    TeamManager public teamManager;
    MockOracle public mockOracle;
    
    address public owner = address(this);
    address public oracle1 = address(0x1);
    address public oracle2 = address(0x2);
    address public oracle3 = address(0x3);
    address public user1 = address(0x4);
    
    uint256 constant MATCHWEEK = 1;
    uint256 constant PLAYER_ID = 1;
    
    event OracleAdded(address indexed oracle);
    event OracleRemoved(address indexed oracle);
    event OracleDataRequested(uint256 indexed matchweek, bytes32 indexed requestId);
    event OracleDataReceived(uint256 indexed matchweek, address indexed oracle, uint256 playerCount);
    event MatchDataValidated(uint256 indexed matchweek, uint256 timestamp);
    event EmergencyModeToggled(bool enabled);
    event AutoScoringTriggered(uint256 indexed matchweek);
    
    function setUp() public {
        // Deploy contracts
        teamManager = new TeamManager();
        scoringEngine = new ScoringEngine(address(teamManager));
        oracleConsumer = new OracleConsumer(address(scoringEngine));
        mockOracle = new MockOracle(address(oracleConsumer));
        
        // Set oracle consumer in scoring engine
        scoringEngine.setOracleConsumer(address(oracleConsumer));
        
        // Add authorized oracles
        oracleConsumer.addOracle(oracle1);
        oracleConsumer.addOracle(oracle2);
        oracleConsumer.addOracle(oracle3);
        oracleConsumer.addOracle(address(mockOracle));
    }

    function testAddOracle() public {
        address newOracle = address(0x5);
        
        vm.expectEmit(true, false, false, false);
        emit OracleAdded(newOracle);
        
        oracleConsumer.addOracle(newOracle);
        
        assertTrue(oracleConsumer.isAuthorizedOracle(newOracle));
    }

    function testAddOracleFailsForNonOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        oracleConsumer.addOracle(address(0x5));
    }

    function testAddOracleFailsForZeroAddress() public {
        vm.expectRevert("Invalid oracle address");
        oracleConsumer.addOracle(address(0));
    }

    function testAddOracleFailsForDuplicate() public {
        vm.expectRevert("Oracle already authorized");
        oracleConsumer.addOracle(oracle1);
    }

    function testRemoveOracle() public {
        vm.expectEmit(true, false, false, false);
        emit OracleRemoved(oracle1);
        
        oracleConsumer.removeOracle(oracle1);
        
        assertFalse(oracleConsumer.isAuthorizedOracle(oracle1));
    }

    function testRemoveOracleFailsForNonOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        oracleConsumer.removeOracle(oracle1);
    }

    function testRemoveOracleFailsForUnauthorized() public {
        vm.expectRevert("Oracle not authorized");
        oracleConsumer.removeOracle(address(0x5));
    }

    function testRequestMatchData() public {
        vm.expectEmit(true, false, false, false);
        emit OracleDataRequested(MATCHWEEK, bytes32(0));
        
        oracleConsumer.requestMatchData(MATCHWEEK);
    }

    function testRequestMatchDataFailsForInvalidMatchweek() public {
        vm.expectRevert("Invalid matchweek");
        oracleConsumer.requestMatchData(0);
        
        vm.expectRevert("Invalid matchweek");
        oracleConsumer.requestMatchData(39);
    }

    function testRequestMatchDataFailsInEmergencyMode() public {
        oracleConsumer.toggleEmergencyMode(true);
        
        vm.expectRevert("Emergency mode active");
        oracleConsumer.requestMatchData(MATCHWEEK);
    }

    function testSubmitMatchData() public {
        DataStructures.PlayerPerformance[] memory performances = 
            new DataStructures.PlayerPerformance[](1);
        
        performances[0] = DataStructures.PlayerPerformance({
            playerId: PLAYER_ID,
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
        
        vm.prank(oracle1);
        vm.expectEmit(true, true, false, false);
        emit OracleDataReceived(MATCHWEEK, oracle1, 1);
        
        oracleConsumer.submitMatchData(MATCHWEEK, performances, block.timestamp);
        
        (uint256 confirmations, bool validated, uint256 timestamp) = 
            oracleConsumer.getOracleStatus(MATCHWEEK);
        
        assertEq(confirmations, 1);
        assertFalse(validated); // Not validated until min confirmations
        assertEq(timestamp, block.timestamp);
    }

    function testSubmitMatchDataFailsForUnauthorized() public {
        DataStructures.PlayerPerformance[] memory performances = 
            new DataStructures.PlayerPerformance[](1);
        
        vm.prank(user1);
        vm.expectRevert("Not authorized oracle");
        oracleConsumer.submitMatchData(MATCHWEEK, performances, block.timestamp);
    }

    function testSubmitMatchDataFailsForInvalidMatchweek() public {
        DataStructures.PlayerPerformance[] memory performances = 
            new DataStructures.PlayerPerformance[](1);
        
        vm.prank(oracle1);
        vm.expectRevert("Invalid matchweek");
        oracleConsumer.submitMatchData(0, performances, block.timestamp);
    }

    function testSubmitMatchDataFailsForEmptyPerformances() public {
        DataStructures.PlayerPerformance[] memory performances = 
            new DataStructures.PlayerPerformance[](0);
        
        vm.prank(oracle1);
        vm.expectRevert("No performance data");
        oracleConsumer.submitMatchData(MATCHWEEK, performances, block.timestamp);
    }

    function testSubmitMatchDataFailsForOldTimestamp() public {
        DataStructures.PlayerPerformance[] memory performances = 
            new DataStructures.PlayerPerformance[](1);
        
        performances[0] = DataStructures.PlayerPerformance({
            playerId: PLAYER_ID,
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
        
        // Set a timestamp that's too old
        vm.warp(10000); // Set current time to 10000
        
        vm.prank(oracle1);
        vm.expectRevert("Invalid timestamp");
        oracleConsumer.submitMatchData(MATCHWEEK, performances, 1000); // Much older timestamp
    }

    function testSubmitMatchDataFailsForDuplicateOracle() public {
        DataStructures.PlayerPerformance[] memory performances = 
            new DataStructures.PlayerPerformance[](1);
        
        performances[0] = DataStructures.PlayerPerformance({
            playerId: PLAYER_ID,
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
        
        vm.prank(oracle1);
        oracleConsumer.submitMatchData(MATCHWEEK, performances, block.timestamp);
        
        vm.prank(oracle1);
        vm.expectRevert("Oracle already submitted");
        oracleConsumer.submitMatchData(MATCHWEEK, performances, block.timestamp);
    }

    function testAutoValidationWithMinConfirmations() public {
        DataStructures.PlayerPerformance[] memory performances = 
            new DataStructures.PlayerPerformance[](1);
        
        performances[0] = DataStructures.PlayerPerformance({
            playerId: PLAYER_ID,
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
        
        // Submit from 3 oracles to reach minimum confirmations
        vm.prank(oracle1);
        oracleConsumer.submitMatchData(MATCHWEEK, performances, block.timestamp);
        
        vm.prank(oracle2);
        oracleConsumer.submitMatchData(MATCHWEEK, performances, block.timestamp);
        
        vm.prank(oracle3);
        vm.expectEmit(true, false, false, false);
        emit MatchDataValidated(MATCHWEEK, block.timestamp);
        
        oracleConsumer.submitMatchData(MATCHWEEK, performances, block.timestamp);
        
        (uint256 confirmations, bool validated,) = oracleConsumer.getOracleStatus(MATCHWEEK);
        
        assertEq(confirmations, 3);
        assertTrue(validated);
    }

    function testSubmitManualData() public {
        oracleConsumer.toggleEmergencyMode(true);
        
        DataStructures.PlayerPerformance[] memory performances = 
            new DataStructures.PlayerPerformance[](1);
        
        performances[0] = DataStructures.PlayerPerformance({
            playerId: PLAYER_ID,
            matchweek: MATCHWEEK,
            goals: 2,
            assists: 1,
            minutesPlayed: 90,
            cleanSheet: false,
            saves: 0,
            cards: 0,
            ownGoal: false,
            penaltyMiss: false,
            bonusPoints: 3,
            isValidated: true
        });
        
        vm.expectEmit(true, false, false, false);
        emit MatchDataValidated(MATCHWEEK, block.timestamp);
        
        oracleConsumer.submitManualData(MATCHWEEK, performances);
        
        DataStructures.MatchData memory matchData = oracleConsumer.getMatchData(MATCHWEEK);
        assertTrue(matchData.isValidated);
        assertEq(matchData.performanceCount, 1);
        
        DataStructures.PlayerPerformance memory perf = oracleConsumer.getPlayerPerformance(MATCHWEEK, PLAYER_ID);
        assertEq(perf.goals, 2);
    }

    function testSubmitManualDataFailsWhenNotAllowed() public {
        DataStructures.PlayerPerformance[] memory performances = 
            new DataStructures.PlayerPerformance[](1);
        
        vm.expectRevert("Manual submission not allowed");
        oracleConsumer.submitManualData(MATCHWEEK, performances);
    }

    function testToggleEmergencyMode() public {
        vm.expectEmit(false, false, false, true);
        emit EmergencyModeToggled(true);
        
        oracleConsumer.toggleEmergencyMode(true);
        
        // Should fail to request data in emergency mode
        vm.expectRevert("Emergency mode active");
        oracleConsumer.requestMatchData(MATCHWEEK);
        
        // Toggle back
        oracleConsumer.toggleEmergencyMode(false);
        
        // Should work again
        oracleConsumer.requestMatchData(MATCHWEEK);
    }

    function testSetManualOverride() public {
        oracleConsumer.setManualOverride(MATCHWEEK, true);
        
        DataStructures.PlayerPerformance[] memory performances = 
            new DataStructures.PlayerPerformance[](1);
        
        performances[0] = DataStructures.PlayerPerformance({
            playerId: PLAYER_ID,
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
        
        // Should work with manual override even without emergency mode
        oracleConsumer.submitManualData(MATCHWEEK, performances);
        
        DataStructures.MatchData memory matchData = oracleConsumer.getMatchData(MATCHWEEK);
        assertTrue(matchData.isValidated);
    }

    function testUpdateOracleConfig() public {
        oracleConsumer.updateOracleConfig(2, 7200, 14400);
        
        // Test with new min confirmations (2 instead of 3)
        DataStructures.PlayerPerformance[] memory performances = 
            new DataStructures.PlayerPerformance[](1);
        
        performances[0] = DataStructures.PlayerPerformance({
            playerId: PLAYER_ID,
            matchweek: 2,
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
        
        vm.prank(oracle1);
        oracleConsumer.submitMatchData(2, performances, block.timestamp);
        
        vm.prank(oracle2);
        vm.expectEmit(true, false, false, false);
        emit MatchDataValidated(2, block.timestamp);
        
        oracleConsumer.submitMatchData(2, performances, block.timestamp);
        
        (uint256 confirmations, bool validated,) = oracleConsumer.getOracleStatus(2);
        
        assertEq(confirmations, 2);
        assertTrue(validated); // Should be validated with 2 confirmations now
    }

    function testUpdateOracleConfigFailsForInvalidValues() public {
        vm.expectRevert("Invalid confirmations");
        oracleConsumer.updateOracleConfig(0, 3600, 7200);
        
        vm.expectRevert("Invalid confirmations");
        oracleConsumer.updateOracleConfig(10, 3600, 7200); // More than available oracles
        
        vm.expectRevert("Invalid timeout");
        oracleConsumer.updateOracleConfig(3, 0, 7200);
        
        vm.expectRevert("Invalid max age");
        oracleConsumer.updateOracleConfig(3, 3600, 0);
    }

    function testGetAuthorizedOracles() public {
        address[] memory oracles = oracleConsumer.getAuthorizedOracles();
        
        assertEq(oracles.length, 4);
        assertEq(oracles[0], oracle1);
        assertEq(oracles[1], oracle2);
        assertEq(oracles[2], oracle3);
        assertEq(oracles[3], address(mockOracle));
    }

    function testTriggerAutoScoring() public {
        // First validate some data
        DataStructures.PlayerPerformance[] memory performances = 
            new DataStructures.PlayerPerformance[](1);
        
        performances[0] = DataStructures.PlayerPerformance({
            playerId: PLAYER_ID,
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
        
        // Submit from 3 oracles to validate
        vm.prank(oracle1);
        oracleConsumer.submitMatchData(MATCHWEEK, performances, block.timestamp);
        vm.prank(oracle2);
        oracleConsumer.submitMatchData(MATCHWEEK, performances, block.timestamp);
        vm.prank(oracle3);
        oracleConsumer.submitMatchData(MATCHWEEK, performances, block.timestamp);
        
        // Fast forward time
        vm.warp(block.timestamp + 3601); // 1 hour + 1 second
        
        vm.expectEmit(true, false, false, false);
        emit AutoScoringTriggered(MATCHWEEK);
        
        oracleConsumer.triggerAutoScoring(MATCHWEEK);
    }

    function testTriggerAutoScoringFailsForUnvalidatedData() public {
        vm.expectRevert("Data not validated");
        oracleConsumer.triggerAutoScoring(MATCHWEEK);
    }

    function testTriggerAutoScoringFailsTooEarly() public {
        // Validate data first
        oracleConsumer.toggleEmergencyMode(true);
        
        DataStructures.PlayerPerformance[] memory performances = 
            new DataStructures.PlayerPerformance[](1);
        
        performances[0] = DataStructures.PlayerPerformance({
            playerId: PLAYER_ID,
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
        
        oracleConsumer.submitManualData(MATCHWEEK, performances);
        
        // Try to trigger immediately
        vm.expectRevert("Too early for scoring");
        oracleConsumer.triggerAutoScoring(MATCHWEEK);
    }
}