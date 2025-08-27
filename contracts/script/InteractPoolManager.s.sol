// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/PoolManager.sol";

contract InteractPoolManager is Script {
    PoolManager constant POOL_MANAGER = PoolManager(0x5FbDB2315678afecb367f032d93F642f64180aa3); // Replace with actual address
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Create a pool for matchweek 1
        uint256 deadline = block.timestamp + 7 days;
        POOL_MANAGER.createPool(1, deadline);
        
        console.log("Pool created for matchweek 1");
        console.log("Deadline:", deadline);
        console.log("Entry fee:", POOL_MANAGER.ENTRY_FEE());
        
        // Get pool info
        DataStructures.Pool memory pool = POOL_MANAGER.getPool(1);
        console.log("Pool active:", pool.isActive);
        console.log("Participants:", pool.participants.length);
        
        vm.stopBroadcast();
    }
}