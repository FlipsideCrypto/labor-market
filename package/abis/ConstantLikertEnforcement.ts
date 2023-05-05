export const abi = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_laborMarket",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_submissionId",
        "type": "uint256"
      }
    ],
    "name": "getPaymentReward",
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
        "internalType": "uint256",
        "name": "_requestId",
        "type": "uint256"
      }
    ],
    "name": "getRemainder",
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
        "internalType": "uint256",
        "name": "_submissionId",
        "type": "uint256"
      }
    ],
    "name": "getReputationReward",
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
        "internalType": "uint256",
        "name": "_submissionId",
        "type": "uint256"
      }
    ],
    "name": "getRewards",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      },
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
        "internalType": "uint256",
        "name": "_submissionId",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_score",
        "type": "uint256"
      }
    ],
    "name": "review",
    "outputs": [],
    "stateMutability": "nonpayable",
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
    "name": "submissionToScores",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "reviewCount",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "reviewSum",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "avg",
        "type": "uint256"
      },
      {
        "internalType": "bool",
        "name": "qualified",
        "type": "bool"
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
    "name": "totalAvgSum",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
] as const
