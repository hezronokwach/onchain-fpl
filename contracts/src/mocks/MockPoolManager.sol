// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/DataStructures.sol";

contract MockPoolManager {
    mapping(uint256 => address[]) public participants;
    mapping(uint256 => uint256) public totalPrizes;
    mapping(uint256 => bool) public isFinalized;
    mapping(uint256 => address) public winners;
    mapping(uint256 => uint256) public winningScores;
    
    function setParticipants(uint256 matchweek, address[] memory _participants) external {
        participants[matchweek] = _participants;
    }
    
    function setTotalPrize(uint256 matchweek, uint256 amount) external {
        totalPrizes[matchweek] = amount;
    }
    
    function getParticipants(uint256 matchweek) external view returns (address[] memory) {
        return participants[matchweek];
    }
    
    function getPool(uint256 matchweek) external view returns (DataStructures.Pool memory pool) {
        pool.totalPrize = totalPrizes[matchweek];
        pool.matchweek = matchweek;
        pool.isActive = true;
        pool.isFinalized = isFinalized[matchweek];
        pool.winner = winners[matchweek];
        pool.winningScore = winningScores[matchweek];
        pool.participants = participants[matchweek];
        pool.entryFee = 0.00015 ether;
        pool.deadline = block.timestamp + 1 hours;
    }
    
    function finalizePool(uint256 matchweek, address winner, uint256 winningScore) external {
        isFinalized[matchweek] = true;
        winners[matchweek] = winner;
        winningScores[matchweek] = winningScore;
    }
}