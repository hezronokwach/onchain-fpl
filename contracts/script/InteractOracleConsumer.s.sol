// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/OracleConsumer.sol";
import "../src/MockOracle.sol";
import "../src/libraries/DataStructures.sol";

contract InteractOracleConsumer is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address oracleConsumerAddress = vm.envAddress("ORACLE_CONSUMER_ADDRESS");
        address mockOracleAddress = vm.envAddress("MOCK_ORACLE_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        OracleConsumer oracleConsumer = OracleConsumer(oracleConsumerAddress);
        MockOracle mockOracle = MockOracle(mockOracleAddress);
        
        // Add mock oracle as authorized
        console.log("Adding mock oracle as authorized...");
        oracleConsumer.addOracle(mockOracleAddress);
        
        // Create realistic mock data for matchweek 1
        console.log("Creating realistic mock data for matchweek 1...");
        mockOracle.createRealisticMockData(1, 50);
        
        // Submit mock data
        console.log("Submitting mock data...");
        mockOracle.submitMockData(1);
        
        // Check oracle status
        (uint256 confirmations, bool validated, uint256 timestamp) = 
            oracleConsumer.getOracleStatus(1);
        
        console.log("Oracle status for matchweek 1:");
        console.log("  Confirmations:", confirmations);
        console.log("  Validated:", validated);
        console.log("  Timestamp:", timestamp);
        
        // Request match data for matchweek 2
        console.log("Requesting match data for matchweek 2...");
        oracleConsumer.requestMatchData(2);
        
        // Demonstrate emergency mode
        console.log("Testing emergency mode...");
        oracleConsumer.toggleEmergencyMode(true);
        
        // Submit manual data in emergency mode
        DataStructures.PlayerPerformance[] memory emergencyPerformances = 
            new DataStructures.PlayerPerformance[](2);
        
        emergencyPerformances[0] = DataStructures.PlayerPerformance({
            playerId: 1,
            matchweek: 3,
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
        
        emergencyPerformances[1] = DataStructures.PlayerPerformance({
            playerId: 2,
            matchweek: 3,
            goals: 0,
            assists: 0,
            minutesPlayed: 0, // Didn't play
            cleanSheet: false,
            saves: 0,
            cards: 0,
            ownGoal: false,
            penaltyMiss: false,
            bonusPoints: 0,
            isValidated: true
        });
        
        console.log("Submitting manual data for matchweek 3...");
        oracleConsumer.submitManualData(3, emergencyPerformances);
        
        // Turn off emergency mode
        oracleConsumer.toggleEmergencyMode(false);
        
        // Get authorized oracles
        address[] memory authorizedOracles = oracleConsumer.getAuthorizedOracles();
        console.log("Authorized oracles count:", authorizedOracles.length);
        for (uint256 i = 0; i < authorizedOracles.length; i++) {
            console.log("  Oracle", i, ":", authorizedOracles[i]);
        }
        
        console.log("Oracle interaction completed successfully!");
        
        vm.stopBroadcast();
    }
}