/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  NBadgeAuthInterface,
  NBadgeAuthInterfaceInterface,
} from "../../../../src/interfaces/auth/NBadgeAuthInterface";

const _abi = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "bytes4[]",
        name: "sigs",
        type: "bytes4[]",
      },
      {
        components: [
          {
            internalType: "bool",
            name: "deployerAllowed",
            type: "bool",
          },
          {
            internalType: "uint256",
            name: "required",
            type: "uint256",
          },
          {
            components: [
              {
                internalType: "contract IERC1155",
                name: "badge",
                type: "address",
              },
              {
                internalType: "uint256",
                name: "id",
                type: "uint256",
              },
              {
                internalType: "uint256",
                name: "min",
                type: "uint256",
              },
              {
                internalType: "uint256",
                name: "max",
                type: "uint256",
              },
              {
                internalType: "uint256",
                name: "points",
                type: "uint256",
              },
            ],
            internalType: "struct NBadgeAuthInterface.Badge[]",
            name: "badges",
            type: "tuple[]",
          },
        ],
        indexed: false,
        internalType: "struct NBadgeAuthInterface.Node[]",
        name: "nodes",
        type: "tuple[]",
      },
    ],
    name: "NodesUpdated",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "user",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "OwnershipTransferred",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "user",
        type: "address",
      },
      {
        internalType: "bytes4",
        name: "sig",
        type: "bytes4",
      },
    ],
    name: "isAuthorized",
    outputs: [
      {
        internalType: "bool",
        name: "authorized",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

export class NBadgeAuthInterface__factory {
  static readonly abi = _abi;
  static createInterface(): NBadgeAuthInterfaceInterface {
    return new utils.Interface(_abi) as NBadgeAuthInterfaceInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): NBadgeAuthInterface {
    return new Contract(address, _abi, signerOrProvider) as NBadgeAuthInterface;
  }
}
