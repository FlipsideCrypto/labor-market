// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ReputationTokenInterface } from "./ReputationTokenInterface.sol";

interface ReputationModuleInterface {
    struct ReputationMarketConfig {
        address reputationToken;
        uint256 signalStake;
        uint256 providerThreshold;
        uint256 maintainerThreshold;
    }

    function createReputationToken(
          address _implementation
        , address _baseToken
        , uint256 _baseTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
    )
        external
        returns (
            address
        );

    function useReputationModule(
          address _laborMarket
        , ReputationMarketConfig calldata _repConfig
    )
        external;

    function setMarketRepConfig(
        ReputationMarketConfig calldata _repConfig
    )
        external;

    function freezeReputation(
          address _account
        , uint256 _frozenUntilEpoch
    )
        external;


    function lockReputation(
          address _account
        , uint256 _amount
    ) 
        external;

    function unlockReputation(
          address _account
        , uint256 _amount
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

    function getReputationAccountInfo(
          address _laborMarket
        , address _account
    )
        external
        view
        returns (
            ReputationTokenInterface.ReputationAccountInfo memory
        );

    function getSignalStake(address _laborMarket)
        external
        view
        returns (
            uint256
        );

    function getProviderThreshold(address _laborMarket)
        external
        view
        returns (
            uint256
        );

    function getMaintainerThreshold(address _laborMarket)
        external
        view
        returns (
            uint256
        );

    function getReputationToken(address _laborMarket) 
        external
        view
        returns (
            address
        );
}