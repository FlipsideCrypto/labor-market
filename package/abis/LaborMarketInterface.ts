export const abi = [
  {
    "inputs": [],
    "name": "getConfiguration",
    "outputs": [
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
        "name": "",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "requestId",
        "type": "uint256"
      }
    ],
    "name": "getRequest",
    "outputs": [
      {
        "components": [
          {
            "internalType": "address",
            "name": "serviceRequester",
            "type": "address"
          },
          {
            "internalType": "address",
            "name": "pToken",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "pTokenQ",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "signalExp",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "submissionExp",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "enforcementExp",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "submissionCount",
            "type": "uint256"
          },
          {
            "internalType": "string",
            "name": "uri",
            "type": "string"
          }
        ],
        "internalType": "struct LaborMarketInterface.ServiceRequest",
        "name": "",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "submissionId",
        "type": "uint256"
      }
    ],
    "name": "getSubmission",
    "outputs": [
      {
        "components": [
          {
            "internalType": "address",
            "name": "serviceProvider",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "requestId",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "timestamp",
            "type": "uint256"
          },
          {
            "internalType": "string",
            "name": "uri",
            "type": "string"
          }
        ],
        "internalType": "struct LaborMarketInterface.ServiceSubmission",
        "name": "",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
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
    "name": "initialize",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
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
    "name": "setConfiguration",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
] as const
