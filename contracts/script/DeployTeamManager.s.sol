// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/TeamManager.sol";

contract DeployTeamManager is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        TeamManager teamManager = new TeamManager();
        
        console.log("TeamManager deployed to:", address(teamManager));
        console.log("Max budget:", DataStructures.MAX_BUDGET);
        console.log("Squad size:", DataStructures.SQUAD_SIZE);
        console.log("Max players per team:", DataStructures.MAX_PLAYERS_PER_TEAM);
        
        vm.stopBroadcast();
    }
}