export const abi = [
  {
    "inputs": [],
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
        "indexed": false,
        "internalType": "address",
        "name": "deployer",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "criteria",
        "type": "address"
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
        "name": "user",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "newOwner",
        "type": "address"
      }
    ],
    "name": "OwnershipTransferred",
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
        "internalType": "address",
        "name": "to",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "bool",
        "name": "settled",
        "type": "bool"
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
        "indexed": false,
        "internalType": "uint256",
        "name": "requestId",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint48",
        "name": "signalExp",
        "type": "uint48"
      },
      {
        "indexed": false,
        "internalType": "uint48",
        "name": "submissionExp",
        "type": "uint48"
      },
      {
        "indexed": false,
        "internalType": "uint48",
        "name": "enforcementExp",
        "type": "uint48"
      },
      {
        "indexed": false,
        "internalType": "uint64",
        "name": "providerLimit",
        "type": "uint64"
      },
      {
        "indexed": false,
        "internalType": "uint64",
        "name": "reviewerLimit",
        "type": "uint64"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "pTokenProviderTotal",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "pTokenReviewerTotal",
        "type": "uint256"
      },
      {
        "indexed": true,
        "internalType": "contract IERC20",
        "name": "pTokenProvider",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "contract IERC20",
        "name": "pTokenReviewer",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "string",
        "name": "uri",
        "type": "string"
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
      },
      {
        "indexed": false,
        "internalType": "string",
        "name": "uri",
        "type": "string"
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
      }
    ],
    "name": "ReviewSignal",
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
      }
    ],
    "name": "claim",
    "outputs": [
      {
        "internalType": "bool",
        "name": "success",
        "type": "bool"
      },
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
    "name": "claimRemainder",
    "outputs": [
      {
        "internalType": "bool",
        "name": "pTokenProviderSuccess",
        "type": "bool"
      },
      {
        "internalType": "bool",
        "name": "pTokenReviewerSuccess",
        "type": "bool"
      },
      {
        "internalType": "uint256",
        "name": "pTokenProviderSurplus",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "pTokenReviewerSurplus",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "deployer",
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
        "name": "_deployer",
        "type": "address"
      },
      {
        "internalType": "contract EnforcementCriteriaInterface",
        "name": "_criteria",
        "type": "address"
      },
      {
        "internalType": "uint256[]",
        "name": "_auxilaries",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "_alphas",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "_betas",
        "type": "uint256[]"
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
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "internalType": "bytes4",
        "name": "_sig",
        "type": "bytes4"
      }
    ],
    "name": "isAuthorized",
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
        "name": "submissionId",
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
        "name": "",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "name": "requestIdToAddressToPerformance",
    "outputs": [
      {
        "internalType": "uint24",
        "name": "",
        "type": "uint24"
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
    "name": "requestIdToRequest",
    "outputs": [
      {
        "internalType": "uint48",
        "name": "signalExp",
        "type": "uint48"
      },
      {
        "internalType": "uint48",
        "name": "submissionExp",
        "type": "uint48"
      },
      {
        "internalType": "uint48",
        "name": "enforcementExp",
        "type": "uint48"
      },
      {
        "internalType": "uint64",
        "name": "providerLimit",
        "type": "uint64"
      },
      {
        "internalType": "uint64",
        "name": "reviewerLimit",
        "type": "uint64"
      },
      {
        "internalType": "uint256",
        "name": "pTokenProviderTotal",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "pTokenReviewerTotal",
        "type": "uint256"
      },
      {
        "internalType": "contract IERC20",
        "name": "pTokenProvider",
        "type": "address"
      },
      {
        "internalType": "contract IERC20",
        "name": "pTokenReviewer",
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
        "name": "",
        "type": "uint256"
      }
    ],
    "name": "requestIdToSignalState",
    "outputs": [
      {
        "internalType": "uint64",
        "name": "providers",
        "type": "uint64"
      },
      {
        "internalType": "uint64",
        "name": "reviewers",
        "type": "uint64"
      },
      {
        "internalType": "uint64",
        "name": "providersArrived",
        "type": "uint64"
      },
      {
        "internalType": "uint64",
        "name": "reviewersArrived",
        "type": "uint64"
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
        "name": "_submissionId",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_score",
        "type": "uint256"
      },
      {
        "internalType": "string",
        "name": "_uri",
        "type": "string"
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
        "name": "_requestId",
        "type": "uint256"
      },
      {
        "internalType": "uint24",
        "name": "_quantity",
        "type": "uint24"
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
        "internalType": "uint8",
        "name": "_blockNonce",
        "type": "uint8"
      },
      {
        "components": [
          {
            "internalType": "uint48",
            "name": "signalExp",
            "type": "uint48"
          },
          {
            "internalType": "uint48",
            "name": "submissionExp",
            "type": "uint48"
          },
          {
            "internalType": "uint48",
            "name": "enforcementExp",
            "type": "uint48"
          },
          {
            "internalType": "uint64",
            "name": "providerLimit",
            "type": "uint64"
          },
          {
            "internalType": "uint64",
            "name": "reviewerLimit",
            "type": "uint64"
          },
          {
            "internalType": "uint256",
            "name": "pTokenProviderTotal",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "pTokenReviewerTotal",
            "type": "uint256"
          },
          {
            "internalType": "contract IERC20",
            "name": "pTokenProvider",
            "type": "address"
          },
          {
            "internalType": "contract IERC20",
            "name": "pTokenReviewer",
            "type": "address"
          }
        ],
        "internalType": "struct LaborMarketInterface.ServiceRequest",
        "name": "_request",
        "type": "tuple"
      },
      {
        "internalType": "string",
        "name": "_uri",
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
