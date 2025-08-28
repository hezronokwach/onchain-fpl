// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/PayoutDistributor.sol";

contract InteractPayoutDistributor is Script {
    PayoutDistributor payoutDistributor;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payoutDistributorAddress = vm.envAddress("PAYOUT_DISTRIBUTOR_ADDRESS");
        
        payoutDistributor = PayoutDistributor(payable(payoutDistributorAddress));
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Example interactions
        uint256 matchweek = 1;
        
        // Check if matchweek is ready for payout
        bool isReady = payoutDistributor.isMatchweekReadyForPayout(matchweek);
        console.log("Matchweek", matchweek, "ready for payout:", isReady);
        
        // Check if payout has been processed
        bool isProcessed = payoutDistributor.isPayoutProcessed(matchweek);
        console.log("Matchweek", matchweek, "payout processed:", isProcessed);
        
        if (isReady && !isProcessed) {
            // Process payout
            console.log("Processing payout for matchweek", matchweek);
            payoutDistributor.processPayout(matchweek);
            console.log("Payout processed successfully!");
            
            // Get winners
            (address[] memory winners, uint256 amountPerWinner) = payoutDistributor.getWinners(matchweek);
            console.log("Number of winners:", winners.length);
            console.log("Amount per winner:", amountPerWinner);
            
            for (uint256 i = 0; i < winners.length; i++) {
                console.log("Winner", i + 1, ":", winners[i]);
            }
        } else if (isProcessed) {
            // Get existing winners
            (address[] memory winners, uint256 amountPerWinner) = payoutDistributor.getWinners(matchweek);
            console.log("Payout already processed:");
            console.log("Number of winners:", winners.length);
            console.log("Amount per winner:", amountPerWinner);
            
            for (uint256 i = 0; i < winners.length; i++) {
                console.log("Winner", i + 1, ":", winners[i]);
            }
        } else {
            console.log("Matchweek not ready for payout yet");
        }
        
        vm.stopBroadcast();
    }
    
    function checkMultipleMatchweeks() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payoutDistributorAddress = vm.envAddress("PAYOUT_DISTRIBUTOR_ADDRESS");
        
        payoutDistributor = PayoutDistributor(payable(payoutDistributorAddress));
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Check status of multiple matchweeks
        for (uint256 matchweek = 1; matchweek <= 5; matchweek++) {
            bool isReady = payoutDistributor.isMatchweekReadyForPayout(matchweek);
            bool isProcessed = payoutDistributor.isPayoutProcessed(matchweek);
            
            console.log("Matchweek", matchweek);
            console.log("Ready:", isReady);
            console.log("Processed:", isProcessed);
            
            if (isProcessed) {
                (address[] memory winners, uint256 amountPerWinner) = payoutDistributor.getWinners(matchweek);
                console.log("Winners:", winners.length);
                console.log("Amount each:", amountPerWinner);
            }
        }
        
        vm.stopBroadcast();
    }
    
    function emergencyWithdraw() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payoutDistributorAddress = vm.envAddress("PAYOUT_DISTRIBUTOR_ADDRESS");
        uint256 matchweek = vm.envUint("MATCHWEEK");
        
        payoutDistributor = PayoutDistributor(payable(payoutDistributorAddress));
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Performing emergency withdrawal for matchweek", matchweek);
        payoutDistributor.emergencyWithdraw(matchweek);
        console.log("Emergency withdrawal completed");
        
        vm.stopBroadcast();
    }
    
    function updateContracts() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payoutDistributorAddress = vm.envAddress("PAYOUT_DISTRIBUTOR_ADDRESS");
        address newPoolManager = vm.envAddress("NEW_POOL_MANAGER_ADDRESS");
        address newScoringEngine = vm.envAddress("NEW_SCORING_ENGINE_ADDRESS");
        
        payoutDistributor = PayoutDistributor(payable(payoutDistributorAddress));
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Updating contract addresses:");
        console.log("New Pool Manager:", newPoolManager);
        console.log("New Scoring Engine:", newScoringEngine);
        
        payoutDistributor.updateContracts(newPoolManager, newScoringEngine);
        console.log("Contract addresses updated successfully");
        
        vm.stopBroadcast();
    }
}