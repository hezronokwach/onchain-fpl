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
}