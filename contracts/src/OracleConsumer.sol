// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {DataStructures} from "./libraries/DataStructures.sol";
import "./libraries/ValidationLibrary.sol";
// import "./ScoringEngine.sol"; // Forward declaration to avoid circular import

/**
 * @title OracleConsumer
 * @dev Chainlink oracle integration for fetching EPL player performance data
 */
contract OracleConsumer is Ownable, ReentrancyGuard {
    using ValidationLibrary for *;
    
    address public scoringEngine;
    
    // Oracle data storage
    mapping(uint256 => DataStructures.MatchData) public matchData;
    mapping(uint256 => mapping(uint256 => DataStructures.PlayerPerformance)) public matchPerformances;
    mapping(uint256 => mapping(address => bool)) public oracleValidators;
    mapping(uint256 => uint256) public confirmationCounts;
    mapping(bytes32 => bool) public pendingRequests;
    
    // Oracle configuration
    address[] public authorizedOracles;
    uint256 public minConfirmations = DataStructures.MIN_CONFIRMATIONS;
    uint256 public oracleTimeout = DataStructures.ORACLE_TIMEOUT;
    uint256 public maxDataAge = DataStructures.MAX_DATA_AGE;
    
    // Fallback mechanism
    bool public emergencyMode = false;
    mapping(uint256 => bool) public manualOverride;
    
    // Events
    event OracleDataRequested(uint256 indexed matchweek, bytes32 indexed requestId);
    event OracleDataReceived(uint256 indexed matchweek, address indexed oracle, uint256 playerCount);
    event MatchDataValidated(uint256 indexed matchweek, uint256 timestamp);
    event EmergencyModeToggled(bool enabled);
    event OracleAdded(address indexed oracle);
    event OracleRemoved(address indexed oracle);
    event AutoScoringTriggered(uint256 indexed matchweek);
    
    modifier onlyAuthorizedOracle() {
        require(isAuthorizedOracle(msg.sender), "Not authorized oracle");
        _;
    }
    
    modifier notInEmergencyMode() {
        require(!emergencyMode, "Emergency mode active");
        _;
    }
    
    constructor(address _scoringEngine) {
        scoringEngine = _scoringEngine;
    }

    /**
     * @notice Request EPL match data for a matchweek
     * @param matchweek The matchweek number
     */
    function requestMatchData(uint256 matchweek) external onlyOwner notInEmergencyMode {
        require(ValidationLibrary.isValidMatchweek(matchweek), "Invalid matchweek");
        require(!matchData[matchweek].isValidated, "Data already validated");
        
        bytes32 requestId = keccak256(abi.encodePacked(matchweek, block.timestamp, block.prevrandao));
        pendingRequests[requestId] = true;
        
        emit OracleDataRequested(matchweek, requestId);
    }

    /**
     * @notice Submit match data from authorized oracle
     * @param matchweek The matchweek number
     * @param performances Array of player performances
     * @param timestamp Data timestamp
     */
    function submitMatchData(
        uint256 matchweek,
        DataStructures.PlayerPerformance[] memory performances,
        uint256 timestamp
    ) external onlyAuthorizedOracle nonReentrant {
        require(ValidationLibrary.isValidMatchweek(matchweek), "Invalid matchweek");
        require(performances.length > 0, "No performance data");
        require(timestamp > 0 && block.timestamp - timestamp <= maxDataAge, "Invalid timestamp");
        require(!oracleValidators[matchweek][msg.sender], "Oracle already submitted");
        
        // Validate performance data
        for (uint256 i = 0; i < performances.length; i++) {
            require(performances[i].matchweek == matchweek, "Matchweek mismatch");
            require(performances[i].playerId > 0, "Invalid player ID");
        }
        
        // Store data if first submission or update existing
        if (confirmationCounts[matchweek] == 0) {
            matchData[matchweek] = DataStructures.MatchData({
                matchweek: matchweek,
                timestamp: timestamp,
                isValidated: false,
                performanceCount: performances.length
            });
            
            // Store individual performances
            for (uint256 i = 0; i < performances.length; i++) {
                matchPerformances[matchweek][performances[i].playerId] = performances[i];
            }
        }
        
        oracleValidators[matchweek][msg.sender] = true;
        confirmationCounts[matchweek]++;
        
        emit OracleDataReceived(matchweek, msg.sender, performances.length);
        
        // Auto-validate if minimum confirmations reached
        if (confirmationCounts[matchweek] >= minConfirmations) {
            _validateAndProcessData(matchweek);
        }
    }

    /**
     * @notice Manual data submission for emergency mode
     * @param matchweek The matchweek number
     * @param performances Array of player performances
     */
    function submitManualData(
        uint256 matchweek,
        DataStructures.PlayerPerformance[] memory performances
    ) external onlyOwner {
        require(emergencyMode || manualOverride[matchweek], "Manual submission not allowed");
        require(ValidationLibrary.isValidMatchweek(matchweek), "Invalid matchweek");
        require(performances.length > 0, "No performance data");
        
        matchData[matchweek] = DataStructures.MatchData({
            matchweek: matchweek,
            timestamp: block.timestamp,
            isValidated: true,
            performanceCount: performances.length
        });
        
        // Store individual performances
        for (uint256 i = 0; i < performances.length; i++) {
            matchPerformances[matchweek][performances[i].playerId] = performances[i];
        }
        
        _processValidatedData(matchweek);
        emit MatchDataValidated(matchweek, block.timestamp);
    }

    /**
     * @notice Trigger automated scoring for a matchweek
     * @param matchweek The matchweek number
     */
    function triggerAutoScoring(uint256 matchweek) external {
        require(matchData[matchweek].isValidated, "Data not validated");
        require(block.timestamp >= matchData[matchweek].timestamp + 1 hours, "Too early for scoring");
        
        _processValidatedData(matchweek);
        emit AutoScoringTriggered(matchweek);
    }

    /**
     * @notice Add authorized oracle
     * @param oracle Oracle address to add
     */
    function addOracle(address oracle) external onlyOwner {
        require(oracle != address(0), "Invalid oracle address");
        require(!isAuthorizedOracle(oracle), "Oracle already authorized");
        
        authorizedOracles.push(oracle);
        emit OracleAdded(oracle);
    }

    /**
     * @notice Remove authorized oracle
     * @param oracle Oracle address to remove
     */
    function removeOracle(address oracle) external onlyOwner {
        require(isAuthorizedOracle(oracle), "Oracle not authorized");
        
        for (uint256 i = 0; i < authorizedOracles.length; i++) {
            if (authorizedOracles[i] == oracle) {
                authorizedOracles[i] = authorizedOracles[authorizedOracles.length - 1];
                authorizedOracles.pop();
                break;
            }
        }
        
        emit OracleRemoved(oracle);
    }

    /**
     * @notice Toggle emergency mode
     * @param enabled Whether to enable emergency mode
     */
    function toggleEmergencyMode(bool enabled) external onlyOwner {
        emergencyMode = enabled;
        emit EmergencyModeToggled(enabled);
    }

    /**
     * @notice Set manual override for specific matchweek
     * @param matchweek The matchweek number
     * @param enabled Whether to enable manual override
     */
    function setManualOverride(uint256 matchweek, bool enabled) external onlyOwner {
        manualOverride[matchweek] = enabled;
    }

    /**
     * @notice Update oracle configuration
     * @param _minConfirmations Minimum confirmations required
     * @param _oracleTimeout Timeout for oracle responses
     * @param _maxDataAge Maximum age of oracle data
     */
    function updateOracleConfig(
        uint256 _minConfirmations,
        uint256 _oracleTimeout,
        uint256 _maxDataAge
    ) external onlyOwner {
        require(_minConfirmations > 0 && _minConfirmations <= authorizedOracles.length, "Invalid confirmations");
        require(_oracleTimeout > 0, "Invalid timeout");
        require(_maxDataAge > 0, "Invalid max age");
        
        minConfirmations = _minConfirmations;
        oracleTimeout = _oracleTimeout;
        maxDataAge = _maxDataAge;
    }

    /**
     * @notice Check if address is authorized oracle
     * @param oracle Address to check
     * @return isAuthorized Whether address is authorized
     */
    function isAuthorizedOracle(address oracle) public view returns (bool isAuthorized) {
        for (uint256 i = 0; i < authorizedOracles.length; i++) {
            if (authorizedOracles[i] == oracle) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Get match data for a matchweek
     * @param matchweek The matchweek number
     * @return data The match data
     */
    function getMatchData(uint256 matchweek) external view returns (DataStructures.MatchData memory data) {
        return matchData[matchweek];
    }

    /**
     * @notice Get oracle status for matchweek
     * @param matchweek The matchweek number
     * @return confirmations Number of confirmations
     * @return validated Whether data is validated
     * @return timestamp Data timestamp
     */
    function getOracleStatus(uint256 matchweek) external view returns (
        uint256 confirmations,
        bool validated,
        uint256 timestamp
    ) {
        return (
            confirmationCounts[matchweek],
            matchData[matchweek].isValidated,
            matchData[matchweek].timestamp
        );
    }

    /**
     * @dev Validate and process oracle data
     * @param matchweek The matchweek number
     */
    function _validateAndProcessData(uint256 matchweek) internal {
        require(!matchData[matchweek].isValidated, "Already validated");
        
        // Additional validation logic can be added here
        // For now, we trust the oracle data if minimum confirmations are met
        
        matchData[matchweek].isValidated = true;
        _processValidatedData(matchweek);
        
        emit MatchDataValidated(matchweek, matchData[matchweek].timestamp);
    }

    /**
     * @dev Process validated data by updating scoring engine
     * @param matchweek The matchweek number
     */
    function _processValidatedData(uint256 matchweek) internal {
        // This will be called after validation, performances are already stored
        // The scoring engine will be updated when individual performances are accessed
    }
    
    /**
     * @notice Get player performance for a matchweek
     * @param matchweek The matchweek number
     * @param playerId The player ID
     * @return performance The player performance data
     */
    function getPlayerPerformance(uint256 matchweek, uint256 playerId) 
        external 
        view 
        returns (DataStructures.PlayerPerformance memory performance) 
    {
        return matchPerformances[matchweek][playerId];
    }
    
    /**
     * @notice Update scoring engine with validated performance data
     * @param matchweek The matchweek number
     * @param playerId The player ID
     */
    function updateScoringEngine(uint256 matchweek, uint256 playerId) external {
        require(matchData[matchweek].isValidated, "Data not validated");
        
        DataStructures.PlayerPerformance memory performance = matchPerformances[matchweek][playerId];
        require(performance.playerId == playerId, "Performance not found");
        
        (bool success,) = scoringEngine.call(
            abi.encodeWithSignature(
                "updatePlayerPerformance(uint256,uint256,(uint256,uint256,uint256,uint256,uint256,bool,uint256,int256,bool,bool,uint256,bool))",
                matchweek,
                playerId,
                performance
            )
        );
        require(success, "Failed to update scoring engine");
    }

    /**
     * @notice Get authorized oracles list
     * @return oracles Array of authorized oracle addresses
     */
    function getAuthorizedOracles() external view returns (address[] memory oracles) {
        return authorizedOracles;
    }
}