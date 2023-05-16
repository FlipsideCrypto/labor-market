import { abi as LaborMarketABI } from './abis/LaborMarket';
import { abi as LaborMarketFactoryABI } from './abis/LaborMarketFactory';
import { abi as BucketEnforcementABI } from './abis/BucketEnforcement';

export const LaborMarket = {
    address: '0xc8f98075fcfA38024069Be0b2202d25bA22C682c' as const,
    abi: LaborMarketABI,
};
export const LaborMarketFactory = {
    address: '0x95be852eCa7d66A406e283b1d79DB268Dff698a0' as const,
    abi: LaborMarketFactoryABI,
};
export const BucketEnforcement = {
    address: '0x7207dDC1A67d18A953e97E373617F338efe1677E' as const,
    abi: BucketEnforcementABI,
};
