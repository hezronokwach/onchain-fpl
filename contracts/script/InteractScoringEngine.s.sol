// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/ScoringEngine.sol";

contract InteractScoringEngine is Script {
    ScoringEngine constant SCORING_ENGINE = ScoringEngine(0x5FbDB2315678afecb367f032d93F642f64180aa3); // Replace with actual address
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Example: Update player performance
        DataStructures.PlayerPerformance memory performance = DataStructures.PlayerPerformance({
            playerId: 1,
            matchweek: 1,
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
        
        SCORING_ENGINE.updatePlayerPerformance(1, 1, performance);
        console.log("Updated performance for player 1");
        
        // Calculate points for the performance
        uint256 points = SCORING_ENGINE.calculatePlayerPoints(performance);
        console.log("Player points:", points);
        
        // Example: Calculate team score
        address teamOwner = 0x1234567890123456789012345678901234567890; // Replace with actual address
        SCORING_ENGINE.calculateTeamScore(1, teamOwner);
        console.log("Calculated team score for matchweek 1");
        
        // Get team score
        DataStructures.TeamScore memory score = SCORING_ENGINE.getTeamScore(1, teamOwner);
        console.log("Total points:", score.totalPoints);
        console.log("Captain points:", score.captainPoints);
        console.log("Bench points:", score.benchPoints);
        
        vm.stopBroadcast();
    }
}