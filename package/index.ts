import { abi as PaymentTokenABI } from "./abis/ERC1155";
import { abi as AnyReputationTokenABI } from "./abis/ERC1155";
import { abi as LaborMarketABI } from "./abis/LaborMarket";
import { abi as ReputationEngineABI } from "./abis/ReputationEngine";
import { abi as LaborMarketFactoryABI } from "./abis/LaborMarketFactory";
import { abi as LaborMarketNetworkABI } from "./abis/LaborMarketNetwork";
import { abi as ReputationModuleABI } from "./abis/ReputationModule";
import { abi as LikertEnforcementABI } from "./abis/LikertEnforcementCriteria";
import { abi as PaymentModuleABI } from "./abis/PaymentModule";
import { abi as PayCurveABI } from "./abis/PayCurve";

export const PaymentToken = {
    "address": "0xc932d7b29390bdbd94057457392731fb7b1f856c" as const,
    "abi": PaymentTokenABI
}
export const AnyReputationToken = {
    "address": "0xf219b405c46406ed7786a9ec51767432a3991c79" as const,
    "abi": AnyReputationTokenABI
}
export const LaborMarket = {
    "address": "0xccbc48a243ef99f975617b0900547e32eea7f87a" as const,
    "abi": LaborMarketABI
}
export const ReputationEngine = {
    "address": "0x42c06b7f401d8d5ae65301881ce4331de2168729" as const,
    "abi": ReputationEngineABI
}
export const LaborMarketFactory = {
    "address": "0x509b65a8616b6898aa9af5e4cefd1703515758b9" as const,
    "abi": LaborMarketFactoryABI
}
export const LaborMarketNetwork = {
    "address": "0x78d8d24c5a2d8717d64ba3bedb80c2500200fcbc" as const,
    "abi": LaborMarketNetworkABI
}
export const ReputationModule = {
    "address": "0x5f701ce3f83402398832fe163c40c5380466c099" as const,
    "abi": ReputationModuleABI
}
export const LikertEnforcement = {
    "address": "0xb6d253d25a0019d90cf67478acf73126c3cea41a" as const,
    "abi": LikertEnforcementABI
}
export const PaymentModule = {
    "address": "0x59ddc8a7429cda1e02cc05057da9a77f7fb9a171" as const,
    "abi": PaymentModuleABI
}
export const PayCurve = {
    "address": "0x3055c2f474c5da064e15f09740302d1a9f5819b6" as const,
    "abi": PayCurveABI
}