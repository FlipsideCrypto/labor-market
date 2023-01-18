// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { ReputationModuleInterface } from "src/Modules/Reputation/interfaces/ReputationModuleInterface.sol";

interface LaborMarketConfigurationInterface {
    struct LaborMarketConfiguration {
        address network;
        address enforcementModule;
        address paymentModule;
        string marketUri;
        address delegateBadge;
        uint256 delegateTokenId;
        address maintainerBadge;
        uint256 maintainerTokenId;
        address reputationModule;
        ReputationModuleInterface.ReputationMarketConfig reputationConfig;
    }
}
