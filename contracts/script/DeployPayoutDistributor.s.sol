// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/PayoutDistributor.sol";

contract DeployPayoutDistributor is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address poolManagerAddress = vm.envAddress("POOL_MANAGER_ADDRESS");
        address scoringEngineAddress = vm.envAddress("SCORING_ENGINE_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        PayoutDistributor payoutDistributor = new PayoutDistributor(
            poolManagerAddress,
            scoringEngineAddress
        );
        
        console.log("PayoutDistributor deployed at:", address(payoutDistributor));
        console.log("Pool Manager:", poolManagerAddress);
        console.log("Scoring Engine:", scoringEngineAddress);
        
        vm.stopBroadcast();
    }
}