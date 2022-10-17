// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface LaborMarketConfigurationInterface {
    struct LaborMarketConfiguration {
        address network;
        address enforcementModule;
        address paymentModule;
        address delegateBadge;
        uint256 delegateTokenId;
        address reputationToken;
        uint256 reputationTokenId;
        uint256 repParticipantMultiplier;
        uint256 repMaintainerMultiplier;
        string marketUri;
    }
}
