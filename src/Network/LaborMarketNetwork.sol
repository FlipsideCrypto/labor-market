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
    ) 
        LaborMarketFactory(
              _factoryImplementation
        ) 
    {
        capacityToken = IERC20(_capacityImplementation);
    }

    /**
     * @notice Allows the owner to set the capacity token implementation.
     * @param _implementation The address of the capacity token.
     *
     * Requirements:
     * - Only a Governor can call this function.
     */
    function setCapacityImplementation(address _implementation)
        external
        virtual
        onlyGovernor(_msgSender())
    {   
        capacityToken = IERC20(_implementation);
    }
}