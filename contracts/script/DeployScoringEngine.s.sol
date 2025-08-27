// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/ScoringEngine.sol";
import "../src/TeamManager.sol";

contract DeployScoringEngine is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy TeamManager first (or use existing address)
        TeamManager teamManager = new TeamManager();
        console.log("TeamManager deployed to:", address(teamManager));
        
        // Deploy ScoringEngine
        ScoringEngine scoringEngine = new ScoringEngine(address(teamManager));
        console.log("ScoringEngine deployed to:", address(scoringEngine));
        
        // Log scoring constants
        console.log("Goal points (GK/DEF):", DataStructures.GOAL_POINTS_GK_DEF);
        console.log("Goal points (MID):", DataStructures.GOAL_POINTS_MID);
        console.log("Goal points (FWD):", DataStructures.GOAL_POINTS_FWD);
        console.log("Assist points:", DataStructures.ASSIST_POINTS);
        console.log("Clean sheet (GK/DEF):", DataStructures.CLEAN_SHEET_GK_DEF);
        console.log("Clean sheet (MID):", DataStructures.CLEAN_SHEET_MID);
        
        vm.stopBroadcast();
    }
}