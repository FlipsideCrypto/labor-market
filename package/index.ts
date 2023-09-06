import { abi as LaborMarketABI } from './abis/LaborMarket';
import { abi as LaborMarketFactoryABI } from './abis/LaborMarketFactory';
import { abi as BucketEnforcementABI } from './abis/BucketEnforcement';

export const LaborMarket = {
    address: '0xF89a26006AbB9a72b2b41abAE575821eD02aC134' as const,
    abi: LaborMarketABI,
};
export const LaborMarketFactory = {
    address: '0x1D9285FeF4a58256A2A58A1a66AC7739Ee9dAA3A' as const,
    abi: LaborMarketFactoryABI,
};
export const BucketEnforcement = {
    address: '0xc104a1884e9788db6426c56F44daA5121c72A97E' as const,
    abi: BucketEnforcementABI,
};
