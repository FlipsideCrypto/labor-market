/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../common";
import type {
  LaborMarketFactory,
  LaborMarketFactoryInterface,
} from "../../src/LaborMarketFactory";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_implementation",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "marketAddress",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "deployer",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "implementation",
        type: "address",
      },
    ],
    name: "LaborMarketCreated",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_deployer",
        type: "address",
      },
      {
        internalType: "contract EnforcementCriteriaInterface",
        name: "_criteria",
        type: "address",
      },
      {
        internalType: "uint256[]",
        name: "_auxilaries",
        type: "uint256[]",
      },
      {
        internalType: "uint256[]",
        name: "_alphas",
        type: "uint256[]",
      },
      {
        internalType: "uint256[]",
        name: "_betas",
        type: "uint256[]",
      },
      {
        internalType: "bytes4[]",
        name: "_sigs",
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
        internalType: "struct NBadgeAuthInterface.Node[]",
        name: "_nodes",
        type: "tuple[]",
      },
    ],
    name: "createLaborMarket",
    outputs: [
      {
        internalType: "address",
        name: "laborMarketAddress",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "implementation",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

const _bytecode =
  "0x60a03461007757601f61087d38819003918201601f19168301916001600160401b0383118484101761007c5780849260209460405283398101031261007757516001600160a01b0381168103610077576080526040516107ea90816100938239608051818181608101528181610208015261042f0152f35b600080fd5b634e487b7160e01b600052604160045260246000fdfe608080604052600436101561001357600080fd5b600090813560e01c9081634d38033d146100a85750635c60da1b1461003757600080fd5b346100a557807ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc3601126100a557602060405173ffffffffffffffffffffffffffffffffffffffff7f0000000000000000000000000000000000000000000000000000000000000000168152f35b80fd5b82346100a55760e07ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc3601126100a5576004359073ffffffffffffffffffffffffffffffffffffffff821682036100a5576024359173ffffffffffffffffffffffffffffffffffffffff8316830361073d5760443567ffffffffffffffff81116107395761013a903690600401610741565b91909460643567ffffffffffffffff81116107355761015d903690600401610741565b919060843567ffffffffffffffff81116107315761017f903690600401610741565b60a43567ffffffffffffffff811161072d5761019f903690600401610741565b93909567ffffffffffffffff60c435116106c757899a9b73ffffffffffffffffffffffffffffffffffffffff60376101e09c9a9b9c3660c435600401610741565b99909b7f3d602d80600a3d3981f3363d3d373d3d3d363d7300000000000000000000000082527f000000000000000000000000000000000000000000000000000000000000000060601b60148301527f5af43d82803e903d91602b57fd5bf300000000000000000000000000000000006028830152f0169a8b156106cf578b3b156106cb579c969593918c989593916040519e8f998d7f21734c15000000000000000000000000000000000000000000000000000000008c5273ffffffffffffffffffffffffffffffffffffffff1660048c015273ffffffffffffffffffffffffffffffffffffffff1660248b015260448a0160e0905260e48a01906102e592610777565b908882037ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc0160648a015261031992610777565b908682037ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc01608488015261034d92610777565b8481037ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc0160a4860152818152602001919085905b808210610659575050507ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc8382030160c4840152818152602081019160208160051b830101928686935b8385106104ad57505050505081929350038183865af180156104a257610458575b6020935060405192827f3c036db17d0d0b5dd4eb57da1cc3bb081ed8e75504d2b5250d42b318071c26c773ffffffffffffffffffffffffffffffffffffffff807f00000000000000000000000000000000000000000000000000000000000000001694169280a48152f35b919267ffffffffffffffff811161047557604052602092916103ed565b6024847f4e487b710000000000000000000000000000000000000000000000000000000081526041600452fd5b6040513d85823e3d90fd5b7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe091949750809396508592950301845286357fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa184360301811215610655578381013580151581036106515715158252808401602081810135908401526040810135929036037fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe1018312156106515767ffffffffffffffff85830184013511610651578185018301803560a0023603602090910113610651578060606040608093959495015260608101868501840135905201916020858201830101918c915b86810182013583106105d75750505050602080600192980194019501919489958b95929794976103cc565b90919293843573ffffffffffffffffffffffffffffffffffffffff8116810361064d5760a060019273ffffffffffffffffffffffffffffffffffffffff829316815260208801356020820152604088013560408201526060880135606082015260808801356080820152019501930191906105ac565b8e80fd5b8b80fd5b8a80fd5b9291955092935084357fffffffff00000000000000000000000000000000000000000000000000000000811681036106c75760206001927fffffffff000000000000000000000000000000000000000000000000000000008293168152019501920191899392899592610382565b8980fd5b8c80fd5b60646040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601660248201527f455243313136373a20637265617465206661696c6564000000000000000000006044820152fd5b8880fd5b8680fd5b8480fd5b8280fd5b5080fd5b9181601f840112156107725782359167ffffffffffffffff8311610772576020808501948460051b01011161077257565b600080fd5b90918281527f07ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff83116107725760209260051b80928483013701019056fea2646970667358221220a3916093da7dbfa26c1fbea3f1f4a8dbaeffe2d9231e2d0847e599d4f8be617064736f6c63430008110033";

type LaborMarketFactoryConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: LaborMarketFactoryConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class LaborMarketFactory__factory extends ContractFactory {
  constructor(...args: LaborMarketFactoryConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    _implementation: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<LaborMarketFactory> {
    return super.deploy(
      _implementation,
      overrides || {}
    ) as Promise<LaborMarketFactory>;
  }
  override getDeployTransaction(
    _implementation: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(_implementation, overrides || {});
  }
  override attach(address: string): LaborMarketFactory {
    return super.attach(address) as LaborMarketFactory;
  }
  override connect(signer: Signer): LaborMarketFactory__factory {
    return super.connect(signer) as LaborMarketFactory__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): LaborMarketFactoryInterface {
    return new utils.Interface(_abi) as LaborMarketFactoryInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): LaborMarketFactory {
    return new Contract(address, _abi, signerOrProvider) as LaborMarketFactory;
  }
}
