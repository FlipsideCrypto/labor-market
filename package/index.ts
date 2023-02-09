import { abi as PaymentTokenABI } from "./abis/ERC20";
import { abi as ReputationTokenABI } from "./abis/BadgerOrganization";
import { abi as LaborMarketABI } from "./abis/LaborMarket";
import { abi as LaborMarketNetworkABI } from "./abis/LaborMarketNetwork";
import { abi as ReputationModuleABI } from "./abis/ReputationModule";
import { abi as ConstantLikertEnforcementABI } from "./abis/ConstantLikertEnforcement";
// import { abi as PaymentModuleABI } from "./abis/PaymentModule";
import { abi as PayCurveABI } from "./abis/PayCurve";

export const PaymentToken = {
    "address": "0xD1Dee0DD6C89FB4d902818C54DD88B3555Ad7df2" as const,
    "abi": PaymentTokenABI
}
export const ReputationToken = {
    "address": "0x854DE1bf96dFBe69FC46f1a888d26934Ad47B77f" as const,
    "abi": ReputationTokenABI
}
export const LaborMarket = {
    "address": "0x2c02b0849c6c6e5e274f94179926bf7f3b50569e" as const,
    "abi": LaborMarketABI
}
export const LaborMarketNetwork = {
    "address": "0x57bD82488017e1b32b3BeD03389fBCB6D69750b8" as const,
    "abi": LaborMarketNetworkABI
}
export const ReputationModule = {
    "address": "0xCC2B59CF632238170966548623f876085C68349e" as const,
    "abi": ReputationModuleABI
}
export const ConstantLikertEnforcement = {
    "address": "0x8D9A907D6Aa8e197AB39b7B00195Ad6956688aFC" as const,
    "abi": ConstantLikertEnforcementABI
}
/// NOTE: Currently PaymentModule is unused and operates the same as the PayCurve contract.
export const PaymentModule = {
    "address": "0xBbe1a8412a4FE1d006BAbb92d4450e60ff427066" as const,
    "abi": PayCurveABI
}
export const PayCurve = {
    "address": "0xBbe1a8412a4FE1d006BAbb92d4450e60ff427066" as const,
    "abi": PayCurveABI
}