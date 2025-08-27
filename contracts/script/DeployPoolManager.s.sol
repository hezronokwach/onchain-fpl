// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/PoolManager.sol";

contract DeployPoolManager is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        PoolManager poolManager = new PoolManager();
        
        console.log("PoolManager deployed to:", address(poolManager));
        console.log("Entry fee:", poolManager.ENTRY_FEE());
        
        vm.stopBroadcast();
    }
}