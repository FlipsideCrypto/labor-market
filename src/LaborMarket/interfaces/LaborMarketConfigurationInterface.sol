// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface LaborMarketConfigurationInterface {
    struct LaborMarketConfiguration {
        string marketUri;
        address owner;
        Modules modules;
        BadgePair delegateBadge;
        BadgePair maintainerBadge;
        BadgePair reputationBadge;
        ReputationParams reputationParams;
    }

    struct ReputationParams {
        uint256 rewardPool;
        uint256 signalStake;
        uint256 submitMin;
        uint256 submitMax;
    }

    struct Modules {
        address network;
        address enforcement;
        address payment;
        address reputation;
    }

    struct BadgePair {
        address token;
        uint256 tokenId;
    }
}