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
     * @notice Checks if the sender is a Governor.
     * @param _sender The message sender address.
     */
    function validateGovernor(address _sender) 
        external 
        view;
}