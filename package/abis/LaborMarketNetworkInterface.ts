export const abi = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_sender",
        "type": "address"
      }
    ],
    "name": "isCreator",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
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
        "name": "_sender",
        "type": "address"
      }
    ],
    "name": "isGovernor",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
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
        "name": "_implementation",
        "type": "address"
      }
    ],
    "name": "setCapacityImplementation",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "components": [
          {
            "internalType": "address",
            "name": "token",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "tokenId",
            "type": "uint256"
          }
        ],
        "internalType": "struct LaborMarketConfigurationInterface.BadgePair",
        "name": "_governorBadge",
        "type": "tuple"
      },
      {
        "components": [
          {
            "internalType": "address",
            "name": "token",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "tokenId",
            "type": "uint256"
          }
        ],
        "internalType": "struct LaborMarketConfigurationInterface.BadgePair",
        "name": "_creatorBadge",
        "type": "tuple"
      }
    ],
    "name": "setNetworkRoles",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_reputationModule",
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
    "name": "setReputationDecay",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
] as const
