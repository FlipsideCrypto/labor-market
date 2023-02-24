import { abi as ReputationTokenABI } from "./abis/BadgerOrganization";
import { abi as LaborMarketABI } from "./abis/LaborMarket";
import { abi as LaborMarketNetworkABI } from "./abis/LaborMarketNetwork";
import { abi as ReputationModuleABI } from "./abis/ReputationModule";
import { abi as ScalableLikertEnforcementABI } from "./abis/ScalableLikertEnforcement";

export const ReputationToken = {
    "address": "0x854DE1bf96dFBe69FC46f1a888d26934Ad47B77f" as const,
    "abi": ReputationTokenABI
}
export const LaborMarket = {
    "address": "0x7e5999E5289f1A4e9Cea3bfB6fCF83b04c2c845A" as const,
    "abi": LaborMarketABI
}
export const LaborMarketNetwork = {
    "address": "0x7b8f452916847f1bC04e187Ce8a47462Da44895C" as const,
    "abi": LaborMarketNetworkABI
}
export const ReputationModule = {
    "address": "0xdE18D5182d90B3eE8909d90475b19c1b51E5Bc2b" as const,
    "abi": ReputationModuleABI
}
export const ScalableLikertEnforcement = {
    "address": "0x9C2B003A97E151559AaBCC607E6653eE1C27AE19" as const,
    "abi": ScalableLikertEnforcementABI
}