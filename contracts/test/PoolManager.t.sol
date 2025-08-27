// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/PoolManager.sol";

contract PoolManagerTest is Test {
    PoolManager public poolManager;
    
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public user3 = address(4);
    
    uint256 constant ENTRY_FEE = 0.00015 ether;
    
    function setUp() public {
        vm.prank(owner);
        poolManager = new PoolManager();
    }
    
    function testCreatePool() public {
        uint256 deadline = block.timestamp + 3600;
        
        vm.prank(owner);
        poolManager.createPool(1, deadline);
        
        DataStructures.Pool memory pool = poolManager.getPool(1);
        assertEq(pool.matchweek, 1);
        assertEq(pool.entryFee, ENTRY_FEE);
        assertEq(pool.deadline, deadline);
        assertTrue(pool.isActive);
        assertFalse(pool.isFinalized);
    }
    
    function testJoinPool() public {
        // Create pool
        vm.prank(owner);
        poolManager.createPool(1, block.timestamp + 3600);
        
        // User joins pool
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        poolManager.joinPool{value: ENTRY_FEE}(1);
        
        // Verify
        assertTrue(poolManager.hasUserEnteredPool(1, user1));
        assertEq(poolManager.getParticipantCount(1), 1);
        
        DataStructures.Pool memory pool = poolManager.getPool(1);
        assertEq(pool.totalPrize, ENTRY_FEE);
    }
    
    function testMultipleUsersJoinPool() public {
        // Create pool
        vm.prank(owner);
        poolManager.createPool(1, block.timestamp + 3600);
        
        // Multiple users join
        address[3] memory users = [user1, user2, user3];
        
        for (uint i = 0; i < users.length; i++) {
            vm.deal(users[i], 1 ether);
            vm.prank(users[i]);
            poolManager.joinPool{value: ENTRY_FEE}(1);
        }
        
        // Verify
        assertEq(poolManager.getParticipantCount(1), 3);
        
        DataStructures.Pool memory pool = poolManager.getPool(1);
        assertEq(pool.totalPrize, ENTRY_FEE * 3);
        
        address[] memory participants = poolManager.getParticipants(1);
        assertEq(participants.length, 3);
    }
    
    function testCannotJoinAfterDeadline() public {
        // Create pool with past deadline
        vm.prank(owner);
        poolManager.createPool(1, block.timestamp + 1);
        
        // Fast forward past deadline
        vm.warp(block.timestamp + 2);
        
        // Try to join - should fail
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vm.expectRevert("Deadline has passed");
        poolManager.joinPool{value: ENTRY_FEE}(1);
    }
    
    function testCannotJoinTwice() public {
        // Create pool
        vm.prank(owner);
        poolManager.createPool(1, block.timestamp + 3600);
        
        // User joins once
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        poolManager.joinPool{value: ENTRY_FEE}(1);
        
        // Try to join again - should fail
        vm.prank(user1);
        vm.expectRevert("Already entered");
        poolManager.joinPool{value: ENTRY_FEE}(1);
    }
    
    function testIncorrectEntryFee() public {
        // Create pool
        vm.prank(owner);
        poolManager.createPool(1, block.timestamp + 3600);
        
        // Try with wrong fee
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vm.expectRevert("Incorrect entry fee");
        poolManager.joinPool{value: ENTRY_FEE + 1}(1);
    }
    
    function testOnlyOwnerCanCreatePool() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        poolManager.createPool(1, block.timestamp + 3600);
    }
    
    function testCannotCreateDuplicatePool() public {
        vm.prank(owner);
        poolManager.createPool(1, block.timestamp + 3600);
        
        vm.prank(owner);
        vm.expectRevert("Pool already exists");
        poolManager.createPool(1, block.timestamp + 7200);
    }
    
    function testFinalizePool() public {
        // Create and populate pool
        vm.prank(owner);
        poolManager.createPool(1, block.timestamp + 3600);
        
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        poolManager.joinPool{value: ENTRY_FEE}(1);
        
        // Fast forward past deadline
        vm.warp(block.timestamp + 3601);
        
        // Finalize pool
        vm.prank(owner);
        poolManager.finalizePool(1, user1, 100);
        
        DataStructures.Pool memory pool = poolManager.getPool(1);
        assertTrue(pool.isFinalized);
        assertEq(pool.winner, user1);
        assertEq(pool.winningScore, 100);
    }

    function testCannotFinalizeBeforeDeadline() public {
        // Create and populate pool
        vm.prank(owner);
        poolManager.createPool(1, block.timestamp + 3600);
        
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        poolManager.joinPool{value: ENTRY_FEE}(1);
        
        // Try to finalize before deadline
        vm.prank(owner);
        vm.expectRevert("Deadline not passed");
        poolManager.finalizePool(1, user1, 100);
    }

    function testCannotFinalizeWithNonParticipant() public {
        // Create and populate pool
        vm.prank(owner);
        poolManager.createPool(1, block.timestamp + 3600);
        
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        poolManager.joinPool{value: ENTRY_FEE}(1);
        
        // Fast forward past deadline
        vm.warp(block.timestamp + 3601);
        
        // Try to finalize with non-participant
        vm.prank(owner);
        vm.expectRevert("Winner not in pool");
        poolManager.finalizePool(1, user2, 100);
    }

    function testPausePool() public {
        // Create pool
        vm.prank(owner);
        poolManager.createPool(1, block.timestamp + 3600);
        
        // Pause pool
        vm.prank(owner);
        poolManager.pausePool(1);
        
        DataStructures.Pool memory pool = poolManager.getPool(1);
        assertFalse(pool.isActive);
    }

    function testEmergencyRefund() public {
        // Create and populate pool
        vm.prank(owner);
        poolManager.createPool(1, block.timestamp + 3600);
        
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        
        vm.prank(user1);
        poolManager.joinPool{value: ENTRY_FEE}(1);
        
        vm.prank(user2);
        poolManager.joinPool{value: ENTRY_FEE}(1);
        
        uint256 user1BalanceBefore = user1.balance;
        uint256 user2BalanceBefore = user2.balance;
        
        // Emergency refund
        vm.prank(owner);
        poolManager.emergencyRefund(1);
        
        // Check refunds
        assertEq(user1.balance, user1BalanceBefore + ENTRY_FEE);
        assertEq(user2.balance, user2BalanceBefore + ENTRY_FEE);
        
        DataStructures.Pool memory pool = poolManager.getPool(1);
        assertFalse(pool.isActive);
        assertEq(pool.totalPrize, 0);
    }

    function testInvalidMatchweek() public {
        vm.prank(owner);
        vm.expectRevert("Invalid matchweek");
        poolManager.createPool(0, block.timestamp + 3600);
        
        vm.prank(owner);
        vm.expectRevert("Invalid matchweek");
        poolManager.createPool(39, block.timestamp + 3600);
    }

    function testInvalidDeadline() public {
        vm.prank(owner);
        vm.expectRevert("Invalid deadline");
        poolManager.createPool(1, block.timestamp - 1);
    }

    function testJoinNonExistentPool() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vm.expectRevert("Pool does not exist");
        poolManager.joinPool{value: ENTRY_FEE}(1);
    }
}