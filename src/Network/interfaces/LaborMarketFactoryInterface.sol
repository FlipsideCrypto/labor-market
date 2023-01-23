// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { LaborMarketVersionsInterface } from "./LaborMarketVersionsInterface.sol";
import { ReputationModuleInterface } from "../../Modules/Reputation/interfaces/ReputationModuleInterface.sol";


interface LaborMarketFactoryInterface is LaborMarketVersionsInterface {
    /**
     * @notice Allows an individual to deploy a new Labor Market given they meet the version funding requirements.
     * @param _implementation The address of the implementation to be used.
     * @param _deployer The address that will be the deployer of the Labor Market contract.
     * @param _configuration The struct containing the config of the Market being created.
     */
    function createLaborMarket(
          address _implementation
        , address _deployer
        , LaborMarketConfiguration calldata _configuration
    ) 
        external 
        returns (
            address
        );
}
