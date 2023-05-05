export const abi = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_implementation",
        "type": "address"
      },
      {
        "components": [
          {
            "internalType": "string",
            "name": "marketUri",
            "type": "string"
          },
          {
            "internalType": "address",
            "name": "owner",
            "type": "address"
          },
          {
            "components": [
              {
                "internalType": "address",
                "name": "network",
                "type": "address"
              },
              {
                "internalType": "address",
                "name": "reputation",
                "type": "address"
              },
              {
                "internalType": "address",
                "name": "enforcement",
                "type": "address"
              },
              {
                "internalType": "bytes32",
                "name": "enforcementKey",
                "type": "bytes32"
              }
            ],
            "internalType": "struct LaborMarketConfigurationInterface.Modules",
            "name": "modules",
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
            "name": "delegateBadge",
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
            "name": "maintainerBadge",
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
            "name": "reputationBadge",
            "type": "tuple"
          },
          {
            "components": [
              {
                "internalType": "uint256",
                "name": "rewardPool",
                "type": "uint256"
              },
              {
                "internalType": "uint256",
                "name": "provideStake",
                "type": "uint256"
              },
              {
                "internalType": "uint256",
                "name": "reviewStake",
                "type": "uint256"
              },
              {
                "internalType": "uint256",
                "name": "submitMin",
                "type": "uint256"
              },
              {
                "internalType": "uint256",
                "name": "submitMax",
                "type": "uint256"
              }
            ],
            "internalType": "struct LaborMarketConfigurationInterface.ReputationParams",
            "name": "reputationParams",
            "type": "tuple"
          }
        ],
        "internalType": "struct LaborMarketConfigurationInterface.LaborMarketConfiguration",
        "name": "_configuration",
        "type": "tuple"
      }
    ],
    "name": "createLaborMarket",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "_versionKey",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "_sender",
        "type": "address"
      }
    ],
    "name": "getLicenseKey",
    "outputs": [
      {
        "internalType": "bytes32",
        "name": "",
        "type": "bytes32"
      }
    ],
    "stateMutability": "pure",
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
    "name": "getVersionKey",
    "outputs": [
      {
        "internalType": "bytes32",
        "name": "",
        "type": "bytes32"
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
      },
      {
        "internalType": "address",
        "name": "_owner",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_tokenAddress",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_tokenId",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_amount",
        "type": "uint256"
      },
      {
        "internalType": "bool",
        "name": "_locked",
        "type": "bool"
      }
    ],
    "name": "setVersion",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
] as const
