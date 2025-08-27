// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/DataStructures.sol";
import "./libraries/ValidationLibrary.sol";

/**
 * @title TeamManager
 * @dev Manages team selection, validation, and storage for OnChain FPL
 */
contract TeamManager is Ownable, ReentrancyGuard {
    using ValidationLibrary for *;
    
    // Player storage: playerId => Player
    mapping(uint256 => DataStructures.Player) public players;
    
    // Team storage: matchweek => owner => Team
    mapping(uint256 => mapping(address => DataStructures.Team)) public teams;
    
    // Track team submissions: matchweek => owner => hasSubmitted
    mapping(uint256 => mapping(address => bool)) public hasSubmittedTeam;
    
    // Pool deadlines: matchweek => deadline
    mapping(uint256 => uint256) public poolDeadlines;
    
    // Events
    event PlayerAdded(uint256 indexed playerId, string name, Position position, uint256 price, uint256 teamId);
    event TeamSubmitted(uint256 indexed matchweek, address indexed owner, uint256 totalCost);
    event TeamUpdated(uint256 indexed matchweek, address indexed owner, uint256 totalCost);
    event PoolDeadlineSet(uint256 indexed matchweek, uint256 deadline);
    
    constructor() {}

    /**
     * @notice Add a player to the system (Owner only)
     * @param playerId Unique player ID
     * @param name Player name
     * @param position Player position
     * @param price Player price in pence
     * @param teamId EPL team ID (1-20)
     */
    function addPlayer(
        uint256 playerId,
        string memory name,
        Position position,
        uint256 price,
        uint256 teamId
    ) external onlyOwner {
        require(playerId > 0, "Invalid player ID");
        require(bytes(name).length > 0, "Invalid name");
        require(ValidationLibrary.isValidPosition(position), "Invalid position");
        require(ValidationLibrary.isValidPrice(price), "Invalid price");
        require(ValidationLibrary.isValidTeamId(teamId), "Invalid team ID");
        require(players[playerId].id == 0, "Player already exists");
        
        players[playerId] = DataStructures.Player({
            id: playerId,
            name: name,
            position: position,
            price: price,
            teamId: teamId,
            isActive: true
        });
        
        emit PlayerAdded(playerId, name, position, price, teamId);
    }

    /**
     * @notice Set pool deadline for a matchweek (Owner only)
     * @param matchweek The matchweek number
     * @param deadline The deadline timestamp
     */
    function setPoolDeadline(uint256 matchweek, uint256 deadline) external onlyOwner {
        require(ValidationLibrary.isValidMatchweek(matchweek), "Invalid matchweek");
        require(deadline > block.timestamp, "Deadline must be in future");
        
        poolDeadlines[matchweek] = deadline;
        emit PoolDeadlineSet(matchweek, deadline);
    }

    /**
     * @notice Submit team for a matchweek
     * @param matchweek The matchweek number
     * @param playerIds Array of 15 player IDs
     * @param startingLineup Indices of starting 11 players (0-14)
     * @param captainIndex Index of captain in starting lineup (0-10)
     * @param viceCaptainIndex Index of vice-captain in starting lineup (0-10)
     * @param formation Team formation
     */
    function submitTeam(
        uint256 matchweek,
        uint256[15] memory playerIds,
        uint256[11] memory startingLineup,
        uint256 captainIndex,
        uint256 viceCaptainIndex,
        Formation formation
    ) external nonReentrant {
        require(ValidationLibrary.isValidMatchweek(matchweek), "Invalid matchweek");
        require(block.timestamp < poolDeadlines[matchweek], "Deadline passed");
        require(captainIndex != viceCaptainIndex, "Captain and vice-captain must be different");
        require(captainIndex < 11 && viceCaptainIndex < 11, "Invalid captain/vice-captain index");
        
        // Validate team
        uint256 totalCost = _validateTeam(playerIds, startingLineup, formation);
        
        // Store team
        teams[matchweek][msg.sender] = DataStructures.Team({
            owner: msg.sender,
            playerIds: playerIds,
            startingLineup: startingLineup,
            captainIndex: captainIndex,
            viceCaptainIndex: viceCaptainIndex,
            formation: formation,
            totalCost: totalCost,
            isSubmitted: true,
            submissionTime: block.timestamp
        });
        
        bool wasSubmitted = hasSubmittedTeam[matchweek][msg.sender];
        hasSubmittedTeam[matchweek][msg.sender] = true;
        
        if (wasSubmitted) {
            emit TeamUpdated(matchweek, msg.sender, totalCost);
        } else {
            emit TeamSubmitted(matchweek, msg.sender, totalCost);
        }
    }

    /**
     * @notice Get team for a matchweek
     * @param matchweek The matchweek number
     * @param owner The team owner
     * @return team The team data
     */
    function getTeam(uint256 matchweek, address owner) 
        external 
        view 
        returns (DataStructures.Team memory team) 
    {
        return teams[matchweek][owner];
    }

    /**
     * @notice Get player information
     * @param playerId The player ID
     * @return player The player data
     */
    function getPlayer(uint256 playerId) 
        external 
        view 
        returns (DataStructures.Player memory player) 
    {
        return players[playerId];
    }

    /**
     * @notice Check if user has submitted team for matchweek
     * @param matchweek The matchweek number
     * @param owner The team owner
     * @return hasSubmitted Whether team has been submitted
     */
    function hasUserSubmittedTeam(uint256 matchweek, address owner) 
        external 
        view 
        returns (bool hasSubmitted) 
    {
        return hasSubmittedTeam[matchweek][owner];
    }

    /**
     * @dev Internal function to validate team constraints
     * @param playerIds Array of 15 player IDs
     * @param startingLineup Indices of starting 11 players
     * @param formation Team formation
     * @return totalCost Total cost of the team
     */
    function _validateTeam(
        uint256[15] memory playerIds,
        uint256[11] memory startingLineup,
        Formation formation
    ) internal view returns (uint256 totalCost) {
        // Validate formation
        require(ValidationLibrary.isValidFormation(formation), "Invalid formation");
        
        // Validate starting lineup indices
        for (uint256 i = 0; i < 11; i++) {
            require(startingLineup[i] < 15, "Invalid starting lineup index");
        }
        
        // Check for duplicate players and calculate cost
        uint256[21] memory teamCounts; // teamId => count
        uint256[4] memory positionCounts; // position => count
        uint256[4] memory startingPositionCounts; // position => count in starting XI
        
        for (uint256 i = 0; i < 15; i++) {
            uint256 playerId = playerIds[i];
            require(playerId > 0, "Invalid player ID");
            
            DataStructures.Player memory player = players[playerId];
            require(player.id != 0, "Player does not exist");
            require(player.isActive, "Player not active");
            
            // Check for duplicates
            for (uint256 j = i + 1; j < 15; j++) {
                require(playerIds[i] != playerIds[j], "Duplicate player");
            }
            
            totalCost += player.price;
            teamCounts[player.teamId]++;
            positionCounts[uint256(player.position)]++;
        }
        
        // Validate budget
        require(totalCost <= DataStructures.MAX_BUDGET, "Exceeds budget limit");
        
        // Validate squad composition (2 GK, 5 DEF, 5 MID, 3 FWD)
        require(positionCounts[0] == 2, "Must have exactly 2 goalkeepers");
        require(positionCounts[1] == 5, "Must have exactly 5 defenders");
        require(positionCounts[2] == 5, "Must have exactly 5 midfielders");
        require(positionCounts[3] == 3, "Must have exactly 3 forwards");
        
        // Validate team limits (max 3 players per EPL team)
        for (uint256 i = 1; i <= DataStructures.TOTAL_EPL_TEAMS; i++) {
            require(teamCounts[i] <= DataStructures.MAX_PLAYERS_PER_TEAM, "Too many players from same team");
        }
        
        // Validate starting XI formation
        _validateStartingFormation(playerIds, startingLineup, formation);
    }

    /**
     * @dev Internal function to validate starting XI formation
     * @param playerIds Array of 15 player IDs
     * @param startingLineup Indices of starting 11 players
     * @param formation Team formation
     */
    function _validateStartingFormation(
        uint256[15] memory playerIds,
        uint256[11] memory startingLineup,
        Formation formation
    ) internal view {
        DataStructures.FormationCount memory required = ValidationLibrary.getFormationCounts(formation);
        uint256[4] memory startingCounts; // position => count in starting XI
        
        for (uint256 i = 0; i < 11; i++) {
            uint256 playerIndex = startingLineup[i];
            uint256 playerId = playerIds[playerIndex];
            DataStructures.Player memory player = players[playerId];
            startingCounts[uint256(player.position)]++;
        }
        
        require(startingCounts[0] == required.goalkeepers, "Invalid goalkeeper count in starting XI");
        require(startingCounts[1] == required.defenders, "Invalid defender count in starting XI");
        require(startingCounts[2] == required.midfielders, "Invalid midfielder count in starting XI");
        require(startingCounts[3] == required.forwards, "Invalid forward count in starting XI");
    }
}