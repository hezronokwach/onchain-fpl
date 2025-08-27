// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/MockOracle.sol";

contract DeployMockOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address oracleConsumerAddress = vm.envAddress("ORACLE_CONSUMER_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy MockOracle
        MockOracle mockOracle = new MockOracle(oracleConsumerAddress);
        
        console.log("MockOracle deployed to:", address(mockOracle));
        
        vm.stopBroadcast();
    }
}