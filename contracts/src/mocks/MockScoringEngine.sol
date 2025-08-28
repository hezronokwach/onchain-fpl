// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/DataStructures.sol";

contract MockScoringEngine {
    mapping(uint256 => mapping(address => DataStructures.TeamScore)) public teamScores;
    mapping(uint256 => mapping(address => uint256)) public teamGoals;
    mapping(uint256 => mapping(address => uint256)) public teamCards;
    mapping(uint256 => bool) public matchweekScored;
    
    function setTeamScore(
        uint256 matchweek, 
        address user, 
        uint256 totalPoints, 
        uint256 benchPoints, 
        uint256 captainPoints
    ) external {
        uint256[11] memory playerPoints;
        for (uint256 i = 0; i < 11; i++) {
            playerPoints[i] = totalPoints / 11;
        }
        
        teamScores[matchweek][user] = DataStructures.TeamScore({
            owner: user,
            matchweek: matchweek,
            totalPoints: totalPoints,
            playerPoints: playerPoints,
            benchPoints: benchPoints,
            captainPoints: captainPoints,
            isCalculated: true,
            calculationTime: block.timestamp
        });
    }
    
    function setTeamGoals(uint256 matchweek, address user, uint256 goals) external {
        teamGoals[matchweek][user] = goals;
    }
    
    function setTeamCards(uint256 matchweek, address user, uint256 cards) external {
        teamCards[matchweek][user] = cards;
    }
    
    function setMatchweekScored(uint256 matchweek, bool scored) external {
        matchweekScored[matchweek] = scored;
    }
    
    function getTeamScore(uint256 matchweek, address user) 
        external view returns (DataStructures.TeamScore memory) {
        return teamScores[matchweek][user];
    }
    
    function isMatchweekScored(uint256 matchweek) external view returns (bool) {
        return matchweekScored[matchweek];
    }
    
    function getTeamGoals(uint256 matchweek, address user) external view returns (uint256) {
        return teamGoals[matchweek][user];
    }
    
    function getTeamCards(uint256 matchweek, address user) external view returns (uint256) {
        return teamCards[matchweek][user];
    }
}