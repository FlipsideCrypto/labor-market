/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type {
  BucketEnforcement,
  BucketEnforcementInterface,
} from "../../../src/enforcement/BucketEnforcement";

const _abi = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "_market",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256[]",
        name: "_auxiliaries",
        type: "uint256[]",
      },
      {
        indexed: false,
        internalType: "uint256[]",
        name: "_alphas",
        type: "uint256[]",
      },
      {
        indexed: false,
        internalType: "uint256[]",
        name: "_betas",
        type: "uint256[]",
      },
    ],
    name: "EnforcementConfigured",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "_market",
        type: "address",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "_requestId",
        type: "uint256",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "_submissionId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "intentChange",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "earnings",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "remainder",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "bool",
        name: "newSubmission",
        type: "bool",
      },
    ],
    name: "SubmissionReviewed",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_requestId",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_submissionId",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_score",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_availableShare",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "_enforcer",
        type: "address",
      },
    ],
    name: "enforce",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
      {
        internalType: "uint24",
        name: "",
        type: "uint24",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_market",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_requestId",
        type: "uint256",
      },
    ],
    name: "getRemainder",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_market",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_requestId",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_submissionId",
        type: "uint256",
      },
    ],
    name: "getRewards",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "marketToMaxScore",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_requestId",
        type: "uint256",
      },
    ],
    name: "remainder",
    outputs: [
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_requestId",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_submissionId",
        type: "uint256",
      },
    ],
    name: "rewards",
    outputs: [
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
      {
        internalType: "bool",
        name: "requiresSubmission",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256[]",
        name: "_auxilaries",
        type: "uint256[]",
      },
      {
        internalType: "uint256[]",
        name: "_ranges",
        type: "uint256[]",
      },
      {
        internalType: "uint256[]",
        name: "_weights",
        type: "uint256[]",
      },
    ],
    name: "setConfiguration",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x6080806040523461001657611078908161001c8239f35b600080fdfe6040610120815260048036101561001557600080fd5b60009060a060e0528160e05152813560e01c9182630109ab541461097d575081633e7e366e146108dd57816364bf71ff146102685781639d10fe35146101ed57508063de8db53f14610174578063e2bd00fb1461010d5763fcc366441461007b57600080fd5b346101065760607ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc3601126101065760209073ffffffffffffffffffffffffffffffffffffffff6100ca610cd7565b1660e05151526002825260e05151818120906024359052825260e05151600282822001906044359052825260018160e051512001549051908152f35b60e0515180fd5b50346101065760207ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc3601126101065760209073ffffffffffffffffffffffffffffffffffffffff61015d610cd7565b1660e05151528060e0515180845220549051908152f35b503461010657807ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc3601126101065760209073ffffffffffffffffffffffffffffffffffffffff6101c3610cd7565b1660e05151526002825260e05151818120906024359052825260018160e051512001549051908152f35b823461010657602091827ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc3601126101065735903360e05151526002835260e05151828282209152835260e051519160018284200154923390526002845260e05151908282209152835260e051516001828220015551908152f35b9050346101065760607ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc3601126101065767ffffffffffffffff908035828111610106576102b99036908301610cff565b6024948535858111610106576102d29036908601610cff565b906044938435888111610106576102ec9036908901610cff565b610100526080523360e051515260c0956020875260016020528460e051512098895461085c57821561082b578135998a156107a9576101005186036107275760e051515b7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff87018781116106f65781101561049e5761036c818888610d30565b356001820180831161046d57610383908989610d30565b3511156103ea577fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff81146103b957600101610330565b8c60118c7f4e487b710000000000000000000000000000000000000000000000000000000060e05151525260e05151fd5b505085517f08c379a00000000000000000000000000000000000000000000000000000000081528851818b01526035818d01527f4275636b6574456e666f7263656d656e743a3a7365744275636b6574733a2042818901527f75636b657473206e6f742073657175656e7469616c00000000000000000000006064820152608490fd5b8e60118e7f4e487b710000000000000000000000000000000000000000000000000000000060e05151525260e05151fd5b5093889286928d8c8a988f8155600181018488116106c5576801000000000000000091828911610694578154898355808a10610664575b50879160e0515152895160e0515192818420845b8c81106106525750505050600201946101005111610624575061010051116105f457505080546101005182558061010051106105c2575b506080519060e051515284519060e05151828120905b6101005181106105b057897f644aa63559522f8f6f8b506611f6d55d82a2ab57ed2d621aa3a46f4b41de5d7e8a61058c8b8b8b61057e8c885196606088526060880191610db8565b928584039051860152610db8565b9281840390820152806105a6339461010051608051610db8565b0390a260e0515180f35b82358282015591830191600101610536565b8160e0515152855160e051519081209182019161010051015b8281106105e9575050610520565b8181556001016105db565b6041907f4e487b710000000000000000000000000000000000000000000000000000000060e05151525260e05151fd5b6041837f4e487b71000000000000000000000000000000000000000000000000000000008693525260e05151fd5b823582820155918301916001016104e9565b8260e05151528a5160e05151908120918b83015b8184018110610689575050506104d5565b828155600101610678565b846041857f4e487b710000000000000000000000000000000000000000000000000000000060e05151525260e05151fd5b836041847f4e487b710000000000000000000000000000000000000000000000000000000060e05151525260e05151fd5b8d60118d7f4e487b710000000000000000000000000000000000000000000000000000000060e05151525260e05151fd5b5085517f08c379a00000000000000000000000000000000000000000000000000000000081528851818b0152602c818d01527f4275636b6574456e666f7263656d656e743a3a7365744275636b6574733a2049818901527f6e76616c696420696e70757400000000000000000000000000000000000000006064820152608490fd5b5085517f08c379a00000000000000000000000000000000000000000000000000000000081528851818b01526030818d01527f4275636b6574456e666f7263656d656e743a3a7365744275636b6574733a204d818901527f61782073636f7265206e6f7420736574000000000000000000000000000000006064820152608490fd5b8a60328a7f4e487b710000000000000000000000000000000000000000000000000000000060e05151525260e05151fd5b85517f08c379a00000000000000000000000000000000000000000000000000000000081528851818b01526036818d01527f4275636b6574456e666f7263656d656e743a3a7365744275636b6574733a2043818901527f7269746572696120616c726561647920696e20757365000000000000000000006064820152608490fd5b90503461010657817ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc360112610106573560016024353360e05151526020906002825260e05151848682209152825260e05151816002878320019152825260e0515193838686200154943390526002835260e05151908682209152825260e05151906002868320019152815260e051518285822001558351928352820152f35b915034610cd35760e0517ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc360112610cd357803560243590604435926064356084359473ffffffffffffffffffffffffffffffffffffffff8616809603610ccf57338752876020976002895281812086825289526002828220018782528952206003810193610a1c888660019160005201602052604060002054151590565b610c4d573360e0515152600197888a528a60e05151209081548511610bcb57610a459087610ee1565b503360e051515260028a5260e05151878c822091528a52610a6d8b60e0515120948454610dab565b8355610a936002840196610a878b89549701968754610d6f565b86558454905490610df5565b908b51906060820182811067ffffffffffffffff821117610b9957918d610adb60028f948f989795610ae4978552610ad182549a8b88528301610e2e565b9086015201610e2e565b90820152610f57565b90818602918683041486151715610b6757509188610b08610b1393610b1d95610df5565b910194818655610d6f565b8085558254610dab565b905554905486519185835286830152868201528360608201527fadd6277f5dd5b08da7ebd7ded4c856390a25d7794f33307731ed6ad3a927640460803392a4825191818352820152f35b6011907f4e487b710000000000000000000000000000000000000000000000000000000060e051515252602460e05151fd5b6041857f4e487b710000000000000000000000000000000000000000000000000000000060e051515252602460e05151fd5b6084838c8e51917f08c379a0000000000000000000000000000000000000000000000000000000008352820152602860248201527f4275636b6574456e666f7263656d656e743a3a7265766965773a20496e76616c60448201527f69642073636f72650000000000000000000000000000000000000000000000006064820152fd5b608490898b51917f08c379a0000000000000000000000000000000000000000000000000000000008352820152603b60248201527f4275636b6574456e666f7263656d656e743a3a7265766965773a20456e666f7260448201527f63657220616c7265616479207375626d697420612072657669657700000000006064820152fd5b8680fd5b5080fd5b6004359073ffffffffffffffffffffffffffffffffffffffff82168203610cfa57565b600080fd5b9181601f84011215610cfa5782359167ffffffffffffffff8311610cfa576020808501948460051b010111610cfa57565b9190811015610d405760051b0190565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b91908203918211610d7c57565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b91908201809211610d7c57565b90918281527f07ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8311610cfa5760209260051b809284830137010190565b8115610dff570490565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601260045260246000fd5b90604051918281548082526020908183019360005281600020916000905b828210610ec757505050509003601f017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe016820167ffffffffffffffff811183821017610e9857604052565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b835486529485019487945060019384019390910190610e4c565b6000828152600182016020526040902054610f3c5780549068010000000000000000821015610e985760018201808255821015610d405782600192826000526020600020015580549260005201602052604060002055600190565b5050600090565b8051821015610d405760209160051b010190565b6020810180515193929084156110395793805b610f8557505060409192500151805115610d40576020015190565b84517fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff820190828211610ff35781610fbc91610f43565b5183101561102157508015610ff3577fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0180610f6a565b602460007f4e487b710000000000000000000000000000000000000000000000000000000081526011600452fd5b929050611035939450604091500151610f43565b5190565b5060019350505056fea2646970667358221220cea580228c24622035f0a664c18e10f25f2353b9bd26c03845b2ed687cdee96a64736f6c63430008110033";

type BucketEnforcementConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: BucketEnforcementConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class BucketEnforcement__factory extends ContractFactory {
  constructor(...args: BucketEnforcementConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<BucketEnforcement> {
    return super.deploy(overrides || {}) as Promise<BucketEnforcement>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): BucketEnforcement {
    return super.attach(address) as BucketEnforcement;
  }
  override connect(signer: Signer): BucketEnforcement__factory {
    return super.connect(signer) as BucketEnforcement__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): BucketEnforcementInterface {
    return new utils.Interface(_abi) as BucketEnforcementInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): BucketEnforcement {
    return new Contract(address, _abi, signerOrProvider) as BucketEnforcement;
  }
}
