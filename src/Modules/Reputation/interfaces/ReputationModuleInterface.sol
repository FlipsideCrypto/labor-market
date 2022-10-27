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

    event ReputationTokenCreated (
        address indexed reputationToken,
        address indexed baseToken,
        uint256 indexed baseTokenId,
        address owner,
        uint256 decayRate,
        uint256 decayInterval
    );

    event MarketReputationConfigured (
        address indexed market,
        ReputationMarketConfig indexed config
    );

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
        address _account,
        uint256 _amount
    ) 
        external;

    function unlockReputation(
        address _account,
        uint256 _amount
    ) 
        external;

    function setDecayConfig(
        uint256 _decayRate,
        uint256 _decayInterval
    ) 
        external;

    function getAvailableReputation(address _account)
        external
        view
        returns (
            uint256
        );

    function getPendingDecay(address _account)
        external
        view
        returns (
            uint256
        );

    function getReputationAccountInfo(address _account)
        external
        view
        returns (
            ReputationTokenInterface.ReputationAccountInfo memory
        );

    function signalStake()
        external
        view
        returns (
            uint256
        );

    function providerThreshold()
        external
        view
        returns (
            uint256
        );

    function maintainerThreshold()
        external
        view
        returns (
            uint256
        );

    function repToken() 
        external
        view
        returns (
            address
        );
}