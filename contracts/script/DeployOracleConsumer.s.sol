// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/OracleConsumer.sol";
import "../src/ScoringEngine.sol";

contract DeployOracleConsumer is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address scoringEngineAddress = vm.envAddress("SCORING_ENGINE_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy OracleConsumer
        OracleConsumer oracleConsumer = new OracleConsumer(scoringEngineAddress);
        
        console.log("OracleConsumer deployed to:", address(oracleConsumer));
        
        // Set oracle consumer in scoring engine
        ScoringEngine scoringEngine = ScoringEngine(scoringEngineAddress);
        scoringEngine.setOracleConsumer(address(oracleConsumer));
        
        console.log("Oracle consumer set in ScoringEngine");
        
        vm.stopBroadcast();
    }
}