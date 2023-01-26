// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { LaborMarketConfigurationInterface } from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";

interface LaborMarketNetworkInterface {

    function setCapacityImplementation(
        address _implementation
    )
        external;

    function setGovernorBadge(
        address _governorBadge,
        uint256 _governorTokenId
    ) external;

    function setReputationDecay(
          address _reputationModule
        , address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
        , uint256 _decayStartEpoch
    )
        external;

    function validateGovernor(address _sender) 
        external 
        view;
}