// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Enums
 * @dev Enumerations for OnChain FPL
 */

/// @dev Player positions in football
enum Position {
    GK,  // Goalkeeper
    DEF, // Defender  
    MID, // Midfielder
    FWD  // Forward
}

/// @dev Valid FPL formations
enum Formation {
    F_3_4_3, // 3 Defenders, 4 Midfielders, 3 Forwards
    F_3_5_2, // 3 Defenders, 5 Midfielders, 2 Forwards
    F_4_3_3, // 4 Defenders, 3 Midfielders, 3 Forwards
    F_4_4_2, // 4 Defenders, 4 Midfielders, 2 Forwards
    F_4_5_1, // 4 Defenders, 5 Midfielders, 1 Forward
    F_5_3_2, // 5 Defenders, 3 Midfielders, 2 Forwards
    F_5_4_1  // 5 Defenders, 4 Midfielders, 1 Forward
}