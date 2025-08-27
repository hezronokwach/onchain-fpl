// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/TeamManager.sol";

contract TeamManagerTest is Test {
    TeamManager public teamManager;
    
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    
    // Sample player data
    uint256[] playerIds;
    string[] playerNames;
    Position[] playerPositions;
    uint256[] playerPrices;
    uint256[] playerTeamIds;
    
    function setUp() public {
        vm.prank(owner);
        teamManager = new TeamManager();
        
        // Setup sample players (15 players for a valid team)
        _setupSamplePlayers();
        _addPlayersToContract();
        
        // Set deadline for matchweek 1
        vm.prank(owner);
        teamManager.setPoolDeadline(1, block.timestamp + 7 days);
    }
    
    function _setupSamplePlayers() internal {
        // 2 Goalkeepers
        playerIds.push(1); playerNames.push("Goalkeeper1"); playerPositions.push(Position.GK); playerPrices.push(4500000); playerTeamIds.push(1);
        playerIds.push(2); playerNames.push("Goalkeeper2"); playerPositions.push(Position.GK); playerPrices.push(4000000); playerTeamIds.push(2);
        
        // 5 Defenders
        playerIds.push(3); playerNames.push("Defender1"); playerPositions.push(Position.DEF); playerPrices.push(5500000); playerTeamIds.push(1);
        playerIds.push(4); playerNames.push("Defender2"); playerPositions.push(Position.DEF); playerPrices.push(5000000); playerTeamIds.push(2);
        playerIds.push(5); playerNames.push("Defender3"); playerPositions.push(Position.DEF); playerPrices.push(4500000); playerTeamIds.push(3);
        playerIds.push(6); playerNames.push("Defender4"); playerPositions.push(Position.DEF); playerPrices.push(4000000); playerTeamIds.push(4);
        playerIds.push(7); playerNames.push("Defender5"); playerPositions.push(Position.DEF); playerPrices.push(4000000); playerTeamIds.push(5);
        
        // 5 Midfielders
        playerIds.push(8); playerNames.push("Midfielder1"); playerPositions.push(Position.MID); playerPrices.push(7000000); playerTeamIds.push(1);
        playerIds.push(9); playerNames.push("Midfielder2"); playerPositions.push(Position.MID); playerPrices.push(6500000); playerTeamIds.push(6);
        playerIds.push(10); playerNames.push("Midfielder3"); playerPositions.push(Position.MID); playerPrices.push(6000000); playerTeamIds.push(7);
        playerIds.push(11); playerNames.push("Midfielder4"); playerPositions.push(Position.MID); playerPrices.push(5500000); playerTeamIds.push(8);
        playerIds.push(12); playerNames.push("Midfielder5"); playerPositions.push(Position.MID); playerPrices.push(5000000); playerTeamIds.push(9);
        
        // 3 Forwards
        playerIds.push(13); playerNames.push("Forward1"); playerPositions.push(Position.FWD); playerPrices.push(9000000); playerTeamIds.push(10);
        playerIds.push(14); playerNames.push("Forward2"); playerPositions.push(Position.FWD); playerPrices.push(8500000); playerTeamIds.push(11);
        playerIds.push(15); playerNames.push("Forward3"); playerPositions.push(Position.FWD); playerPrices.push(8000000); playerTeamIds.push(12);
    }
    
    function _addPlayersToContract() internal {
        vm.startPrank(owner);
        for (uint256 i = 0; i < playerIds.length; i++) {
            teamManager.addPlayer(
                playerIds[i],
                playerNames[i],
                playerPositions[i],
                playerPrices[i],
                playerTeamIds[i]
            );
        }
        vm.stopPrank();
    }
    
    function _getValidTeamData() internal pure returns (
        uint256[15] memory playerIds,
        uint256[11] memory startingLineup,
        uint256 captainIndex,
        uint256 viceCaptainIndex,
        Formation formation
    ) {
        // Valid 15 player IDs
        playerIds = [uint256(1), 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
        
        // Valid starting XI for 4-4-2 formation (GK, 4 DEF, 4 MID, 2 FWD)
        startingLineup = [uint256(0), 2, 3, 4, 5, 7, 8, 9, 10, 12, 13]; // indices in playerIds array
        
        captainIndex = 10; // Forward1
        viceCaptainIndex = 9; // Midfielder4
        formation = Formation.F_4_4_2;
    }
    
    function testAddPlayer() public {
        vm.prank(owner);
        teamManager.addPlayer(100, "TestPlayer", Position.MID, 7000000, 15);
        
        DataStructures.Player memory player = teamManager.getPlayer(100);
        assertEq(player.id, 100);
        assertEq(player.name, "TestPlayer");
        assertTrue(uint8(player.position) == uint8(Position.MID));
        assertEq(player.price, 7000000);
        assertEq(player.teamId, 15);
        assertTrue(player.isActive);
    }
    
    function testSetPoolDeadline() public {
        uint256 deadline = block.timestamp + 10 days;
        
        vm.prank(owner);
        teamManager.setPoolDeadline(2, deadline);
        
        assertEq(teamManager.poolDeadlines(2), deadline);
    }
    
    function testSubmitValidTeam() public {
        (
            uint256[15] memory playerIds,
            uint256[11] memory startingLineup,
            uint256 captainIndex,
            uint256 viceCaptainIndex,
            Formation formation
        ) = _getValidTeamData();
        
        vm.prank(user1);
        teamManager.submitTeam(1, playerIds, startingLineup, captainIndex, viceCaptainIndex, formation);
        
        DataStructures.Team memory team = teamManager.getTeam(1, user1);
        assertEq(team.owner, user1);
        assertTrue(team.isSubmitted);
        assertTrue(team.totalCost <= DataStructures.MAX_BUDGET);
        assertTrue(teamManager.hasUserSubmittedTeam(1, user1));
    }
    
    function testUpdateTeam() public {
        (
            uint256[15] memory playerIds,
            uint256[11] memory startingLineup,
            uint256 captainIndex,
            uint256 viceCaptainIndex,
            Formation formation
        ) = _getValidTeamData();
        
        // Submit initial team
        vm.prank(user1);
        teamManager.submitTeam(1, playerIds, startingLineup, captainIndex, viceCaptainIndex, formation);
        
        // Update team (change captain)
        vm.prank(user1);
        teamManager.submitTeam(1, playerIds, startingLineup, 8, viceCaptainIndex, formation);
        
        DataStructures.Team memory team = teamManager.getTeam(1, user1);
        assertEq(team.captainIndex, 8);
    }
    
    function testCannotSubmitAfterDeadline() public {
        (
            uint256[15] memory playerIds,
            uint256[11] memory startingLineup,
            uint256 captainIndex,
            uint256 viceCaptainIndex,
            Formation formation
        ) = _getValidTeamData();
        
        // Fast forward past deadline
        vm.warp(block.timestamp + 8 days);
        
        vm.prank(user1);
        vm.expectRevert("Deadline passed");
        teamManager.submitTeam(1, playerIds, startingLineup, captainIndex, viceCaptainIndex, formation);
    }
    
    function testCannotSubmitDuplicatePlayers() public {
        uint256[15] memory duplicatePlayerIds = [uint256(1), 1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; // Duplicate player 1
        uint256[11] memory startingLineup = [uint256(0), 2, 3, 4, 5, 7, 8, 9, 10, 12, 13];
        
        vm.prank(user1);
        vm.expectRevert("Duplicate player");
        teamManager.submitTeam(1, duplicatePlayerIds, startingLineup, 0, 1, Formation.F_4_4_2);
    }
    
    function testCannotExceedBudget() public {
        // Add expensive players that exceed budget
        vm.startPrank(owner);
        for (uint256 i = 16; i <= 30; i++) {
            teamManager.addPlayer(i, "ExpensivePlayer", Position.FWD, 15000000, 20); // £15M each
        }
        vm.stopPrank();
        
        uint256[15] memory expensivePlayerIds = [uint256(16), 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30];
        uint256[11] memory startingLineup = [uint256(0), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        
        vm.prank(user1);
        vm.expectRevert("Exceeds budget limit");
        teamManager.submitTeam(1, expensivePlayerIds, startingLineup, 0, 1, Formation.F_4_4_2);
    }
    
    function testCannotHaveTooManyPlayersFromSameTeam() public {
        // Add 4 players from same team
        vm.startPrank(owner);
        teamManager.addPlayer(16, "SameTeam1", Position.DEF, 4000000, 1);
        teamManager.addPlayer(17, "SameTeam2", Position.MID, 4000000, 1);
        vm.stopPrank();
        
        uint256[15] memory teamPlayerIds = [uint256(1), 2, 3, 8, 16, 17, 7, 9, 10, 11, 12, 13, 14, 15, 6]; // 4 players from team 1
        uint256[11] memory startingLineup = [uint256(0), 2, 3, 4, 5, 7, 8, 9, 10, 12, 13];
        
        vm.prank(user1);
        vm.expectRevert("Must have exactly 5 defenders");
        teamManager.submitTeam(1, teamPlayerIds, startingLineup, 0, 1, Formation.F_4_4_2);
    }
    
    function testCannotHaveInvalidSquadComposition() public {
        // Try with 3 goalkeepers instead of 2
        vm.startPrank(owner);
        teamManager.addPlayer(16, "ExtraGK", Position.GK, 4000000, 13);
        vm.stopPrank();
        
        uint256[15] memory squadPlayerIds = [uint256(1), 2, 16, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; // 3 GKs
        uint256[11] memory startingLineup = [uint256(0), 3, 4, 5, 6, 7, 8, 9, 10, 12, 13];
        
        vm.prank(user1);
        vm.expectRevert("Must have exactly 2 goalkeepers");
        teamManager.submitTeam(1, squadPlayerIds, startingLineup, 0, 1, Formation.F_4_4_2);
    }
    
    function testCannotHaveInvalidFormation() public {
        (
            uint256[15] memory playerIds,
            uint256[11] memory startingLineup,
            uint256 captainIndex,
            uint256 viceCaptainIndex,
        ) = _getValidTeamData();
        
        // Try with invalid starting lineup for 3-4-3 formation
        vm.prank(user1);
        vm.expectRevert("Invalid defender count in starting XI");
        teamManager.submitTeam(1, playerIds, startingLineup, captainIndex, viceCaptainIndex, Formation.F_3_4_3);
    }
    
    function testCannotHaveSameCaptainAndViceCaptain() public {
        (
            uint256[15] memory playerIds,
            uint256[11] memory startingLineup,
            ,
            ,
            Formation formation
        ) = _getValidTeamData();
        
        vm.prank(user1);
        vm.expectRevert("Captain and vice-captain must be different");
        teamManager.submitTeam(1, playerIds, startingLineup, 5, 5, formation); // Same index
    }
    
    function testCannotAddPlayerAsNonOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        teamManager.addPlayer(100, "TestPlayer", Position.MID, 7000000, 15);
    }
    
    function testCannotSetDeadlineAsNonOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        teamManager.setPoolDeadline(2, block.timestamp + 7 days);
    }
    
    function testCannotAddDuplicatePlayer() public {
        vm.prank(owner);
        vm.expectRevert("Player already exists");
        teamManager.addPlayer(1, "DuplicatePlayer", Position.MID, 7000000, 15);
    }
    
    function testInvalidPlayerData() public {
        vm.startPrank(owner);
        
        // Invalid player ID
        vm.expectRevert("Invalid player ID");
        teamManager.addPlayer(0, "TestPlayer", Position.MID, 7000000, 15);
        
        // Invalid name
        vm.expectRevert("Invalid name");
        teamManager.addPlayer(100, "", Position.MID, 7000000, 15);
        
        // Invalid price
        vm.expectRevert("Invalid price");
        teamManager.addPlayer(100, "TestPlayer", Position.MID, 0, 15);
        
        // Invalid team ID
        vm.expectRevert("Invalid team ID");
        teamManager.addPlayer(100, "TestPlayer", Position.MID, 7000000, 0);
        
        vm.stopPrank();
    }
}