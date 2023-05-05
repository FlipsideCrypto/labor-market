export const abi = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_network",
        "type": "address"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "uint8",
        "name": "version",
        "type": "uint8"
      }
    ],
    "name": "Initialized",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "market",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "reputationToken",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "reputationTokenId",
        "type": "uint256"
      }
    ],
    "name": "MarketReputationConfigured",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "account",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "reputationToken",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "reputationTokenId",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "int256",
        "name": "amount",
        "type": "int256"
      }
    ],
    "name": "ReputationBalanceChange",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "reputationToken",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "reputationTokenId",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "decayRate",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "decayInterval",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "decayStartEpoch",
        "type": "uint256"
      }
    ],
    "name": "ReputationDecayConfigured",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "name": "accountInfo",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "lastDecayEpoch",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "frozenUntilEpoch",
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
        "name": "",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "name": "decayConfig",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "decayRate",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "decayInterval",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "decayStartEpoch",
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
        "name": "_availableReputation",
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
        "name": "",
        "type": "address"
      }
    ],
    "name": "marketRepConfig",
    "outputs": [
      {
        "internalType": "address",
        "name": "reputationToken",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "reputationTokenId",
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
    "inputs": [],
    "name": "network",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
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
