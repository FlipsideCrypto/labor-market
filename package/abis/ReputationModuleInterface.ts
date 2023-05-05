export const abi = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_reputationToken",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_reputationTokenId",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_frozenUntilEpoch",
        "type": "uint256"
      }
    ],
    "name": "freezeReputation",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_laborMarket",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_account",
        "type": "address"
      }
    ],
    "name": "getAvailableReputation",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_laborMarket",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_account",
        "type": "address"
      }
    ],
    "name": "getPendingDecay",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_account",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_amount",
        "type": "uint256"
      }
    ],
    "name": "mintReputation",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_account",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_amount",
        "type": "uint256"
      }
    ],
    "name": "revokeReputation",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_reputationToken",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_reputationTokenId",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_decayRate",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_decayInterval",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_decayStartEpoch",
        "type": "uint256"
      }
    ],
    "name": "setDecayConfig",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_laborMarket",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_reputationToken",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_reputationTokenId",
        "type": "uint256"
      }
    ],
    "name": "useReputationModule",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
] as const
