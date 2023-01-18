// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { ReputationEngineInterface } from "./ReputationEngineInterface.sol";

interface ReputationModuleInterface {
    struct MarketReputationConfig {
        address reputationEngine;
        uint256 signalStake;
        uint256 submitMin;
        uint256 submitMax;
    }

    function createReputationEngine(
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
        , MarketReputationConfig calldata _repConfig
    )
        external;

    function setMarketRepConfig(
        MarketReputationConfig calldata _repConfig
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
            ReputationEngineInterface.ReputationAccountInfo memory
        );

    function getMarketReputationConfig(address _laborMarket)
        external
        view
        returns (
            MarketReputationConfig memory
        );

    function getReputationEngine(address _laborMarket) 
        external
        view
        returns (
            address
        );
}