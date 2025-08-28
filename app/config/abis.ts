// Contract ABIs for OnChain FPL
export const POOL_MANAGER_ABI = [
  {
    "inputs": [{"type": "uint256", "name": "matchweek"}],
    "name": "joinPool",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [{"type": "uint256", "name": "matchweek"}],
    "name": "getPool",
    "outputs": [
      {
        "components": [
          {"type": "uint256", "name": "matchweek"},
          {"type": "uint256", "name": "entryFee"},
          {"type": "uint256", "name": "deadline"},
          {"type": "uint256", "name": "totalPrize"},
          {"type": "address[]", "name": "participants"},
          {"type": "bool", "name": "isActive"},
          {"type": "bool", "name": "isFinalized"},
          {"type": "address", "name": "winner"},
          {"type": "uint256", "name": "winningScore"}
        ],
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"type": "uint256", "name": "matchweek"}],
    "name": "getParticipants",
    "outputs": [{"type": "address[]", "name": "participants"}],
    "stateMutability": "view",
    "type": "function"
  }
] as const

export const TEAM_MANAGER_ABI = [
  {
    "inputs": [{"type": "uint256", "name": "playerId"}],
    "name": "getPlayer",
    "outputs": [
      {
        "components": [
          {"type": "uint256", "name": "id"},
          {"type": "string", "name": "name"},
          {"type": "uint8", "name": "position"},
          {"type": "uint256", "name": "price"},
          {"type": "uint256", "name": "teamId"},
          {"type": "bool", "name": "isActive"}
        ],
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
] as const