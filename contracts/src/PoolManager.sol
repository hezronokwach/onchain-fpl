// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/DataStructures.sol";
import "./libraries/ValidationLibrary.sol";

/**
 * @title PoolManager
 * @dev Manages matchweek pools for OnChain FPL
 */
contract PoolManager is Ownable, ReentrancyGuard {
    using ValidationLibrary for *;
    
    // State variables
    uint256 public constant ENTRY_FEE = 0.00015 ether; // ~50 KSh
    
    // Pool storage: matchweek => Pool
    mapping(uint256 => DataStructures.Pool) public pools;
    
    // Track user entries: matchweek => user => hasEntered
    mapping(uint256 => mapping(address => bool)) public hasUserEntered;
    
    // Events
    event PoolCreated(uint256 indexed matchweek, uint256 deadline, uint256 entryFee);
    event UserJoinedPool(uint256 indexed matchweek, address indexed user, uint256 amount);
    event PoolFinalized(uint256 indexed matchweek, address indexed winner, uint256 prize);
    
    // Constructor
    constructor() {}

    /**
     * @notice Create a new pool for a matchweek
     * @dev Only owner can create pools
     * @param matchweek The matchweek number (1-38)
     * @param deadline Submission deadline timestamp
     */
    function createPool(uint256 matchweek, uint256 deadline) 
        external 
        onlyOwner 
    {
        // Validation
        require(ValidationLibrary.isValidMatchweek(matchweek), "Invalid matchweek");
        require(ValidationLibrary.isValidDeadline(deadline), "Invalid deadline");
        require(!pools[matchweek].isActive, "Pool already exists");
        
        // Create pool
        pools[matchweek] = DataStructures.Pool({
            matchweek: matchweek,
            entryFee: ENTRY_FEE,
            deadline: deadline,
            totalPrize: 0,
            participants: new address[](0),
            isActive: true,
            isFinalized: false,
            winner: address(0),
            winningScore: 0
        });
        
        emit PoolCreated(matchweek, deadline, ENTRY_FEE);
    }

    /**
     * @notice Join a matchweek pool by paying entry fee
     * @dev User must pay exact entry fee and deadline must not have passed
     * @param matchweek The matchweek to join
     */
    function joinPool(uint256 matchweek) 
        external 
        payable 
        nonReentrant 
    {
        DataStructures.Pool storage pool = pools[matchweek];
        
        // Validation
        require(pool.isActive, "Pool does not exist");
        require(block.timestamp < pool.deadline, "Deadline has passed");
        require(msg.value == ENTRY_FEE, "Incorrect entry fee");
        require(!hasUserEntered[matchweek][msg.sender], "Already entered");
        
        // Add user to pool
        pool.participants.push(msg.sender);
        pool.totalPrize += msg.value;
        hasUserEntered[matchweek][msg.sender] = true;
        
        emit UserJoinedPool(matchweek, msg.sender, msg.value);
    }

    /**
     * @notice Get pool information
     * @param matchweek The matchweek number
     * @return pool The pool data
     */
    function getPool(uint256 matchweek) 
        external 
        view 
        returns (DataStructures.Pool memory pool) 
    {
        return pools[matchweek];
    }

    /**
     * @notice Get pool participants
     * @param matchweek The matchweek number
     * @return participants Array of participant addresses
     */
    function getParticipants(uint256 matchweek) 
        external 
        view 
        returns (address[] memory participants) 
    {
        return pools[matchweek].participants;
    }

    /**
     * @notice Check if user has entered a pool
     * @param matchweek The matchweek number
     * @param user The user address
     * @return hasEntered Whether user has entered
     */
    function hasUserEnteredPool(uint256 matchweek, address user) 
        external 
        view 
        returns (bool hasEntered) 
    {
        return hasUserEntered[matchweek][user];
    }

    /**
     * @notice Get participant count for a pool
     * @param matchweek The matchweek number
     * @return count Number of participants
     */
    function getParticipantCount(uint256 matchweek) 
        external 
        view 
        returns (uint256 count) 
    {
        return pools[matchweek].participants.length;
    }

    /**
     * @notice Finalize pool and set winner
     * @dev Called by scoring contract after matchweek completion
     * @param matchweek The matchweek number
     * @param winner The winning address
     * @param winningScore The winning score
     */
    function finalizePool(
        uint256 matchweek, 
        address winner, 
        uint256 winningScore
    ) 
        external 
        onlyOwner // Will be changed to scoring contract later
    {
        DataStructures.Pool storage pool = pools[matchweek];
        
        require(pool.isActive, "Pool does not exist");
        require(!pool.isFinalized, "Pool already finalized");
        require(block.timestamp >= pool.deadline, "Deadline not passed");
        require(hasUserEntered[matchweek][winner], "Winner not in pool");
        
        pool.isFinalized = true;
        pool.winner = winner;
        pool.winningScore = winningScore;
        
        emit PoolFinalized(matchweek, winner, pool.totalPrize);
    }

    /**
     * @notice Emergency function to pause pool creation
     * @dev Only owner can call this
     */
    function pausePool(uint256 matchweek) external onlyOwner {
        pools[matchweek].isActive = false;
    }

    /**
     * @notice Emergency withdrawal (only if pool not finalized)
     * @dev Refunds all participants if needed
     * @param matchweek The matchweek to refund
     */
    function emergencyRefund(uint256 matchweek) external onlyOwner {
        DataStructures.Pool storage pool = pools[matchweek];
        require(!pool.isFinalized, "Pool already finalized");
        
        _refundParticipants(matchweek);
        
        pool.isActive = false;
        pool.totalPrize = 0;
    }

    /**
     * @dev Internal function to refund participants
     * @param matchweek The matchweek to refund
     */
    function _refundParticipants(uint256 matchweek) internal {
        address[] memory participants = pools[matchweek].participants;
        uint256 length = participants.length;
        
        for (uint256 i = 0; i < length; i++) {
            payable(participants[i]).transfer(ENTRY_FEE);
        }
    }
}