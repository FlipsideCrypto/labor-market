// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface ReputationModuleInterface {
    struct MarketReputationConfig {
        address reputationToken;
        uint256 reputationTokenId;
    }

    struct DecayConfig {
        uint256 decayRate;
        uint256 decayInterval;
        uint256 decayStartEpoch;
    }

    struct ReputationAccountInfo {
        uint256 lastDecayEpoch;
        uint256 frozenUntilEpoch;
    }

    function useReputationModule(
          address _laborMarket
        , address _reputationToken
        , uint256 _reputationTokenId
    )
        external;
        
    function revokeReputation(
          address _account
        , uint256 _amount
    )
        external;

    function mintReputation(
          address _account
        , uint256 _amount
    )
        external;

    function freezeReputation(
          address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _frozenUntilEpoch
    )
        external; 


    function setDecayConfig(
          address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
        , uint256 _decayStartEpoch
    )
        external;

    function getAvailableReputation(
          address _laborMarket
        , address _account
    )
        external
        view
        returns (
            uint256
        );

    function getPendingDecay(
          address _laborMarket
        , address _account
    )
        external
        view
        returns (
            uint256
        );
}