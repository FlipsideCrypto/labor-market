/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type {
  FunctionFragment,
  Result,
  EventFragment,
} from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "../common";

export declare namespace NBadgeAuthInterface {
  export type BadgeStruct = {
    badge: PromiseOrValue<string>;
    id: PromiseOrValue<BigNumberish>;
    min: PromiseOrValue<BigNumberish>;
    max: PromiseOrValue<BigNumberish>;
    points: PromiseOrValue<BigNumberish>;
  };

  export type BadgeStructOutput = [
    string,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber
  ] & {
    badge: string;
    id: BigNumber;
    min: BigNumber;
    max: BigNumber;
    points: BigNumber;
  };

  export type NodeStruct = {
    deployerAllowed: PromiseOrValue<boolean>;
    required: PromiseOrValue<BigNumberish>;
    badges: NBadgeAuthInterface.BadgeStruct[];
  };

  export type NodeStructOutput = [
    boolean,
    BigNumber,
    NBadgeAuthInterface.BadgeStructOutput[]
  ] & {
    deployerAllowed: boolean;
    required: BigNumber;
    badges: NBadgeAuthInterface.BadgeStructOutput[];
  };
}

export declare namespace LaborMarketInterface {
  export type ServiceRequestStruct = {
    signalExp: PromiseOrValue<BigNumberish>;
    submissionExp: PromiseOrValue<BigNumberish>;
    enforcementExp: PromiseOrValue<BigNumberish>;
    providerLimit: PromiseOrValue<BigNumberish>;
    reviewerLimit: PromiseOrValue<BigNumberish>;
    pTokenProviderTotal: PromiseOrValue<BigNumberish>;
    pTokenReviewerTotal: PromiseOrValue<BigNumberish>;
    pTokenProvider: PromiseOrValue<string>;
    pTokenReviewer: PromiseOrValue<string>;
  };

  export type ServiceRequestStructOutput = [
    number,
    number,
    number,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    string,
    string
  ] & {
    signalExp: number;
    submissionExp: number;
    enforcementExp: number;
    providerLimit: BigNumber;
    reviewerLimit: BigNumber;
    pTokenProviderTotal: BigNumber;
    pTokenReviewerTotal: BigNumber;
    pTokenProvider: string;
    pTokenReviewer: string;
  };
}

export interface LaborMarketInterface extends utils.Interface {
  functions: {
    "claim(uint256,uint256)": FunctionFragment;
    "claimRemainder(uint256)": FunctionFragment;
    "deployer()": FunctionFragment;
    "initialize(address,address,uint256[],uint256[],uint256[],bytes4[],(bool,uint256,(address,uint256,uint256,uint256,uint256)[])[])": FunctionFragment;
    "isAuthorized(address,bytes4)": FunctionFragment;
    "provide(uint256,string)": FunctionFragment;
    "requestIdToAddressToPerformance(uint256,address)": FunctionFragment;
    "requestIdToRequest(uint256)": FunctionFragment;
    "requestIdToSignalState(uint256)": FunctionFragment;
    "review(uint256,uint256,uint256,string)": FunctionFragment;
    "signal(uint256)": FunctionFragment;
    "signalReview(uint256,uint24)": FunctionFragment;
    "submitRequest(uint8,(uint48,uint48,uint48,uint64,uint64,uint256,uint256,address,address),string)": FunctionFragment;
    "withdrawRequest(uint256)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "claim"
      | "claimRemainder"
      | "deployer"
      | "initialize"
      | "isAuthorized"
      | "provide"
      | "requestIdToAddressToPerformance"
      | "requestIdToRequest"
      | "requestIdToSignalState"
      | "review"
      | "signal"
      | "signalReview"
      | "submitRequest"
      | "withdrawRequest"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "claim",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "claimRemainder",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(functionFragment: "deployer", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "initialize",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>[],
      PromiseOrValue<BigNumberish>[],
      PromiseOrValue<BigNumberish>[],
      PromiseOrValue<BytesLike>[],
      NBadgeAuthInterface.NodeStruct[]
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "isAuthorized",
    values: [PromiseOrValue<string>, PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "provide",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "requestIdToAddressToPerformance",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "requestIdToRequest",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "requestIdToSignalState",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "review",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<string>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "signal",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "signalReview",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "submitRequest",
    values: [
      PromiseOrValue<BigNumberish>,
      LaborMarketInterface.ServiceRequestStruct,
      PromiseOrValue<string>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "withdrawRequest",
    values: [PromiseOrValue<BigNumberish>]
  ): string;

  decodeFunctionResult(functionFragment: "claim", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "claimRemainder",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "deployer", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "initialize", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "isAuthorized",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "provide", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "requestIdToAddressToPerformance",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "requestIdToRequest",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "requestIdToSignalState",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "review", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "signal", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "signalReview",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "submitRequest",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "withdrawRequest",
    data: BytesLike
  ): Result;

  events: {
    "Initialized(uint8)": EventFragment;
    "LaborMarketConfigured(address,address)": EventFragment;
    "OwnershipTransferred(address,address)": EventFragment;
    "RemainderClaimed(address,uint256,address,bool)": EventFragment;
    "RequestConfigured(address,uint256,uint48,uint48,uint48,uint64,uint64,uint256,uint256,address,address,string)": EventFragment;
    "RequestFulfilled(address,uint256,uint256,string)": EventFragment;
    "RequestPayClaimed(address,uint256,uint256,uint256,address)": EventFragment;
    "RequestReviewed(address,uint256,uint256,uint256,string)": EventFragment;
    "RequestSignal(address,uint256)": EventFragment;
    "RequestWithdrawn(uint256)": EventFragment;
    "ReviewSignal(address,uint256,uint256)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "Initialized"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "LaborMarketConfigured"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "OwnershipTransferred"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "RemainderClaimed"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "RequestConfigured"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "RequestFulfilled"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "RequestPayClaimed"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "RequestReviewed"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "RequestSignal"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "RequestWithdrawn"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "ReviewSignal"): EventFragment;
}

export interface InitializedEventObject {
  version: number;
}
export type InitializedEvent = TypedEvent<[number], InitializedEventObject>;

export type InitializedEventFilter = TypedEventFilter<InitializedEvent>;

export interface LaborMarketConfiguredEventObject {
  deployer: string;
  criteria: string;
}
export type LaborMarketConfiguredEvent = TypedEvent<
  [string, string],
  LaborMarketConfiguredEventObject
>;

export type LaborMarketConfiguredEventFilter =
  TypedEventFilter<LaborMarketConfiguredEvent>;

export interface OwnershipTransferredEventObject {
  user: string;
  newOwner: string;
}
export type OwnershipTransferredEvent = TypedEvent<
  [string, string],
  OwnershipTransferredEventObject
>;

export type OwnershipTransferredEventFilter =
  TypedEventFilter<OwnershipTransferredEvent>;

export interface RemainderClaimedEventObject {
  claimer: string;
  requestId: BigNumber;
  to: string;
  settled: boolean;
}
export type RemainderClaimedEvent = TypedEvent<
  [string, BigNumber, string, boolean],
  RemainderClaimedEventObject
>;

export type RemainderClaimedEventFilter =
  TypedEventFilter<RemainderClaimedEvent>;

export interface RequestConfiguredEventObject {
  requester: string;
  requestId: BigNumber;
  signalExp: number;
  submissionExp: number;
  enforcementExp: number;
  providerLimit: BigNumber;
  reviewerLimit: BigNumber;
  pTokenProviderTotal: BigNumber;
  pTokenReviewerTotal: BigNumber;
  pTokenProvider: string;
  pTokenReviewer: string;
  uri: string;
}
export type RequestConfiguredEvent = TypedEvent<
  [
    string,
    BigNumber,
    number,
    number,
    number,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    string,
    string,
    string
  ],
  RequestConfiguredEventObject
>;

export type RequestConfiguredEventFilter =
  TypedEventFilter<RequestConfiguredEvent>;

export interface RequestFulfilledEventObject {
  fulfiller: string;
  requestId: BigNumber;
  submissionId: BigNumber;
  uri: string;
}
export type RequestFulfilledEvent = TypedEvent<
  [string, BigNumber, BigNumber, string],
  RequestFulfilledEventObject
>;

export type RequestFulfilledEventFilter =
  TypedEventFilter<RequestFulfilledEvent>;

export interface RequestPayClaimedEventObject {
  claimer: string;
  requestId: BigNumber;
  submissionId: BigNumber;
  payAmount: BigNumber;
  to: string;
}
export type RequestPayClaimedEvent = TypedEvent<
  [string, BigNumber, BigNumber, BigNumber, string],
  RequestPayClaimedEventObject
>;

export type RequestPayClaimedEventFilter =
  TypedEventFilter<RequestPayClaimedEvent>;

export interface RequestReviewedEventObject {
  reviewer: string;
  requestId: BigNumber;
  submissionId: BigNumber;
  reviewScore: BigNumber;
  uri: string;
}
export type RequestReviewedEvent = TypedEvent<
  [string, BigNumber, BigNumber, BigNumber, string],
  RequestReviewedEventObject
>;

export type RequestReviewedEventFilter = TypedEventFilter<RequestReviewedEvent>;

export interface RequestSignalEventObject {
  signaler: string;
  requestId: BigNumber;
}
export type RequestSignalEvent = TypedEvent<
  [string, BigNumber],
  RequestSignalEventObject
>;

export type RequestSignalEventFilter = TypedEventFilter<RequestSignalEvent>;

export interface RequestWithdrawnEventObject {
  requestId: BigNumber;
}
export type RequestWithdrawnEvent = TypedEvent<
  [BigNumber],
  RequestWithdrawnEventObject
>;

export type RequestWithdrawnEventFilter =
  TypedEventFilter<RequestWithdrawnEvent>;

export interface ReviewSignalEventObject {
  signaler: string;
  requestId: BigNumber;
  quantity: BigNumber;
}
export type ReviewSignalEvent = TypedEvent<
  [string, BigNumber, BigNumber],
  ReviewSignalEventObject
>;

export type ReviewSignalEventFilter = TypedEventFilter<ReviewSignalEvent>;

export interface LaborMarket extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: LaborMarketInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    claim(
      _requestId: PromiseOrValue<BigNumberish>,
      _submissionId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    claimRemainder(
      _requestId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    deployer(overrides?: CallOverrides): Promise<[string]>;

    initialize(
      _deployer: PromiseOrValue<string>,
      _criteria: PromiseOrValue<string>,
      _auxilaries: PromiseOrValue<BigNumberish>[],
      _alphas: PromiseOrValue<BigNumberish>[],
      _betas: PromiseOrValue<BigNumberish>[],
      _sigs: PromiseOrValue<BytesLike>[],
      _nodes: NBadgeAuthInterface.NodeStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    isAuthorized(
      user: PromiseOrValue<string>,
      _sig: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    provide(
      _requestId: PromiseOrValue<BigNumberish>,
      _uri: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    requestIdToAddressToPerformance(
      arg0: PromiseOrValue<BigNumberish>,
      arg1: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[number]>;

    requestIdToRequest(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<
      [
        number,
        number,
        number,
        BigNumber,
        BigNumber,
        BigNumber,
        BigNumber,
        string,
        string
      ] & {
        signalExp: number;
        submissionExp: number;
        enforcementExp: number;
        providerLimit: BigNumber;
        reviewerLimit: BigNumber;
        pTokenProviderTotal: BigNumber;
        pTokenReviewerTotal: BigNumber;
        pTokenProvider: string;
        pTokenReviewer: string;
      }
    >;

    requestIdToSignalState(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<
      [BigNumber, BigNumber, BigNumber, BigNumber] & {
        providers: BigNumber;
        reviewers: BigNumber;
        providersArrived: BigNumber;
        reviewersArrived: BigNumber;
      }
    >;

    review(
      _requestId: PromiseOrValue<BigNumberish>,
      _submissionId: PromiseOrValue<BigNumberish>,
      _score: PromiseOrValue<BigNumberish>,
      _uri: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    signal(
      _requestId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    signalReview(
      _requestId: PromiseOrValue<BigNumberish>,
      _quantity: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    submitRequest(
      _blockNonce: PromiseOrValue<BigNumberish>,
      _request: LaborMarketInterface.ServiceRequestStruct,
      _uri: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    withdrawRequest(
      _requestId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  claim(
    _requestId: PromiseOrValue<BigNumberish>,
    _submissionId: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  claimRemainder(
    _requestId: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  deployer(overrides?: CallOverrides): Promise<string>;

  initialize(
    _deployer: PromiseOrValue<string>,
    _criteria: PromiseOrValue<string>,
    _auxilaries: PromiseOrValue<BigNumberish>[],
    _alphas: PromiseOrValue<BigNumberish>[],
    _betas: PromiseOrValue<BigNumberish>[],
    _sigs: PromiseOrValue<BytesLike>[],
    _nodes: NBadgeAuthInterface.NodeStruct[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  isAuthorized(
    user: PromiseOrValue<string>,
    _sig: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  provide(
    _requestId: PromiseOrValue<BigNumberish>,
    _uri: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  requestIdToAddressToPerformance(
    arg0: PromiseOrValue<BigNumberish>,
    arg1: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<number>;

  requestIdToRequest(
    arg0: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<
    [
      number,
      number,
      number,
      BigNumber,
      BigNumber,
      BigNumber,
      BigNumber,
      string,
      string
    ] & {
      signalExp: number;
      submissionExp: number;
      enforcementExp: number;
      providerLimit: BigNumber;
      reviewerLimit: BigNumber;
      pTokenProviderTotal: BigNumber;
      pTokenReviewerTotal: BigNumber;
      pTokenProvider: string;
      pTokenReviewer: string;
    }
  >;

  requestIdToSignalState(
    arg0: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<
    [BigNumber, BigNumber, BigNumber, BigNumber] & {
      providers: BigNumber;
      reviewers: BigNumber;
      providersArrived: BigNumber;
      reviewersArrived: BigNumber;
    }
  >;

  review(
    _requestId: PromiseOrValue<BigNumberish>,
    _submissionId: PromiseOrValue<BigNumberish>,
    _score: PromiseOrValue<BigNumberish>,
    _uri: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  signal(
    _requestId: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  signalReview(
    _requestId: PromiseOrValue<BigNumberish>,
    _quantity: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  submitRequest(
    _blockNonce: PromiseOrValue<BigNumberish>,
    _request: LaborMarketInterface.ServiceRequestStruct,
    _uri: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  withdrawRequest(
    _requestId: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    claim(
      _requestId: PromiseOrValue<BigNumberish>,
      _submissionId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[boolean, BigNumber] & { success: boolean }>;

    claimRemainder(
      _requestId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<
      [boolean, boolean, BigNumber, BigNumber] & {
        pTokenProviderSuccess: boolean;
        pTokenReviewerSuccess: boolean;
        pTokenProviderSurplus: BigNumber;
        pTokenReviewerSurplus: BigNumber;
      }
    >;

    deployer(overrides?: CallOverrides): Promise<string>;

    initialize(
      _deployer: PromiseOrValue<string>,
      _criteria: PromiseOrValue<string>,
      _auxilaries: PromiseOrValue<BigNumberish>[],
      _alphas: PromiseOrValue<BigNumberish>[],
      _betas: PromiseOrValue<BigNumberish>[],
      _sigs: PromiseOrValue<BytesLike>[],
      _nodes: NBadgeAuthInterface.NodeStruct[],
      overrides?: CallOverrides
    ): Promise<void>;

    isAuthorized(
      user: PromiseOrValue<string>,
      _sig: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    provide(
      _requestId: PromiseOrValue<BigNumberish>,
      _uri: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    requestIdToAddressToPerformance(
      arg0: PromiseOrValue<BigNumberish>,
      arg1: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<number>;

    requestIdToRequest(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<
      [
        number,
        number,
        number,
        BigNumber,
        BigNumber,
        BigNumber,
        BigNumber,
        string,
        string
      ] & {
        signalExp: number;
        submissionExp: number;
        enforcementExp: number;
        providerLimit: BigNumber;
        reviewerLimit: BigNumber;
        pTokenProviderTotal: BigNumber;
        pTokenReviewerTotal: BigNumber;
        pTokenProvider: string;
        pTokenReviewer: string;
      }
    >;

    requestIdToSignalState(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<
      [BigNumber, BigNumber, BigNumber, BigNumber] & {
        providers: BigNumber;
        reviewers: BigNumber;
        providersArrived: BigNumber;
        reviewersArrived: BigNumber;
      }
    >;

    review(
      _requestId: PromiseOrValue<BigNumberish>,
      _submissionId: PromiseOrValue<BigNumberish>,
      _score: PromiseOrValue<BigNumberish>,
      _uri: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    signal(
      _requestId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    signalReview(
      _requestId: PromiseOrValue<BigNumberish>,
      _quantity: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    submitRequest(
      _blockNonce: PromiseOrValue<BigNumberish>,
      _request: LaborMarketInterface.ServiceRequestStruct,
      _uri: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    withdrawRequest(
      _requestId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {
    "Initialized(uint8)"(version?: null): InitializedEventFilter;
    Initialized(version?: null): InitializedEventFilter;

    "LaborMarketConfigured(address,address)"(
      deployer?: null,
      criteria?: null
    ): LaborMarketConfiguredEventFilter;
    LaborMarketConfigured(
      deployer?: null,
      criteria?: null
    ): LaborMarketConfiguredEventFilter;

    "OwnershipTransferred(address,address)"(
      user?: PromiseOrValue<string> | null,
      newOwner?: PromiseOrValue<string> | null
    ): OwnershipTransferredEventFilter;
    OwnershipTransferred(
      user?: PromiseOrValue<string> | null,
      newOwner?: PromiseOrValue<string> | null
    ): OwnershipTransferredEventFilter;

    "RemainderClaimed(address,uint256,address,bool)"(
      claimer?: PromiseOrValue<string> | null,
      requestId?: PromiseOrValue<BigNumberish> | null,
      to?: PromiseOrValue<string> | null,
      settled?: null
    ): RemainderClaimedEventFilter;
    RemainderClaimed(
      claimer?: PromiseOrValue<string> | null,
      requestId?: PromiseOrValue<BigNumberish> | null,
      to?: PromiseOrValue<string> | null,
      settled?: null
    ): RemainderClaimedEventFilter;

    "RequestConfigured(address,uint256,uint48,uint48,uint48,uint64,uint64,uint256,uint256,address,address,string)"(
      requester?: PromiseOrValue<string> | null,
      requestId?: null,
      signalExp?: null,
      submissionExp?: null,
      enforcementExp?: null,
      providerLimit?: null,
      reviewerLimit?: null,
      pTokenProviderTotal?: null,
      pTokenReviewerTotal?: null,
      pTokenProvider?: PromiseOrValue<string> | null,
      pTokenReviewer?: PromiseOrValue<string> | null,
      uri?: null
    ): RequestConfiguredEventFilter;
    RequestConfigured(
      requester?: PromiseOrValue<string> | null,
      requestId?: null,
      signalExp?: null,
      submissionExp?: null,
      enforcementExp?: null,
      providerLimit?: null,
      reviewerLimit?: null,
      pTokenProviderTotal?: null,
      pTokenReviewerTotal?: null,
      pTokenProvider?: PromiseOrValue<string> | null,
      pTokenReviewer?: PromiseOrValue<string> | null,
      uri?: null
    ): RequestConfiguredEventFilter;

    "RequestFulfilled(address,uint256,uint256,string)"(
      fulfiller?: PromiseOrValue<string> | null,
      requestId?: PromiseOrValue<BigNumberish> | null,
      submissionId?: PromiseOrValue<BigNumberish> | null,
      uri?: null
    ): RequestFulfilledEventFilter;
    RequestFulfilled(
      fulfiller?: PromiseOrValue<string> | null,
      requestId?: PromiseOrValue<BigNumberish> | null,
      submissionId?: PromiseOrValue<BigNumberish> | null,
      uri?: null
    ): RequestFulfilledEventFilter;

    "RequestPayClaimed(address,uint256,uint256,uint256,address)"(
      claimer?: PromiseOrValue<string> | null,
      requestId?: PromiseOrValue<BigNumberish> | null,
      submissionId?: PromiseOrValue<BigNumberish> | null,
      payAmount?: null,
      to?: null
    ): RequestPayClaimedEventFilter;
    RequestPayClaimed(
      claimer?: PromiseOrValue<string> | null,
      requestId?: PromiseOrValue<BigNumberish> | null,
      submissionId?: PromiseOrValue<BigNumberish> | null,
      payAmount?: null,
      to?: null
    ): RequestPayClaimedEventFilter;

    "RequestReviewed(address,uint256,uint256,uint256,string)"(
      reviewer?: PromiseOrValue<string> | null,
      requestId?: PromiseOrValue<BigNumberish> | null,
      submissionId?: PromiseOrValue<BigNumberish> | null,
      reviewScore?: null,
      uri?: null
    ): RequestReviewedEventFilter;
    RequestReviewed(
      reviewer?: PromiseOrValue<string> | null,
      requestId?: PromiseOrValue<BigNumberish> | null,
      submissionId?: PromiseOrValue<BigNumberish> | null,
      reviewScore?: null,
      uri?: null
    ): RequestReviewedEventFilter;

    "RequestSignal(address,uint256)"(
      signaler?: PromiseOrValue<string> | null,
      requestId?: PromiseOrValue<BigNumberish> | null
    ): RequestSignalEventFilter;
    RequestSignal(
      signaler?: PromiseOrValue<string> | null,
      requestId?: PromiseOrValue<BigNumberish> | null
    ): RequestSignalEventFilter;

    "RequestWithdrawn(uint256)"(
      requestId?: PromiseOrValue<BigNumberish> | null
    ): RequestWithdrawnEventFilter;
    RequestWithdrawn(
      requestId?: PromiseOrValue<BigNumberish> | null
    ): RequestWithdrawnEventFilter;

    "ReviewSignal(address,uint256,uint256)"(
      signaler?: PromiseOrValue<string> | null,
      requestId?: PromiseOrValue<BigNumberish> | null,
      quantity?: PromiseOrValue<BigNumberish> | null
    ): ReviewSignalEventFilter;
    ReviewSignal(
      signaler?: PromiseOrValue<string> | null,
      requestId?: PromiseOrValue<BigNumberish> | null,
      quantity?: PromiseOrValue<BigNumberish> | null
    ): ReviewSignalEventFilter;
  };

  estimateGas: {
    claim(
      _requestId: PromiseOrValue<BigNumberish>,
      _submissionId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    claimRemainder(
      _requestId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    deployer(overrides?: CallOverrides): Promise<BigNumber>;

    initialize(
      _deployer: PromiseOrValue<string>,
      _criteria: PromiseOrValue<string>,
      _auxilaries: PromiseOrValue<BigNumberish>[],
      _alphas: PromiseOrValue<BigNumberish>[],
      _betas: PromiseOrValue<BigNumberish>[],
      _sigs: PromiseOrValue<BytesLike>[],
      _nodes: NBadgeAuthInterface.NodeStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    isAuthorized(
      user: PromiseOrValue<string>,
      _sig: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    provide(
      _requestId: PromiseOrValue<BigNumberish>,
      _uri: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    requestIdToAddressToPerformance(
      arg0: PromiseOrValue<BigNumberish>,
      arg1: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    requestIdToRequest(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    requestIdToSignalState(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    review(
      _requestId: PromiseOrValue<BigNumberish>,
      _submissionId: PromiseOrValue<BigNumberish>,
      _score: PromiseOrValue<BigNumberish>,
      _uri: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    signal(
      _requestId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    signalReview(
      _requestId: PromiseOrValue<BigNumberish>,
      _quantity: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    submitRequest(
      _blockNonce: PromiseOrValue<BigNumberish>,
      _request: LaborMarketInterface.ServiceRequestStruct,
      _uri: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    withdrawRequest(
      _requestId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    claim(
      _requestId: PromiseOrValue<BigNumberish>,
      _submissionId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    claimRemainder(
      _requestId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    deployer(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    initialize(
      _deployer: PromiseOrValue<string>,
      _criteria: PromiseOrValue<string>,
      _auxilaries: PromiseOrValue<BigNumberish>[],
      _alphas: PromiseOrValue<BigNumberish>[],
      _betas: PromiseOrValue<BigNumberish>[],
      _sigs: PromiseOrValue<BytesLike>[],
      _nodes: NBadgeAuthInterface.NodeStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    isAuthorized(
      user: PromiseOrValue<string>,
      _sig: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    provide(
      _requestId: PromiseOrValue<BigNumberish>,
      _uri: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    requestIdToAddressToPerformance(
      arg0: PromiseOrValue<BigNumberish>,
      arg1: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    requestIdToRequest(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    requestIdToSignalState(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    review(
      _requestId: PromiseOrValue<BigNumberish>,
      _submissionId: PromiseOrValue<BigNumberish>,
      _score: PromiseOrValue<BigNumberish>,
      _uri: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    signal(
      _requestId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    signalReview(
      _requestId: PromiseOrValue<BigNumberish>,
      _quantity: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    submitRequest(
      _blockNonce: PromiseOrValue<BigNumberish>,
      _request: LaborMarketInterface.ServiceRequestStruct,
      _uri: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    withdrawRequest(
      _requestId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}
