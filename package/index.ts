import { abi as PaymentTokenABI } from "./abis/ERC20";
import { abi as ReputationTokenABI } from "./abis/ERC1155";
import { abi as LaborMarketABI } from "./abis/LaborMarket";
import { abi as ReputationEngineABI } from "./abis/ReputationEngine";
import { abi as LaborMarketNetworkABI } from "./abis/LaborMarketNetwork";
import { abi as ReputationModuleABI } from "./abis/ReputationModule";
import { abi as LikertEnforcementABI } from "./abis/LikertEnforcementCriteria";
import { abi as PaymentModuleABI } from "./abis/PaymentModule";
import { abi as PayCurveABI } from "./abis/PayCurve";

export const PaymentToken = {
    "address": "0xD1Dee0DD6C89FB4d902818C54DD88B3555Ad7df2" as const,
    "abi": PaymentTokenABI
}
export const ReputationToken = {
    "address": "0x0034F6CF1ec2A5b51497D06C0619985945F6A5d4" as const,
    "abi": ReputationTokenABI
}
export const LaborMarket = {
    "address": "0xB9464209bEeb537050A5278AEB4E450E7C0Bed0A" as const,
    "abi": LaborMarketABI
}
export const ReputationEngine = {
    "address": "0x1585c93cf4F74230F6dC4378cDa2B98187A4A40E" as const,
    "abi": ReputationEngineABI
}
export const LaborMarketNetwork = {
    "address": "0x6EbBE4A8c2F58bDB59F906Cb1Fc5A14B2bF5471C" as const,
    "abi": LaborMarketNetworkABI
}
export const ReputationModule = {
    "address": "0xcb2241adD515189b661423E04d9917fFDb90CD01" as const,
    "abi": ReputationModuleABI
}
export const LikertEnforcement = {
    "address": "0xA49d7AE1aa90e384704749Ea78093577a70cD87c" as const,
    "abi": LikertEnforcementABI
}
export const PaymentModule = {
    "address": "0x83e16f89627B1Ce73F5000c1225f4673a2Cf3deB" as const,
    "abi": PaymentModuleABI
}
export const PayCurve = {
    "address": "0x67bf50b4688Ff31194C74084D8c0903F59cb098B" as const,
    "abi": PayCurveABI
}