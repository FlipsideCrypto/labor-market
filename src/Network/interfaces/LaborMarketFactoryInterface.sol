// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { LaborMarketVersionsInterface } from "./LaborMarketVersionsInterface.sol";
import { ReputationModuleInterface } from "../../Modules/Reputation/interfaces/ReputationModuleInterface.sol";


interface LaborMarketFactoryInterface is LaborMarketVersionsInterface {
    /**
     * @notice Allows an individual to deploy a new Labor Market given they meet the version funding requirements.
     * @param _implementation The address of the implementation to be used.
     * @param _configuration The struct containing the config of the Market being created.
     */
    function createLaborMarket(
          address _implementation
        , LaborMarketConfiguration calldata _configuration
    ) 
        external 
        returns (
            address
        );
}
