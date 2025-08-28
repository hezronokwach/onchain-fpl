// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/TeamManager.sol";
import "../src/PoolManager.sol";
import "../src/ScoringEngine.sol";
import "../src/OracleConsumer.sol";
import "../src/PayoutDistributor.sol";

contract DeployAll is Script {
    function run() external {
        // Try to use keystore first, fallback to private key
        address deployer;
        
        // Check if using keystore or private key
        try vm.envUint("PRIVATE_KEY") returns (uint256 privateKey) {
            vm.startBroadcast(privateKey);
            deployer = vm.addr(privateKey);
            console.log("Using private key from .env");
        } catch {
            // Using keystore - address will be set by --sender flag
            vm.startBroadcast();
            deployer = msg.sender;
            console.log("Using Foundry keystore");
        }
        
        console.log("Deploying OnChain FPL contracts to Base Sepolia...");
        console.log("Deployer:", deployer);
        
        // 1. Deploy TeamManager
        console.log("\n1. Deploying TeamManager...");
        TeamManager teamManager = new TeamManager();
        console.log("TeamManager deployed at:", address(teamManager));
        
        // 2. Deploy PoolManager
        console.log("\n2. Deploying PoolManager...");
        PoolManager poolManager = new PoolManager();
        console.log("PoolManager deployed at:", address(poolManager));
        
        // 3. Deploy ScoringEngine
        console.log("\n3. Deploying ScoringEngine...");
        ScoringEngine scoringEngine = new ScoringEngine(address(teamManager));
        console.log("ScoringEngine deployed at:", address(scoringEngine));
        
        // 4. Deploy OracleConsumer
        console.log("\n4. Deploying OracleConsumer...");
        OracleConsumer oracleConsumer = new OracleConsumer(address(scoringEngine));
        console.log("OracleConsumer deployed at:", address(oracleConsumer));
        
        // 5. Deploy PayoutDistributor
        console.log("\n5. Deploying PayoutDistributor...");
        PayoutDistributor payoutDistributor = new PayoutDistributor(
            address(poolManager),
            address(scoringEngine)
        );
        console.log("PayoutDistributor deployed at:", address(payoutDistributor));
        
        // 6. Configure contract connections
        console.log("\n6. Configuring contract connections...");
        scoringEngine.setOracleConsumer(address(oracleConsumer));
        console.log("ScoringEngine oracle consumer set");
        
        console.log("\n All contracts deployed successfully!");
        console.log("\n Contract Addresses:");
        console.log("TeamManager:", address(teamManager));
        console.log("PoolManager:", address(poolManager));
        console.log("ScoringEngine:", address(scoringEngine));
        console.log("OracleConsumer:", address(oracleConsumer));
        console.log("PayoutDistributor:", address(payoutDistributor));
        
        console.log("\n Add these to your .env file:");
        console.log("TEAM_MANAGER_ADDRESS=", address(teamManager));
        console.log("POOL_MANAGER_ADDRESS=", address(poolManager));
        console.log("SCORING_ENGINE_ADDRESS=", address(scoringEngine));
        console.log("ORACLE_CONSUMER_ADDRESS=", address(oracleConsumer));
        console.log("PAYOUT_DISTRIBUTOR_ADDRESS=", address(payoutDistributor));
        
        vm.stopBroadcast();
    }
}