// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/PayoutDistributor.sol";
import "../src/mocks/MockPoolManager.sol";
import "../src/mocks/MockScoringEngine.sol";
import "../src/libraries/DataStructures.sol";

contract PayoutDistributorTest is Test {
    PayoutDistributor public payoutDistributor;
    MockPoolManager public mockPoolManager;
    MockScoringEngine public mockScoringEngine;
    
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public user3 = address(4);
    
    uint256 constant ENTRY_FEE = 0.00015 ether;
    uint256 constant MATCHWEEK = 1;
    
    function setUp() public {
        vm.startPrank(owner);
        
        // Deploy mock contracts
        mockPoolManager = new MockPoolManager();
        mockScoringEngine = new MockScoringEngine();
        payoutDistributor = new PayoutDistributor(
            address(mockPoolManager), 
            address(mockScoringEngine)
        );
        
        vm.stopPrank();
        
        // Fund the contract
        vm.deal(address(payoutDistributor), 10 ether);
        
        // Fund users
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        vm.deal(user3, 1 ether);
    }
    
    function testSingleWinnerPayout() public {
        // Setup: 3 participants
        address[] memory participants = new address[](3);
        participants[0] = user1;
        participants[1] = user2;
        participants[2] = user3;
        
        mockPoolManager.setParticipants(MATCHWEEK, participants);
        mockPoolManager.setTotalPrize(MATCHWEEK, ENTRY_FEE * 3);
        
        // Set scores: user1 = 100, user2 = 80, user3 = 90
        mockScoringEngine.setTeamScore(MATCHWEEK, user1, 100, 10, 5);
        mockScoringEngine.setTeamScore(MATCHWEEK, user2, 80, 8, 3);
        mockScoringEngine.setTeamScore(MATCHWEEK, user3, 90, 12, 4);
        
        uint256 user1BalanceBefore = user1.balance;
        
        // Process payout
        payoutDistributor.processPayout(MATCHWEEK);
        
        // Verify
        assertTrue(payoutDistributor.isPayoutProcessed(MATCHWEEK));
        assertEq(user1.balance, user1BalanceBefore + (ENTRY_FEE * 3));
        
        (address[] memory winners, uint256 amountPerWinner) = payoutDistributor.getWinners(MATCHWEEK);
        assertEq(winners.length, 1);
        assertEq(winners[0], user1);
        assertEq(amountPerWinner, ENTRY_FEE * 3);
    }
    
    function testTieBreakingByBenchScore() public {
        // Setup: 2 participants with same total score, different bench scores
        address[] memory participants = new address[](2);
        participants[0] = user1;
        participants[1] = user2;
        
        mockPoolManager.setParticipants(MATCHWEEK, participants);
        mockPoolManager.setTotalPrize(MATCHWEEK, ENTRY_FEE * 2);
        
        // Same total score (100), but user1 has higher bench score (15 vs 10)
        mockScoringEngine.setTeamScore(MATCHWEEK, user1, 100, 15, 5);
        mockScoringEngine.setTeamScore(MATCHWEEK, user2, 100, 10, 3);
        
        uint256 user1BalanceBefore = user1.balance;
        
        // Process payout
        payoutDistributor.processPayout(MATCHWEEK);
        
        // Verify user1 wins due to higher bench score
        (address[] memory winners,) = payoutDistributor.getWinners(MATCHWEEK);
        assertEq(winners.length, 1);
        assertEq(winners[0], user1);
        assertEq(user1.balance, user1BalanceBefore + (ENTRY_FEE * 2));
    }
    
    function testCompleteTie_SplitPrize() public {
        // Setup: Complete tie after all tie-breaking rules
        address[] memory participants = new address[](2);
        participants[0] = user1;
        participants[1] = user2;
        
        mockPoolManager.setParticipants(MATCHWEEK, participants);
        mockPoolManager.setTotalPrize(MATCHWEEK, ENTRY_FEE * 2);
        
        // Identical scores in all categories
        mockScoringEngine.setTeamScore(MATCHWEEK, user1, 100, 10, 5);
        mockScoringEngine.setTeamScore(MATCHWEEK, user2, 100, 10, 5);
        mockScoringEngine.setTeamGoals(MATCHWEEK, user1, 5);
        mockScoringEngine.setTeamGoals(MATCHWEEK, user2, 5);
        mockScoringEngine.setTeamCards(MATCHWEEK, user1, 2);
        mockScoringEngine.setTeamCards(MATCHWEEK, user2, 2);
        
        uint256 user1BalanceBefore = user1.balance;
        uint256 user2BalanceBefore = user2.balance;
        
        // Process payout
        payoutDistributor.processPayout(MATCHWEEK);
        
        // Verify both users get half the prize
        (address[] memory winners, uint256 amountPerWinner) = payoutDistributor.getWinners(MATCHWEEK);
        assertEq(winners.length, 2);
        assertEq(amountPerWinner, ENTRY_FEE); // Half each
        assertEq(user1.balance, user1BalanceBefore + ENTRY_FEE);
        assertEq(user2.balance, user2BalanceBefore + ENTRY_FEE);
    }
    
    function testCannotProcessTwice() public {
        // Setup basic scenario
        address[] memory participants = new address[](1);
        participants[0] = user1;
        
        mockPoolManager.setParticipants(MATCHWEEK, participants);
        mockPoolManager.setTotalPrize(MATCHWEEK, ENTRY_FEE);
        mockScoringEngine.setTeamScore(MATCHWEEK, user1, 100, 10, 5);
        
        // Process once
        payoutDistributor.processPayout(MATCHWEEK);
        
        // Try to process again - should fail
        vm.expectRevert(PayoutDistributor.PayoutAlreadyProcessed.selector);
        payoutDistributor.processPayout(MATCHWEEK);
    }
    
    function testCannotProcessWithoutScores() public {
        // Setup: participants but no scores calculated
        address[] memory participants = new address[](1);
        participants[0] = user1;
        
        mockPoolManager.setParticipants(MATCHWEEK, participants);
        mockPoolManager.setTotalPrize(MATCHWEEK, ENTRY_FEE);
        // Don't set team score - should fail
        
        // Try to process without scores - should fail
        vm.expectRevert(PayoutDistributor.ScoresNotCalculated.selector);
        payoutDistributor.processPayout(MATCHWEEK);
    }
    
    function testCannotProcessEmptyPool() public {
        // Try to process empty pool - should fail
        vm.expectRevert(PayoutDistributor.NoParticipants.selector);
        payoutDistributor.processPayout(MATCHWEEK);
    }
    
    function testIsMatchweekReadyForPayout() public {
        // Initially not ready (no participants)
        assertFalse(payoutDistributor.isMatchweekReadyForPayout(MATCHWEEK));
        
        // Add participant but no scores
        address[] memory participants = new address[](1);
        participants[0] = user1;
        mockPoolManager.setParticipants(MATCHWEEK, participants);
        mockPoolManager.setTotalPrize(MATCHWEEK, ENTRY_FEE);
        assertFalse(payoutDistributor.isMatchweekReadyForPayout(MATCHWEEK));
        
        // Add scores - now ready
        mockScoringEngine.setTeamScore(MATCHWEEK, user1, 100, 10, 5);
        assertTrue(payoutDistributor.isMatchweekReadyForPayout(MATCHWEEK));
        
        // Process payout - no longer ready
        payoutDistributor.processPayout(MATCHWEEK);
        assertFalse(payoutDistributor.isMatchweekReadyForPayout(MATCHWEEK));
    }
    
    function testEmergencyWithdraw() public {
        // Setup pool with funds
        mockPoolManager.setTotalPrize(MATCHWEEK, ENTRY_FEE * 3);
        
        uint256 ownerBalanceBefore = owner.balance;
        
        // Emergency withdraw
        vm.prank(owner);
        payoutDistributor.emergencyWithdraw(MATCHWEEK);
        
        // Verify owner received funds
        assertEq(owner.balance, ownerBalanceBefore + (ENTRY_FEE * 3));
    }
    
    function testOnlyOwnerCanEmergencyWithdraw() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        payoutDistributor.emergencyWithdraw(MATCHWEEK);
    }
    
    function testCannotEmergencyWithdrawAfterPayout() public {
        // Setup and process payout
        address[] memory participants = new address[](1);
        participants[0] = user1;
        
        mockPoolManager.setParticipants(MATCHWEEK, participants);
        mockPoolManager.setTotalPrize(MATCHWEEK, ENTRY_FEE);
        mockScoringEngine.setTeamScore(MATCHWEEK, user1, 100, 10, 5);
        payoutDistributor.processPayout(MATCHWEEK);
        
        // Try emergency withdraw - should fail
        vm.prank(owner);
        vm.expectRevert("Payout already processed");
        payoutDistributor.emergencyWithdraw(MATCHWEEK);
    }
    
    function testUpdateContracts() public {
        address newPoolManager = address(0x123);
        address newScoringEngine = address(0x456);
        
        vm.prank(owner);
        payoutDistributor.updateContracts(newPoolManager, newScoringEngine);
        
        assertEq(address(payoutDistributor.poolManager()), newPoolManager);
        assertEq(address(payoutDistributor.scoringEngine()), newScoringEngine);
    }
    
    function testCannotUpdateContractsWithZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(PayoutDistributor.InvalidContract.selector);
        payoutDistributor.updateContracts(address(0), address(mockScoringEngine));
        
        vm.prank(owner);
        vm.expectRevert(PayoutDistributor.InvalidContract.selector);
        payoutDistributor.updateContracts(address(mockPoolManager), address(0));
    }
    
    function testOnlyOwnerCanUpdateContracts() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        payoutDistributor.updateContracts(address(0x123), address(0x456));
    }
    
    function testReceiveFunction() public {
        uint256 amount = 1 ether;
        uint256 balanceBefore = address(payoutDistributor).balance;
        
        // Send ETH to contract
        (bool success,) = address(payoutDistributor).call{value: amount}("");
        assertTrue(success);
        
        assertEq(address(payoutDistributor).balance, balanceBefore + amount);
    }
    

}