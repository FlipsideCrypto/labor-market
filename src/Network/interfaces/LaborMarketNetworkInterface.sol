// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface LaborMarketNetworkInterface {
    struct ReputationToken {
        ReputationTokenConfig config;
        mapping(address => BalanceInfo) balanceInfo;
    }

    struct ReputationTokenConfig {
        address manager;
        uint256 decayRate;
        uint256 decayInterval;
        uint256 baseSignalStake;
        uint256 baseMaintainerThreshold;
        uint256 baseProviderThreshold;
    }
    
    struct BalanceInfo {
        uint256 locked;
        uint256 lastDecayEpoch;
        uint256 frozenUntilEpoch;
    }

    function setCapacityImplementation(
        address _capacityImplementation
    )
        external;


    function freezeReputation(
          address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _frozenUntilEpoch
    ) 
        external;

    function lockReputation(
          address _account
        , address _reputationImplementation
        , uint256 _reputationTokenId
        , uint256 _amount
    ) 
        external;

    function getAvailableReputation(
          address _account
        , address _reputationToken
        , uint256 _reputationTokenId
    )
        external
        view
        returns (
            uint256
        );

    function getReputationManager(
          address _reputationImplementation
        , uint256 _reputationTokenId
    )
        external
        view
        returns (
            address
        );

    function getPendingDecay(
          address _reputationImplementation
        , uint256 _reputationTokenId
        , uint256 _lastDecayEpoch
        , uint256 _frozenUntilEpoch
    )
        external 
        view 
        returns (
            uint256
        );

    function getDecayRate(
          address _reputationImplementation
        , uint256 _reputationTokenId
    )
        external
        view
        returns (
            uint256
        );

    function getDecayInterval(
          address _reputationImplementation
        , uint256 _reputationTokenId
    )
        external
        view
        returns (
            uint256
        );

    function getBaseSignalStake(
          address _reputationImplementation
        , uint256 _reputationTokenId
    )
        external
        view
        returns (
            uint256
        );

    function getBaseMaintainerThreshold(
          address _reputationImplementation
        , uint256 _reputationTokenId
    )
        external
        view
        returns (
            uint256
        );

    function getBaseProviderThreshold(
          address _reputationImplementation
        , uint256 _reputationTokenId
    )
        external
        view
        returns (
            uint256
        );

}
