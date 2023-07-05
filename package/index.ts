import { abi as LaborMarketABI } from './abis/LaborMarket';
import { abi as LaborMarketFactoryABI } from './abis/LaborMarketFactory';
import { abi as BucketEnforcementABI } from './abis/BucketEnforcement';

export const LaborMarket = {
    address: '0x74a18fC4a7b9f09c08c4e0fF31226f11eb2f9966' as const,
    abi: LaborMarketABI,
};
export const LaborMarketFactory = {
    address: '0x93e6830873847e7eF966c030BcFD21037cA8552C' as const,
    abi: LaborMarketFactoryABI,
};
export const BucketEnforcement = {
    address: '0x355A284eA2494E299Bd2E4046DA17ac28F3Dc8b4' as const,
    abi: BucketEnforcementABI,
};
