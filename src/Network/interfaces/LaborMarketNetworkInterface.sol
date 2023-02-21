// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { LaborMarketVersionsInterface } from "./LaborMarketVersionsInterface.sol";

interface LaborMarketNetworkInterface {

    function setCapacityImplementation(
        address _implementation
    )
        external;

    function setNetworkRoles(
          LaborMarketVersionsInterface.BadgePair memory _governorBadge
        , LaborMarketVersionsInterface.BadgePair memory _creatorBadge
    ) 
        external;

    function setReputationDecay(
          address _reputationModule
        , address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
        , uint256 _decayStartEpoch
    )
        external;

    function isGovernor(address _sender) 
        external 
        view
        returns (
            bool
        );

    function isCreator(address _sender) 
        external 
        view
        returns (
            bool
        );
}