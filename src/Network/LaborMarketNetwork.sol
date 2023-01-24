// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { LaborMarketNetworkInterface } from "./interfaces/LaborMarketNetworkInterface.sol";
import { LaborMarketFactory } from "./LaborMarketFactory.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LaborMarketNetwork is
    LaborMarketNetworkInterface,
    LaborMarketFactory
{
    constructor(
          address _factoryImplementation
        , address _capacityImplementation
        , address _governorBadge
        , uint256 _governorTokenId
    ) 
        LaborMarketFactory(
              _factoryImplementation
            , _governorBadge
            , _governorTokenId
        ) 
    {
        capacityToken = IERC20(_capacityImplementation);
    }

    /**
     * See {LaborMarketNetworkInterface.setGovernorBadge}
     */
    function setGovernorBadge(
          address _governorBadge
        , uint256 _governorTokenId
    ) 
        external
        virtual
        override
        onlyOwner
    {
        _setGovernorBadge(_governorBadge, _governorTokenId);
    }

    /**
     * See {LaborMarketNetworkInterface.setCapacityImplementation}
     */
    function setCapacityImplementation(address _implementation)
        external
        virtual
        override
        onlyOwner
    {
        capacityToken = IERC20(_implementation);
    }

    /**
     * See {LaborMarketNetworkInterface.setReputationDecay}
     */
    function setReputationDecay(
          address _reputationModule
        , address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
    )
        external
        virtual
        override
    {
        _validateGovernor(_msgSender());

        _setReputationDecay(
              _reputationModule
            , _reputationToken
            , _reputationTokenId
            , _decayRate
            , _decayInterval
        );
    }

    /**
     * See {LaborMarketNetworkInterface.validateGovernor}
     */
    function validateGovernor(address _sender) 
        external
        view
        virtual
        override
    {
        _validateGovernor(_sender);
    }
}