// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Enums.sol";

/**
 * @title DataStructures
 * @dev Core data structures for OnChain FPL
 */
library DataStructures {
    
    /// @dev Player information structure
    struct Player {
        uint256 id;              // Unique player ID
        string name;             // Player name
        Position position;       // Player position (GK, DEF, MID, FWD)
        uint256 price;          // Player price in pence (e.g., 8500000 = £8.5M)
        uint256 teamId;         // EPL team ID (1-20)
        bool isActive;          // Whether player is available for selection
    }
    
    /// @dev Fantasy team structure
    struct Team {
        address owner;           // Team owner address
        uint256[15] playerIds;   // Array of 15 player IDs
        uint256[11] startingLineup; // Indices of starting 11 players (0-14)
        uint256 captainIndex;    // Index of captain in starting lineup (0-10)
        uint256 viceCaptainIndex; // Index of vice-captain in starting lineup (0-10)
        Formation formation;     // Team formation
        uint256 totalCost;      // Total team cost in pence
        bool isSubmitted;       // Whether team has been submitted
        uint256 submissionTime; // When team was submitted
    }
    
    /// @dev Matchweek pool structure
    struct Pool {
        uint256 matchweek;      // Matchweek number (1-38)
        uint256 entryFee;       // Entry fee in wei
        uint256 deadline;       // Submission deadline timestamp
        uint256 totalPrize;     // Total prize pool in wei
        address[] participants; // Array of participant addresses
        bool isActive;          // Whether pool is accepting entries
        bool isFinalized;       // Whether pool has been finalized
        address winner;         // Winner address (set after scoring)
        uint256 winningScore;   // Winning score
    }
    
    /// @dev Player performance data for a matchweek
    struct PlayerPerformance {
        uint256 playerId;       // Player ID
        uint256 matchweek;      // Matchweek number
        uint256 goals;          // Goals scored
        uint256 assists;        // Assists made
        uint256 minutesPlayed;  // Minutes played
        bool cleanSheet;        // Whether player kept clean sheet
        uint256 saves;          // Saves made (goalkeepers only)
        int256 cards;           // Cards received (-1 yellow, -3 red)
        bool ownGoal;           // Whether player scored own goal
        bool penaltyMiss;       // Whether player missed penalty
        uint256 bonusPoints;    // Bonus points awarded
        bool isValidated;       // Whether data has been validated
    }
    
    /// @dev Team score for a matchweek
    struct TeamScore {
        address owner;          // Team owner
        uint256 matchweek;      // Matchweek number
        uint256 totalPoints;    // Total points scored
        uint256[11] playerPoints; // Points for each starting player
        uint256 benchPoints;    // Points from bench players (auto-subs)
        uint256 captainPoints;  // Captain points (doubled)
        bool isCalculated;      // Whether score has been calculated
        uint256 calculationTime; // When score was calculated
    }
    
    /// @dev Formation validation structure
    struct FormationCount {
        uint256 goalkeepers;    // Number of goalkeepers
        uint256 defenders;      // Number of defenders
        uint256 midfielders;    // Number of midfielders
        uint256 forwards;       // Number of forwards
    }
    
    /// @dev Constants for FPL rules
    uint256 constant MAX_BUDGET = 100_000_000; // £100M in pence
    uint256 constant SQUAD_SIZE = 15;          // Total squad size
    uint256 constant STARTING_XI = 11;         // Starting lineup size
    uint256 constant MAX_PLAYERS_PER_TEAM = 3; // Max players from same EPL team
    uint256 constant TOTAL_EPL_TEAMS = 20;     // Number of EPL teams
    uint256 constant MAX_MATCHWEEKS = 38;      // Total matchweeks in season
    
    /// @dev FPL scoring constants
    uint256 constant GOAL_POINTS_GK_DEF = 6;   // Goals for GK/DEF
    uint256 constant GOAL_POINTS_MID = 5;      // Goals for MID
    uint256 constant GOAL_POINTS_FWD = 4;      // Goals for FWD
    uint256 constant ASSIST_POINTS = 3;        // Assists all positions
    uint256 constant CLEAN_SHEET_GK_DEF = 4;   // Clean sheet GK/DEF
    uint256 constant CLEAN_SHEET_MID = 1;      // Clean sheet MID
    uint256 constant MINUTES_PLAYED_FULL = 2;  // >60 minutes
    uint256 constant MINUTES_PLAYED_PARTIAL = 1; // <60 minutes
    uint256 constant SAVES_PER_POINT = 3;      // Every 3 saves = 1 point
    uint256 constant PENALTY_SAVE_POINTS = 5;  // Penalty save
}