// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LaborMarketNetworkInterface } from "./interfaces/LaborMarketNetworkInterface.sol";
import { LaborMarketFactory } from "./LaborMarketFactory.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LaborMarketNetwork is LaborMarketFactory {
    IERC20 public capacityToken;

    constructor(
        address _factoryImplementation,
        address _capacityImplementation
    ) LaborMarketFactory(_factoryImplementation) {
        capacityToken = IERC20(_capacityImplementation);
    }

    /**
     * @notice Allows the owner to set the capacity token implementation.
     * @param _implementation The address of the reputation token.
     * Requirements:
     * - Only the owner can call this function.
     */
    function setCapacityImplementation(address _implementation)
        external
        virtual
        onlyOwner
    {
        capacityToken = IERC20(_implementation);
    }
}