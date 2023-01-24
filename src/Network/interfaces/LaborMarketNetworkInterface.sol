// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { LaborMarketConfigurationInterface } from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";

interface LaborMarketNetworkInterface {

    /**
     * @notice Allows the owner to set the capacity token implementation.
     * @param _implementation The address of the reputation token.
     * Requirements:
     * - Only a Governor can call this function.
     */
    function setCapacityImplementation(address _implementation)
        external;

    /**
     * @notice Allows the owner to set the Governor Badge.
     * @dev This is used to gate the ability to create and update Labor Markets.
     * @param _governorBadge The address of the Governor Badge.
     * @param _governorTokenId The token ID of the Governor Badge.
     * Requirements:
     * - Only the owner can call this function.
     */
    function setGovernorBadge(
        address _governorBadge,
        uint256 _governorTokenId
    ) external;

    /**
     * @notice Sets the reputation decay configuration for a token.
     * @param _reputationModule The address of the Reputation Module.
     * @param _reputationToken The address of the Reputation Token.
     * @param _reputationTokenId The token ID of the Reputation Token.
     * @param _decayRate The rate of decay.
     * @param _decayInterval The interval of decay.
     * Requirements:
     * - Only a Governor can call this function.
     */
    function setReputationDecay(
          address _reputationModule
        , address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
    )
        external;

    /**
     * @notice Checks if the sender is a Governor.
     * @param _sender The message sender address.
     */
    function validateGovernor(address _sender) 
        external 
        view;
}