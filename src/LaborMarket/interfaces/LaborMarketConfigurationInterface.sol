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
        uint256 rewardPool; // rToken total rewards for a request. Will be removed in V2
        uint256 provideStake; // The rToken stake to signal to provide.
        uint256 reviewStake; // The rToken stake to signal to review.
        uint256 submitMin; // The minimum of rToken required to submit.
        uint256 submitMax; // The maximum of rToken allowed to submit.
    }

    struct Modules {
        address network; // The network module.
        address reputation; // The reputation module.
        address enforcement; // The enforcement module.
        bytes32 enforcementKey; // The enforcement key for bucket config.
    }

    struct BadgePair {
        address token;
        uint256 tokenId;
    }
}