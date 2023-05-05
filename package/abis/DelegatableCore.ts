export const abi = [
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
  }
] as const
