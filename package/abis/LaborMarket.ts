export const abi = [
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
        "indexed": true,
        "internalType": "struct LaborMarketConfigurationInterface.LaborMarketConfiguration",
        "name": "configuration",
        "type": "tuple"
      }
    ],
    "name": "LaborMarketConfigured",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "claimer",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "requestId",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "remainderAmount",
        "type": "uint256"
      }
    ],
    "name": "RemainderClaimed",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "requester",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "requestId",
        "type": "uint256"
      },
      {
        "indexed": true,
        "internalType": "string",
        "name": "uri",
        "type": "string"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "pToken",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "pTokenQ",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "signalExp",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "submissionExp",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "enforcementExp",
        "type": "uint256"
      }
    ],
    "name": "RequestConfigured",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "fulfiller",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "requestId",
        "type": "uint256"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "submissionId",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "string",
        "name": "uri",
        "type": "string"
      }
    ],
    "name": "RequestFulfilled",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "claimer",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "requestId",
        "type": "uint256"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "submissionId",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "payAmount",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "to",
        "type": "address"
      }
    ],
    "name": "RequestPayClaimed",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "reviewer",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "requestId",
        "type": "uint256"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "submissionId",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "reviewScore",
        "type": "uint256"
      }
    ],
    "name": "RequestReviewed",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "signaler",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "requestId",
        "type": "uint256"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "signalAmount",
        "type": "uint256"
      }
    ],
    "name": "RequestSignal",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "requestId",
        "type": "uint256"
      }
    ],
    "name": "RequestWithdrawn",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "signaler",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "requestId",
        "type": "uint256"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "quantity",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "signalAmount",
        "type": "uint256"
      }
    ],
    "name": "ReviewSignal",
    "type": "event"
  },
  {
    "inputs": [
      {
        "components": [
          {
            "internalType": "address",
            "name": "enforcer",
            "type": "address"
          },
          {
            "internalType": "bytes",
            "name": "terms",
            "type": "bytes"
          }
        ],
        "internalType": "struct Caveat[]",
        "name": "_input",
        "type": "tuple[]"
      }
    ],
    "name": "GET_CAVEAT_ARRAY_PACKETHASH",
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
        "components": [
          {
            "internalType": "address",
            "name": "enforcer",
            "type": "address"
          },
          {
            "internalType": "bytes",
            "name": "terms",
            "type": "bytes"
          }
        ],
        "internalType": "struct Caveat",
        "name": "_input",
        "type": "tuple"
      }
    ],
    "name": "GET_CAVEAT_PACKETHASH",
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
        "components": [
          {
            "internalType": "address",
            "name": "delegate",
            "type": "address"
          },
          {
            "internalType": "bytes32",
            "name": "authority",
            "type": "bytes32"
          },
          {
            "components": [
              {
                "internalType": "address",
                "name": "enforcer",
                "type": "address"
              },
              {
                "internalType": "bytes",
                "name": "terms",
                "type": "bytes"
              }
            ],
            "internalType": "struct Caveat[]",
            "name": "caveats",
            "type": "tuple[]"
          }
        ],
        "internalType": "struct Delegation",
        "name": "_input",
        "type": "tuple"
      }
    ],
    "name": "GET_DELEGATION_PACKETHASH",
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
        "components": [
          {
            "components": [
              {
                "components": [
                  {
                    "internalType": "address",
                    "name": "to",
                    "type": "address"
                  },
                  {
                    "internalType": "uint256",
                    "name": "gasLimit",
                    "type": "uint256"
                  },
                  {
                    "internalType": "bytes",
                    "name": "data",
                    "type": "bytes"
                  }
                ],
                "internalType": "struct Transaction",
                "name": "transaction",
                "type": "tuple"
              },
              {
                "components": [
                  {
                    "components": [
                      {
                        "internalType": "address",
                        "name": "delegate",
                        "type": "address"
                      },
                      {
                        "internalType": "bytes32",
                        "name": "authority",
                        "type": "bytes32"
                      },
                      {
                        "components": [
                          {
                            "internalType": "address",
                            "name": "enforcer",
                            "type": "address"
                          },
                          {
                            "internalType": "bytes",
                            "name": "terms",
                            "type": "bytes"
                          }
                        ],
                        "internalType": "struct Caveat[]",
                        "name": "caveats",
                        "type": "tuple[]"
                      }
                    ],
                    "internalType": "struct Delegation",
                    "name": "delegation",
                    "type": "tuple"
                  },
                  {
                    "internalType": "bytes",
                    "name": "signature",
                    "type": "bytes"
                  }
                ],
                "internalType": "struct SignedDelegation[]",
                "name": "authority",
                "type": "tuple[]"
              }
            ],
            "internalType": "struct Invocation[]",
            "name": "batch",
            "type": "tuple[]"
          },
          {
            "components": [
              {
                "internalType": "uint256",
                "name": "nonce",
                "type": "uint256"
              },
              {
                "internalType": "uint256",
                "name": "queue",
                "type": "uint256"
              }
            ],
            "internalType": "struct ReplayProtection",
            "name": "replayProtection",
            "type": "tuple"
          }
        ],
        "internalType": "struct Invocations",
        "name": "_input",
        "type": "tuple"
      }
    ],
    "name": "GET_INVOCATIONS_PACKETHASH",
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
        "components": [
          {
            "components": [
              {
                "internalType": "address",
                "name": "to",
                "type": "address"
              },
              {
                "internalType": "uint256",
                "name": "gasLimit",
                "type": "uint256"
              },
              {
                "internalType": "bytes",
                "name": "data",
                "type": "bytes"
              }
            ],
            "internalType": "struct Transaction",
            "name": "transaction",
            "type": "tuple"
          },
          {
            "components": [
              {
                "components": [
                  {
                    "internalType": "address",
                    "name": "delegate",
                    "type": "address"
                  },
                  {
                    "internalType": "bytes32",
                    "name": "authority",
                    "type": "bytes32"
                  },
                  {
                    "components": [
                      {
                        "internalType": "address",
                        "name": "enforcer",
                        "type": "address"
                      },
                      {
                        "internalType": "bytes",
                        "name": "terms",
                        "type": "bytes"
                      }
                    ],
                    "internalType": "struct Caveat[]",
                    "name": "caveats",
                    "type": "tuple[]"
                  }
                ],
                "internalType": "struct Delegation",
                "name": "delegation",
                "type": "tuple"
              },
              {
                "internalType": "bytes",
                "name": "signature",
                "type": "bytes"
              }
            ],
            "internalType": "struct SignedDelegation[]",
            "name": "authority",
            "type": "tuple[]"
          }
        ],
        "internalType": "struct Invocation[]",
        "name": "_input",
        "type": "tuple[]"
      }
    ],
    "name": "GET_INVOCATION_ARRAY_PACKETHASH",
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
        "components": [
          {
            "components": [
              {
                "internalType": "address",
                "name": "to",
                "type": "address"
              },
              {
                "internalType": "uint256",
                "name": "gasLimit",
                "type": "uint256"
              },
              {
                "internalType": "bytes",
                "name": "data",
                "type": "bytes"
              }
            ],
            "internalType": "struct Transaction",
            "name": "transaction",
            "type": "tuple"
          },
          {
            "components": [
              {
                "components": [
                  {
                    "internalType": "address",
                    "name": "delegate",
                    "type": "address"
                  },
                  {
                    "internalType": "bytes32",
                    "name": "authority",
                    "type": "bytes32"
                  },
                  {
                    "components": [
                      {
                        "internalType": "address",
                        "name": "enforcer",
                        "type": "address"
                      },
                      {
                        "internalType": "bytes",
                        "name": "terms",
                        "type": "bytes"
                      }
                    ],
                    "internalType": "struct Caveat[]",
                    "name": "caveats",
                    "type": "tuple[]"
                  }
                ],
                "internalType": "struct Delegation",
                "name": "delegation",
                "type": "tuple"
              },
              {
                "internalType": "bytes",
                "name": "signature",
                "type": "bytes"
              }
            ],
            "internalType": "struct SignedDelegation[]",
            "name": "authority",
            "type": "tuple[]"
          }
        ],
        "internalType": "struct Invocation",
        "name": "_input",
        "type": "tuple"
      }
    ],
    "name": "GET_INVOCATION_PACKETHASH",
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
        "components": [
          {
            "internalType": "uint256",
            "name": "nonce",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "queue",
            "type": "uint256"
          }
        ],
        "internalType": "struct ReplayProtection",
        "name": "_input",
        "type": "tuple"
      }
    ],
    "name": "GET_REPLAYPROTECTION_PACKETHASH",
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
        "components": [
          {
            "components": [
              {
                "internalType": "address",
                "name": "delegate",
                "type": "address"
              },
              {
                "internalType": "bytes32",
                "name": "authority",
                "type": "bytes32"
              },
              {
                "components": [
                  {
                    "internalType": "address",
                    "name": "enforcer",
                    "type": "address"
                  },
                  {
                    "internalType": "bytes",
                    "name": "terms",
                    "type": "bytes"
                  }
                ],
                "internalType": "struct Caveat[]",
                "name": "caveats",
                "type": "tuple[]"
              }
            ],
            "internalType": "struct Delegation",
            "name": "delegation",
            "type": "tuple"
          },
          {
            "internalType": "bytes",
            "name": "signature",
            "type": "bytes"
          }
        ],
        "internalType": "struct SignedDelegation[]",
        "name": "_input",
        "type": "tuple[]"
      }
    ],
    "name": "GET_SIGNEDDELEGATION_ARRAY_PACKETHASH",
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
        "components": [
          {
            "components": [
              {
                "internalType": "address",
                "name": "delegate",
                "type": "address"
              },
              {
                "internalType": "bytes32",
                "name": "authority",
                "type": "bytes32"
              },
              {
                "components": [
                  {
                    "internalType": "address",
                    "name": "enforcer",
                    "type": "address"
                  },
                  {
                    "internalType": "bytes",
                    "name": "terms",
                    "type": "bytes"
                  }
                ],
                "internalType": "struct Caveat[]",
                "name": "caveats",
                "type": "tuple[]"
              }
            ],
            "internalType": "struct Delegation",
            "name": "delegation",
            "type": "tuple"
          },
          {
            "internalType": "bytes",
            "name": "signature",
            "type": "bytes"
          }
        ],
        "internalType": "struct SignedDelegation",
        "name": "_input",
        "type": "tuple"
      }
    ],
    "name": "GET_SIGNEDDELEGATION_PACKETHASH",
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
        "components": [
          {
            "internalType": "address",
            "name": "to",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "gasLimit",
            "type": "uint256"
          },
          {
            "internalType": "bytes",
            "name": "data",
            "type": "bytes"
          }
        ],
        "internalType": "struct Transaction",
        "name": "_input",
        "type": "tuple"
      }
    ],
    "name": "GET_TRANSACTION_PACKETHASH",
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
        "internalType": "uint256",
        "name": "_submissionId",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "_to",
        "type": "address"
      }
    ],
    "name": "claim",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "pTokenClaimed",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "rTokenClaimed",
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
      }
    ],
    "name": "claimRemainder",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "configuration",
    "outputs": [
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
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "components": [
          {
            "components": [
              {
                "internalType": "address",
                "name": "to",
                "type": "address"
              },
              {
                "internalType": "uint256",
                "name": "gasLimit",
                "type": "uint256"
              },
              {
                "internalType": "bytes",
                "name": "data",
                "type": "bytes"
              }
            ],
            "internalType": "struct Transaction",
            "name": "transaction",
            "type": "tuple"
          },
          {
            "components": [
              {
                "components": [
                  {
                    "internalType": "address",
                    "name": "delegate",
                    "type": "address"
                  },
                  {
                    "internalType": "bytes32",
                    "name": "authority",
                    "type": "bytes32"
                  },
                  {
                    "components": [
                      {
                        "internalType": "address",
                        "name": "enforcer",
                        "type": "address"
                      },
                      {
                        "internalType": "bytes",
                        "name": "terms",
                        "type": "bytes"
                      }
                    ],
                    "internalType": "struct Caveat[]",
                    "name": "caveats",
                    "type": "tuple[]"
                  }
                ],
                "internalType": "struct Delegation",
                "name": "delegation",
                "type": "tuple"
              },
              {
                "internalType": "bytes",
                "name": "signature",
                "type": "bytes"
              }
            ],
            "internalType": "struct SignedDelegation[]",
            "name": "authority",
            "type": "tuple[]"
          }
        ],
        "internalType": "struct Invocation[]",
        "name": "batch",
        "type": "tuple[]"
      }
    ],
    "name": "contractInvoke",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "domainHash",
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
        "internalType": "uint256",
        "name": "_requestId",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "_pToken",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_pTokenQ",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_signalExp",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_submissionExp",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_enforcementExp",
        "type": "uint256"
      },
      {
        "internalType": "string",
        "name": "_requestUri",
        "type": "string"
      }
    ],
    "name": "editRequest",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
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
        "components": [
          {
            "internalType": "address",
            "name": "delegate",
            "type": "address"
          },
          {
            "internalType": "bytes32",
            "name": "authority",
            "type": "bytes32"
          },
          {
            "components": [
              {
                "internalType": "address",
                "name": "enforcer",
                "type": "address"
              },
              {
                "internalType": "bytes",
                "name": "terms",
                "type": "bytes"
              }
            ],
            "internalType": "struct Caveat[]",
            "name": "caveats",
            "type": "tuple[]"
          }
        ],
        "internalType": "struct Delegation",
        "name": "delegation",
        "type": "tuple"
      }
    ],
    "name": "getDelegationTypedDataHash",
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
        "internalType": "string",
        "name": "contractName",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "version",
        "type": "string"
      },
      {
        "internalType": "uint256",
        "name": "chainId",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "verifyingContract",
        "type": "address"
      }
    ],
    "name": "getEIP712DomainHash",
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
        "components": [
          {
            "components": [
              {
                "components": [
                  {
                    "internalType": "address",
                    "name": "to",
                    "type": "address"
                  },
                  {
                    "internalType": "uint256",
                    "name": "gasLimit",
                    "type": "uint256"
                  },
                  {
                    "internalType": "bytes",
                    "name": "data",
                    "type": "bytes"
                  }
                ],
                "internalType": "struct Transaction",
                "name": "transaction",
                "type": "tuple"
              },
              {
                "components": [
                  {
                    "components": [
                      {
                        "internalType": "address",
                        "name": "delegate",
                        "type": "address"
                      },
                      {
                        "internalType": "bytes32",
                        "name": "authority",
                        "type": "bytes32"
                      },
                      {
                        "components": [
                          {
                            "internalType": "address",
                            "name": "enforcer",
                            "type": "address"
                          },
                          {
                            "internalType": "bytes",
                            "name": "terms",
                            "type": "bytes"
                          }
                        ],
                        "internalType": "struct Caveat[]",
                        "name": "caveats",
                        "type": "tuple[]"
                      }
                    ],
                    "internalType": "struct Delegation",
                    "name": "delegation",
                    "type": "tuple"
                  },
                  {
                    "internalType": "bytes",
                    "name": "signature",
                    "type": "bytes"
                  }
                ],
                "internalType": "struct SignedDelegation[]",
                "name": "authority",
                "type": "tuple[]"
              }
            ],
            "internalType": "struct Invocation[]",
            "name": "batch",
            "type": "tuple[]"
          },
          {
            "components": [
              {
                "internalType": "uint256",
                "name": "nonce",
                "type": "uint256"
              },
              {
                "internalType": "uint256",
                "name": "queue",
                "type": "uint256"
              }
            ],
            "internalType": "struct ReplayProtection",
            "name": "replayProtection",
            "type": "tuple"
          }
        ],
        "internalType": "struct Invocations",
        "name": "invocations",
        "type": "tuple"
      }
    ],
    "name": "getInvocationsTypedDataHash",
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
        "name": "intendedSender",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "queue",
        "type": "uint256"
      }
    ],
    "name": "getNonce",
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
        "name": "_submissionId",
        "type": "uint256"
      }
    ],
    "name": "getRewards",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "pTokenToClaim",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "rTokenToClaim",
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
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "",
        "type": "bytes32"
      }
    ],
    "name": "hasPerformed",
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
            "components": [
              {
                "components": [
                  {
                    "components": [
                      {
                        "internalType": "address",
                        "name": "to",
                        "type": "address"
                      },
                      {
                        "internalType": "uint256",
                        "name": "gasLimit",
                        "type": "uint256"
                      },
                      {
                        "internalType": "bytes",
                        "name": "data",
                        "type": "bytes"
                      }
                    ],
                    "internalType": "struct Transaction",
                    "name": "transaction",
                    "type": "tuple"
                  },
                  {
                    "components": [
                      {
                        "components": [
                          {
                            "internalType": "address",
                            "name": "delegate",
                            "type": "address"
                          },
                          {
                            "internalType": "bytes32",
                            "name": "authority",
                            "type": "bytes32"
                          },
                          {
                            "components": [
                              {
                                "internalType": "address",
                                "name": "enforcer",
                                "type": "address"
                              },
                              {
                                "internalType": "bytes",
                                "name": "terms",
                                "type": "bytes"
                              }
                            ],
                            "internalType": "struct Caveat[]",
                            "name": "caveats",
                            "type": "tuple[]"
                          }
                        ],
                        "internalType": "struct Delegation",
                        "name": "delegation",
                        "type": "tuple"
                      },
                      {
                        "internalType": "bytes",
                        "name": "signature",
                        "type": "bytes"
                      }
                    ],
                    "internalType": "struct SignedDelegation[]",
                    "name": "authority",
                    "type": "tuple[]"
                  }
                ],
                "internalType": "struct Invocation[]",
                "name": "batch",
                "type": "tuple[]"
              },
              {
                "components": [
                  {
                    "internalType": "uint256",
                    "name": "nonce",
                    "type": "uint256"
                  },
                  {
                    "internalType": "uint256",
                    "name": "queue",
                    "type": "uint256"
                  }
                ],
                "internalType": "struct ReplayProtection",
                "name": "replayProtection",
                "type": "tuple"
              }
            ],
            "internalType": "struct Invocations",
            "name": "invocations",
            "type": "tuple"
          },
          {
            "internalType": "bytes",
            "name": "signature",
            "type": "bytes"
          }
        ],
        "internalType": "struct SignedInvocation[]",
        "name": "signedInvocations",
        "type": "tuple[]"
      }
    ],
    "name": "invoke",
    "outputs": [
      {
        "internalType": "bool",
        "name": "success",
        "type": "bool"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_account",
        "type": "address"
      }
    ],
    "name": "isDelegate",
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
        "name": "_account",
        "type": "address"
      }
    ],
    "name": "isMaintainer",
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
        "name": "_account",
        "type": "address"
      }
    ],
    "name": "isPermittedParticipant",
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
        "name": "",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      },
      {
        "internalType": "uint256[]",
        "name": "",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "",
        "type": "uint256[]"
      },
      {
        "internalType": "bytes",
        "name": "",
        "type": "bytes"
      }
    ],
    "name": "onERC1155BatchReceived",
    "outputs": [
      {
        "internalType": "bytes4",
        "name": "",
        "type": "bytes4"
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
      },
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
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      },
      {
        "internalType": "bytes",
        "name": "",
        "type": "bytes"
      }
    ],
    "name": "onERC1155Received",
    "outputs": [
      {
        "internalType": "bytes4",
        "name": "",
        "type": "bytes4"
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
        "internalType": "string",
        "name": "_uri",
        "type": "string"
      }
    ],
    "name": "provide",
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
        "internalType": "uint256",
        "name": "_requestId",
        "type": "uint256"
      }
    ],
    "name": "retrieveReputation",
    "outputs": [],
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
    "name": "reviewSignals",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "total",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "remainder",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "serviceId",
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
        "name": "",
        "type": "uint256"
      }
    ],
    "name": "serviceRequests",
    "outputs": [
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
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "name": "serviceSubmissions",
    "outputs": [
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
    "name": "setConfiguration",
    "outputs": [],
    "stateMutability": "nonpayable",
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
    "name": "signal",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "name": "signalCount",
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
      },
      {
        "internalType": "uint256",
        "name": "_quantity",
        "type": "uint256"
      }
    ],
    "name": "signalReview",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_pToken",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_pTokenQ",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_signalExp",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_submissionExp",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_enforcementExp",
        "type": "uint256"
      },
      {
        "internalType": "string",
        "name": "_requestUri",
        "type": "string"
      }
    ],
    "name": "submitRequest",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "requestId",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes4",
        "name": "interfaceId",
        "type": "bytes4"
      }
    ],
    "name": "supportsInterface",
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
        "components": [
          {
            "components": [
              {
                "internalType": "address",
                "name": "delegate",
                "type": "address"
              },
              {
                "internalType": "bytes32",
                "name": "authority",
                "type": "bytes32"
              },
              {
                "components": [
                  {
                    "internalType": "address",
                    "name": "enforcer",
                    "type": "address"
                  },
                  {
                    "internalType": "bytes",
                    "name": "terms",
                    "type": "bytes"
                  }
                ],
                "internalType": "struct Caveat[]",
                "name": "caveats",
                "type": "tuple[]"
              }
            ],
            "internalType": "struct Delegation",
            "name": "delegation",
            "type": "tuple"
          },
          {
            "internalType": "bytes",
            "name": "signature",
            "type": "bytes"
          }
        ],
        "internalType": "struct SignedDelegation",
        "name": "signedDelegation",
        "type": "tuple"
      }
    ],
    "name": "verifyDelegationSignature",
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
        "components": [
          {
            "components": [
              {
                "components": [
                  {
                    "components": [
                      {
                        "internalType": "address",
                        "name": "to",
                        "type": "address"
                      },
                      {
                        "internalType": "uint256",
                        "name": "gasLimit",
                        "type": "uint256"
                      },
                      {
                        "internalType": "bytes",
                        "name": "data",
                        "type": "bytes"
                      }
                    ],
                    "internalType": "struct Transaction",
                    "name": "transaction",
                    "type": "tuple"
                  },
                  {
                    "components": [
                      {
                        "components": [
                          {
                            "internalType": "address",
                            "name": "delegate",
                            "type": "address"
                          },
                          {
                            "internalType": "bytes32",
                            "name": "authority",
                            "type": "bytes32"
                          },
                          {
                            "components": [
                              {
                                "internalType": "address",
                                "name": "enforcer",
                                "type": "address"
                              },
                              {
                                "internalType": "bytes",
                                "name": "terms",
                                "type": "bytes"
                              }
                            ],
                            "internalType": "struct Caveat[]",
                            "name": "caveats",
                            "type": "tuple[]"
                          }
                        ],
                        "internalType": "struct Delegation",
                        "name": "delegation",
                        "type": "tuple"
                      },
                      {
                        "internalType": "bytes",
                        "name": "signature",
                        "type": "bytes"
                      }
                    ],
                    "internalType": "struct SignedDelegation[]",
                    "name": "authority",
                    "type": "tuple[]"
                  }
                ],
                "internalType": "struct Invocation[]",
                "name": "batch",
                "type": "tuple[]"
              },
              {
                "components": [
                  {
                    "internalType": "uint256",
                    "name": "nonce",
                    "type": "uint256"
                  },
                  {
                    "internalType": "uint256",
                    "name": "queue",
                    "type": "uint256"
                  }
                ],
                "internalType": "struct ReplayProtection",
                "name": "replayProtection",
                "type": "tuple"
              }
            ],
            "internalType": "struct Invocations",
            "name": "invocations",
            "type": "tuple"
          },
          {
            "internalType": "bytes",
            "name": "signature",
            "type": "bytes"
          }
        ],
        "internalType": "struct SignedInvocation",
        "name": "signedInvocation",
        "type": "tuple"
      }
    ],
    "name": "verifyInvocationSignature",
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
        "internalType": "uint256",
        "name": "_requestId",
        "type": "uint256"
      }
    ],
    "name": "withdrawRequest",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
] as const
