// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

// import { ReputationModuleInterface } from "src/Modules/Reputation/interfaces/ReputationModuleInterface.sol";

interface LaborMarketConfigurationInterface {
    struct LaborMarketConfiguration {
        string marketUri;
        address network;
        address enforcementModule;
        address paymentModule;
        address reputationModule;
        address delegateBadge;
        uint256 delegateTokenId;
        address maintainerBadge;
        uint256 maintainerTokenId;
        uint256 signalStake;
        uint256 submitMin;
        uint256 submitMax;
    }
}