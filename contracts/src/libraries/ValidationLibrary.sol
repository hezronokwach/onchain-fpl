// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DataStructures.sol";
import "./Enums.sol";

/**
 * @title ValidationLibrary
 * @dev Validation functions for OnChain FPL
 */
library ValidationLibrary {
    using DataStructures for *;
    
    /// @dev Validate formation requirements
    /// @param formation The formation to validate
    /// @return counts The position counts for the formation
    function getFormationCounts(Formation formation) 
        internal 
        pure 
        returns (DataStructures.FormationCount memory counts) 
    {
        counts.goalkeepers = 1; // Always 1 GK
        
        if (formation == Formation.F_3_4_3) {
            counts.defenders = 3;
            counts.midfielders = 4;
            counts.forwards = 3;
        } else if (formation == Formation.F_3_5_2) {
            counts.defenders = 3;
            counts.midfielders = 5;
            counts.forwards = 2;
        } else if (formation == Formation.F_4_3_3) {
            counts.defenders = 4;
            counts.midfielders = 3;
            counts.forwards = 3;
        } else if (formation == Formation.F_4_4_2) {
            counts.defenders = 4;
            counts.midfielders = 4;
            counts.forwards = 2;
        } else if (formation == Formation.F_4_5_1) {
            counts.defenders = 4;
            counts.midfielders = 5;
            counts.forwards = 1;
        } else if (formation == Formation.F_5_3_2) {
            counts.defenders = 5;
            counts.midfielders = 3;
            counts.forwards = 2;
        } else if (formation == Formation.F_5_4_1) {
            counts.defenders = 5;
            counts.midfielders = 4;
            counts.forwards = 1;
        }
    }
    
    /// @dev Validate if a formation is valid
    /// @param formation The formation to validate
    /// @return isValid Whether the formation is valid
    function isValidFormation(Formation formation) internal pure returns (bool isValid) {
        return uint8(formation) <= uint8(Formation.F_5_4_1);
    }
    
    /// @dev Validate matchweek number
    /// @param matchweek The matchweek to validate
    /// @return isValid Whether the matchweek is valid
    function isValidMatchweek(uint256 matchweek) internal pure returns (bool isValid) {
        return matchweek > 0 && matchweek <= DataStructures.MAX_MATCHWEEKS;
    }
    
    /// @dev Validate deadline is in the future
    /// @param deadline The deadline timestamp to validate
    /// @return isValid Whether the deadline is valid
    function isValidDeadline(uint256 deadline) internal view returns (bool isValid) {
        return deadline > block.timestamp;
    }
    
    /// @dev Validate player position
    /// @param position The position to validate
    /// @return isValid Whether the position is valid
    function isValidPosition(Position position) internal pure returns (bool isValid) {
        return uint8(position) <= uint8(Position.FWD);
    }
    
    /// @dev Validate EPL team ID
    /// @param teamId The team ID to validate
    /// @return isValid Whether the team ID is valid
    function isValidTeamId(uint256 teamId) internal pure returns (bool isValid) {
        return teamId > 0 && teamId <= DataStructures.TOTAL_EPL_TEAMS;
    }
    
    /// @dev Validate player price
    /// @param price The price to validate
    /// @return isValid Whether the price is valid
    function isValidPrice(uint256 price) internal pure returns (bool isValid) {
        return price > 0 && price <= 15_000_000; // Max £15M per player
    }
    
    /// @dev Validate squad composition (2 GK, 5 DEF, 5 MID, 3 FWD)
    /// @param positionCounts Array of position counts [GK, DEF, MID, FWD]
    /// @return isValid Whether the squad composition is valid
    function isValidSquadComposition(uint256[4] memory positionCounts) internal pure returns (bool isValid) {
        return positionCounts[0] == 2 && // 2 Goalkeepers
               positionCounts[1] == 5 && // 5 Defenders
               positionCounts[2] == 5 && // 5 Midfielders
               positionCounts[3] == 3;   // 3 Forwards
    }
    
    /// @dev Validate team budget
    /// @param totalCost Total cost of the team
    /// @return isValid Whether the budget is valid
    function isValidBudget(uint256 totalCost) internal pure returns (bool isValid) {
        return totalCost <= DataStructures.MAX_BUDGET;
    }
    
    /// @dev Validate EPL team limits (max 3 players per team)
    /// @param teamCounts Array of team counts for each EPL team
    /// @return isValid Whether team limits are respected
    function isValidTeamLimits(uint256[21] memory teamCounts) internal pure returns (bool isValid) {
        for (uint256 i = 1; i <= DataStructures.TOTAL_EPL_TEAMS; i++) {
            if (teamCounts[i] > DataStructures.MAX_PLAYERS_PER_TEAM) {
                return false;
            }
        }
        return true;
    }
    
    /// @dev Validate starting lineup indices
    /// @param startingLineup Array of starting lineup indices
    /// @return isValid Whether all indices are valid (< 15)
    function isValidStartingLineup(uint256[11] memory startingLineup) internal pure returns (bool isValid) {
        for (uint256 i = 0; i < 11; i++) {
            if (startingLineup[i] >= DataStructures.SQUAD_SIZE) {
                return false;
            }
        }
        return true;
    }
    
    /// @dev Validate captain and vice-captain indices
    /// @param captainIndex Captain index in starting lineup
    /// @param viceCaptainIndex Vice-captain index in starting lineup
    /// @return isValid Whether captain indices are valid
    function isValidCaptainSelection(uint256 captainIndex, uint256 viceCaptainIndex) internal pure returns (bool isValid) {
        return captainIndex < DataStructures.STARTING_XI && 
               viceCaptainIndex < DataStructures.STARTING_XI && 
               captainIndex != viceCaptainIndex;
    }
}