// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/PayoutDistributor.sol";
import "../src/mocks/MockPoolManager.sol";
import "../src/mocks/MockScoringEngine.sol";

/**
 * @title PayoutDistributorIntegrationTest
 * @dev Integration tests showing complete payout flow scenarios
 */
contract PayoutDistributorIntegrationTest is Test {
    PayoutDistributor public payoutDistributor;
    MockPoolManager public mockPoolManager;
    MockScoringEngine public mockScoringEngine;
    
    address public owner = address(1);
    address public alice = address(2);
    address public bob = address(3);
    address public charlie = address(4);
    address public diana = address(5);
    
    uint256 constant ENTRY_FEE = 0.00015 ether;
    uint256 constant MATCHWEEK = 1;
    
    event PayoutProcessed(
        uint256 indexed matchweek, 
        address[] winners, 
        uint256 totalPrize, 
        uint256 amountPerWinner
    );
    
    function setUp() public {
        vm.startPrank(owner);
        
        mockPoolManager = new MockPoolManager();
        mockScoringEngine = new MockScoringEngine();
        payoutDistributor = new PayoutDistributor(
            address(mockPoolManager), 
            address(mockScoringEngine)
        );
        
        vm.stopPrank();
        
        // Fund contract and users
        vm.deal(address(payoutDistributor), 10 ether);
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        vm.deal(charlie, 1 ether);
        vm.deal(diana, 1 ether);
    }
    
    function testCompletePayoutFlow_SingleWinner() public {
        // Setup: 4 participants with different scores
        address[] memory participants = new address[](4);
        participants[0] = alice;   // Score: 120 (winner)
        participants[1] = bob;     // Score: 100
        participants[2] = charlie; // Score: 110
        participants[3] = diana;   // Score: 95
        
        mockPoolManager.setParticipants(MATCHWEEK, participants);
        mockPoolManager.setTotalPrize(MATCHWEEK, ENTRY_FEE * 4);
        
        // Set team scores
        mockScoringEngine.setTeamScore(MATCHWEEK, alice, 120, 15, 10);
        mockScoringEngine.setTeamScore(MATCHWEEK, bob, 100, 12, 8);
        mockScoringEngine.setTeamScore(MATCHWEEK, charlie, 110, 18, 12);
        mockScoringEngine.setTeamScore(MATCHWEEK, diana, 95, 10, 6);
        
        // Record balances before payout
        uint256 aliceBalanceBefore = alice.balance;
        uint256 bobBalanceBefore = bob.balance;
        uint256 charlieBalanceBefore = charlie.balance;
        uint256 dianaBalanceBefore = diana.balance;
        
        // Expect PayoutProcessed event
        vm.expectEmit(true, false, false, true);
        address[] memory expectedWinners = new address[](1);
        expectedWinners[0] = alice;
        emit PayoutProcessed(MATCHWEEK, expectedWinners, ENTRY_FEE * 4, ENTRY_FEE * 4);
        
        // Process payout
        payoutDistributor.processPayout(MATCHWEEK);
        
        // Verify results
        assertTrue(payoutDistributor.isPayoutProcessed(MATCHWEEK));
        
        (address[] memory winners, uint256 amountPerWinner) = payoutDistributor.getWinners(MATCHWEEK);
        assertEq(winners.length, 1);
        assertEq(winners[0], alice);
        assertEq(amountPerWinner, ENTRY_FEE * 4);
        
        // Verify balances
        assertEq(alice.balance, aliceBalanceBefore + (ENTRY_FEE * 4));
        assertEq(bob.balance, bobBalanceBefore); // No change
        assertEq(charlie.balance, charlieBalanceBefore); // No change
        assertEq(diana.balance, dianaBalanceBefore); // No change
    }
    
    function testCompletePayoutFlow_TieBreakingScenario() public {
        // Setup: 3 participants, 2 tied on total score, different bench scores
        address[] memory participants = new address[](3);
        participants[0] = alice;   // Score: 100, Bench: 20 (winner via tie-break)
        participants[1] = bob;     // Score: 100, Bench: 15 (tied on total)
        participants[2] = charlie; // Score: 90 (lower score)
        
        mockPoolManager.setParticipants(MATCHWEEK, participants);
        mockPoolManager.setTotalPrize(MATCHWEEK, ENTRY_FEE * 3);
        
        // Set team scores - Alice and Bob tied on total, Alice higher bench
        mockScoringEngine.setTeamScore(MATCHWEEK, alice, 100, 20, 10);
        mockScoringEngine.setTeamScore(MATCHWEEK, bob, 100, 15, 10);
        mockScoringEngine.setTeamScore(MATCHWEEK, charlie, 90, 12, 8);
        
        uint256 aliceBalanceBefore = alice.balance;
        uint256 bobBalanceBefore = bob.balance;
        uint256 charlieBalanceBefore = charlie.balance;
        
        // Process payout
        payoutDistributor.processPayout(MATCHWEEK);
        
        // Verify Alice wins via tie-breaking (higher bench score)
        (address[] memory winners, uint256 amountPerWinner) = payoutDistributor.getWinners(MATCHWEEK);
        assertEq(winners.length, 1);
        assertEq(winners[0], alice);
        assertEq(amountPerWinner, ENTRY_FEE * 3);
        
        // Verify balances
        assertEq(alice.balance, aliceBalanceBefore + (ENTRY_FEE * 3));
        assertEq(bob.balance, bobBalanceBefore);
        assertEq(charlie.balance, charlieBalanceBefore);
    }
    
    function testCompletePayoutFlow_CompleteTie() public {
        // Setup: 2 participants with identical scores in all categories
        address[] memory participants = new address[](2);
        participants[0] = alice;
        participants[1] = bob;
        
        mockPoolManager.setParticipants(MATCHWEEK, participants);
        mockPoolManager.setTotalPrize(MATCHWEEK, ENTRY_FEE * 2);
        
        // Set identical scores
        mockScoringEngine.setTeamScore(MATCHWEEK, alice, 100, 15, 10);
        mockScoringEngine.setTeamScore(MATCHWEEK, bob, 100, 15, 10);
        mockScoringEngine.setTeamGoals(MATCHWEEK, alice, 8);
        mockScoringEngine.setTeamGoals(MATCHWEEK, bob, 8);
        mockScoringEngine.setTeamCards(MATCHWEEK, alice, 3);
        mockScoringEngine.setTeamCards(MATCHWEEK, bob, 3);
        
        uint256 aliceBalanceBefore = alice.balance;
        uint256 bobBalanceBefore = bob.balance;
        
        // Process payout
        payoutDistributor.processPayout(MATCHWEEK);
        
        // Verify both win and split prize
        (address[] memory winners, uint256 amountPerWinner) = payoutDistributor.getWinners(MATCHWEEK);
        assertEq(winners.length, 2);
        assertEq(amountPerWinner, ENTRY_FEE); // Half each
        
        // Both should be winners (order may vary)
        bool aliceIsWinner = (winners[0] == alice || winners[1] == alice);
        bool bobIsWinner = (winners[0] == bob || winners[1] == bob);
        assertTrue(aliceIsWinner);
        assertTrue(bobIsWinner);
        
        // Verify balances - both get half
        assertEq(alice.balance, aliceBalanceBefore + ENTRY_FEE);
        assertEq(bob.balance, bobBalanceBefore + ENTRY_FEE);
    }
    
    function testCompletePayoutFlow_LargePool() public {
        // Setup: Large pool with 10 participants
        address[] memory participants = new address[](4); // Using 4 for simplicity
        participants[0] = alice;   // Score: 150 (clear winner)
        participants[1] = bob;     // Score: 140
        participants[2] = charlie; // Score: 130
        participants[3] = diana;   // Score: 120
        
        uint256 totalPrize = ENTRY_FEE * 4;
        mockPoolManager.setParticipants(MATCHWEEK, participants);
        mockPoolManager.setTotalPrize(MATCHWEEK, totalPrize);
        
        // Set decreasing scores
        mockScoringEngine.setTeamScore(MATCHWEEK, alice, 150, 20, 15);
        mockScoringEngine.setTeamScore(MATCHWEEK, bob, 140, 18, 12);
        mockScoringEngine.setTeamScore(MATCHWEEK, charlie, 130, 16, 10);
        mockScoringEngine.setTeamScore(MATCHWEEK, diana, 120, 14, 8);
        
        uint256 aliceBalanceBefore = alice.balance;
        
        // Process payout
        payoutDistributor.processPayout(MATCHWEEK);
        
        // Verify Alice wins entire pool
        (address[] memory winners, uint256 amountPerWinner) = payoutDistributor.getWinners(MATCHWEEK);
        assertEq(winners.length, 1);
        assertEq(winners[0], alice);
        assertEq(amountPerWinner, totalPrize);
        assertEq(alice.balance, aliceBalanceBefore + totalPrize);
    }
    
    function testPayoutFlow_EdgeCases() public {
        // Test single participant
        address[] memory participants = new address[](1);
        participants[0] = alice;
        
        mockPoolManager.setParticipants(MATCHWEEK, participants);
        mockPoolManager.setTotalPrize(MATCHWEEK, ENTRY_FEE);
        mockScoringEngine.setTeamScore(MATCHWEEK, alice, 100, 15, 10);
        
        uint256 aliceBalanceBefore = alice.balance;
        
        payoutDistributor.processPayout(MATCHWEEK);
        
        (address[] memory winners, uint256 amountPerWinner) = payoutDistributor.getWinners(MATCHWEEK);
        assertEq(winners.length, 1);
        assertEq(winners[0], alice);
        assertEq(amountPerWinner, ENTRY_FEE);
        assertEq(alice.balance, aliceBalanceBefore + ENTRY_FEE);
    }
    
    function testPayoutReadinessChecks() public {
        uint256 testMatchweek = 2;
        
        // Initially not ready (no participants)
        assertFalse(payoutDistributor.isMatchweekReadyForPayout(testMatchweek));
        
        // Add participants but no scores
        address[] memory participants = new address[](2);
        participants[0] = alice;
        participants[1] = bob;
        mockPoolManager.setParticipants(testMatchweek, participants);
        mockPoolManager.setTotalPrize(testMatchweek, ENTRY_FEE * 2);
        
        assertFalse(payoutDistributor.isMatchweekReadyForPayout(testMatchweek));
        
        // Add partial scores
        mockScoringEngine.setTeamScore(testMatchweek, alice, 100, 15, 10);
        assertFalse(payoutDistributor.isMatchweekReadyForPayout(testMatchweek));
        
        // Add all scores - now ready
        mockScoringEngine.setTeamScore(testMatchweek, bob, 90, 12, 8);
        assertTrue(payoutDistributor.isMatchweekReadyForPayout(testMatchweek));
        
        // Process payout - no longer ready
        payoutDistributor.processPayout(testMatchweek);
        assertFalse(payoutDistributor.isMatchweekReadyForPayout(testMatchweek));
    }
}