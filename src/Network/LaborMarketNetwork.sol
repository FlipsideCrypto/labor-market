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
     * @notice Allows the owner to set the Governor Badge.
     * @dev This is used to gate the ability to create and update Labor Markets.
     * @param _governorBadge The address of the Governor Badge.
     * @param _governorTokenId The token ID of the Governor Badge.
     * Requirements:
     * - Only the owner can call this function.
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
     * @notice Allows the owner to set the capacity token implementation.
     * @param _implementation The address of the reputation token.
     * Requirements:
     * - Only a Governor can call this function.
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
     * @notice Sets the reputation decay configuration for a token.
     * @param _reputationModule The address of the Reputation Module.
     * @param _reputationToken The address of the Reputation Token.
     * @param _reputationTokenId The token ID of the Reputation Token.
     * @param _decayRate The rate of decay.
     * @param _decayInterval The interval of decay.
     * @param _decayStartEpoch The epoch to start the decay.
     * Requirements:
     * - Only a Governor can call this function.
     */
    function setReputationDecay(
          address _reputationModule
        , address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
        , uint256 _decayStartEpoch
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
            , _decayStartEpoch
        );
    }

    /**
     * @notice Checks if the sender is a Governor.
     * @param _sender The message sender address.
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