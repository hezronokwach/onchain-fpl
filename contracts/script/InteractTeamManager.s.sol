// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/TeamManager.sol";

contract InteractTeamManager is Script {
    TeamManager constant TEAM_MANAGER = TeamManager(0x5FbDB2315678afecb367f032d93F642f64180aa3); // Replace with actual address
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Add sample players
        TEAM_MANAGER.addPlayer(1, "Alisson", Position.GK, 5500000, 1); // Liverpool GK
        TEAM_MANAGER.addPlayer(2, "Van Dijk", Position.DEF, 6500000, 1); // Liverpool DEF
        TEAM_MANAGER.addPlayer(3, "Salah", Position.FWD, 13000000, 1); // Liverpool FWD
        
        console.log("Added sample players");
        
        // Set deadline for matchweek 1
        uint256 deadline = block.timestamp + 7 days;
        TEAM_MANAGER.setPoolDeadline(1, deadline);
        
        console.log("Set deadline for matchweek 1:", deadline);
        
        // Get player info
        DataStructures.Player memory player = TEAM_MANAGER.getPlayer(1);
        console.log("Player 1 name:", player.name);
        console.log("Player 1 price:", player.price);
        
        vm.stopBroadcast();
    }
}