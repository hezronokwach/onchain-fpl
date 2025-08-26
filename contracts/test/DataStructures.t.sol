// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/libraries/DataStructures.sol";
import "../src/libraries/ValidationLibrary.sol";
import "../src/libraries/Enums.sol";

contract DataStructuresTest is Test {
    using ValidationLibrary for *;
    
    function testFormationValidation() public {
        // Test valid formations
        assertTrue(ValidationLibrary.isValidFormation(Formation.F_4_3_3));
        assertTrue(ValidationLibrary.isValidFormation(Formation.F_3_4_3));
        assertTrue(ValidationLibrary.isValidFormation(Formation.F_5_4_1));
        
        // Test formation counts
        DataStructures.FormationCount memory counts = ValidationLibrary.getFormationCounts(Formation.F_4_3_3);
        assertEq(counts.goalkeepers, 1);
        assertEq(counts.defenders, 4);
        assertEq(counts.midfielders, 3);
        assertEq(counts.forwards, 3);
    }
    
    function testMatchweekValidation() public {
        // Valid matchweeks
        assertTrue(ValidationLibrary.isValidMatchweek(1));
        assertTrue(ValidationLibrary.isValidMatchweek(38));
        assertTrue(ValidationLibrary.isValidMatchweek(20));
        
        // Invalid matchweeks
        assertFalse(ValidationLibrary.isValidMatchweek(0));
        assertFalse(ValidationLibrary.isValidMatchweek(39));
        assertFalse(ValidationLibrary.isValidMatchweek(100));
    }
    
    function testDeadlineValidation() public {
        // Future deadline should be valid
        assertTrue(ValidationLibrary.isValidDeadline(block.timestamp + 3600));
        
        // Past deadline should be invalid
        assertFalse(ValidationLibrary.isValidDeadline(block.timestamp - 1));
        
        // Current timestamp should be invalid
        assertFalse(ValidationLibrary.isValidDeadline(block.timestamp));
    }
    
    function testPositionValidation() public {
        // Valid positions
        assertTrue(ValidationLibrary.isValidPosition(Position.GK));
        assertTrue(ValidationLibrary.isValidPosition(Position.DEF));
        assertTrue(ValidationLibrary.isValidPosition(Position.MID));
        assertTrue(ValidationLibrary.isValidPosition(Position.FWD));
    }
    
    function testTeamIdValidation() public {
        // Valid team IDs
        assertTrue(ValidationLibrary.isValidTeamId(1));
        assertTrue(ValidationLibrary.isValidTeamId(20));
        assertTrue(ValidationLibrary.isValidTeamId(10));
        
        // Invalid team IDs
        assertFalse(ValidationLibrary.isValidTeamId(0));
        assertFalse(ValidationLibrary.isValidTeamId(21));
        assertFalse(ValidationLibrary.isValidTeamId(100));
    }
    
    function testPriceValidation() public {
        // Valid prices
        assertTrue(ValidationLibrary.isValidPrice(4_000_000)); // £4M
        assertTrue(ValidationLibrary.isValidPrice(12_500_000)); // £12.5M
        assertTrue(ValidationLibrary.isValidPrice(15_000_000)); // £15M max
        
        // Invalid prices
        assertFalse(ValidationLibrary.isValidPrice(0));
        assertFalse(ValidationLibrary.isValidPrice(15_000_001)); // Over £15M
        assertFalse(ValidationLibrary.isValidPrice(20_000_000)); // Way over limit
    }
    
    function testConstants() public {
        // Test FPL constants
        assertEq(DataStructures.MAX_BUDGET, 100_000_000); // £100M
        assertEq(DataStructures.SQUAD_SIZE, 15);
        assertEq(DataStructures.STARTING_XI, 11);
        assertEq(DataStructures.MAX_PLAYERS_PER_TEAM, 3);
        assertEq(DataStructures.TOTAL_EPL_TEAMS, 20);
        assertEq(DataStructures.MAX_MATCHWEEKS, 38);
        
        // Test scoring constants
        assertEq(DataStructures.GOAL_POINTS_GK_DEF, 6);
        assertEq(DataStructures.GOAL_POINTS_MID, 5);
        assertEq(DataStructures.GOAL_POINTS_FWD, 4);
        assertEq(DataStructures.ASSIST_POINTS, 3);
        assertEq(DataStructures.CLEAN_SHEET_GK_DEF, 4);
        assertEq(DataStructures.CLEAN_SHEET_MID, 1);
    }
    
    function testPlayerStruct() public {
        DataStructures.Player memory player = DataStructures.Player({
            id: 1,
            name: "Mohamed Salah",
            position: Position.FWD,
            price: 12_500_000, // £12.5M
            teamId: 1, // Liverpool
            isActive: true
        });
        
        assertEq(player.id, 1);
        assertEq(player.price, 12_500_000);
        assertTrue(player.isActive);
        assertEq(uint8(player.position), uint8(Position.FWD));
    }
    
    function testTeamStruct() public {
        uint256[15] memory playerIds;
        uint256[11] memory startingLineup;
        
        // Fill with sample data
        for (uint i = 0; i < 15; i++) {
            playerIds[i] = i + 1;
        }
        for (uint i = 0; i < 11; i++) {
            startingLineup[i] = i;
        }
        
        DataStructures.Team memory team = DataStructures.Team({
            owner: address(0x123),
            playerIds: playerIds,
            startingLineup: startingLineup,
            captainIndex: 0,
            viceCaptainIndex: 1,
            formation: Formation.F_4_3_3,
            totalCost: 100_000_000,
            isSubmitted: true,
            submissionTime: block.timestamp
        });
        
        assertEq(team.owner, address(0x123));
        assertEq(team.totalCost, 100_000_000);
        assertTrue(team.isSubmitted);
        assertEq(uint8(team.formation), uint8(Formation.F_4_3_3));
    }
}