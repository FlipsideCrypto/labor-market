export const abi = [
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "_market",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256[]",
        "name": "_auxiliaries",
        "type": "uint256[]"
      },
      {
        "indexed": false,
        "internalType": "uint256[]",
        "name": "_alphas",
        "type": "uint256[]"
      },
      {
        "indexed": false,
        "internalType": "uint256[]",
        "name": "_betas",
        "type": "uint256[]"
      }
    ],
    "name": "EnforcementConfigured",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "_market",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "_requestId",
        "type": "uint256"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "_submissionId",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "intentChange",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "earnings",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "remainder",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "bool",
        "name": "newSubmission",
        "type": "bool"
      }
    ],
    "name": "SubmissionReviewed",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "_requestId",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_submissionId",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_score",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_availableShare",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "_enforcer",
        "type": "address"
      }
    ],
    "name": "enforce",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      },
      {
        "internalType": "uint24",
        "name": "",
        "type": "uint24"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_market",
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
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_market",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_requestId",
        "type": "uint256"
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
      }
    ],
    "stateMutability": "nonpayable",
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
    "name": "marketToMaxScore",
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
        "internalType": "uint256",
        "name": "_requestId",
        "type": "uint256"
      }
    ],
    "name": "remainder",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "_requestId",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_submissionId",
        "type": "uint256"
      }
    ],
    "name": "rewards",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      },
      {
        "internalType": "bool",
        "name": "requiresSubmission",
        "type": "bool"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256[]",
        "name": "_auxilaries",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "_ranges",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "_weights",
        "type": "uint256[]"
      }
    ],
    "name": "setConfiguration",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
] as const
