// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { LaborMarketVersionsInterface } from "./LaborMarketVersionsInterface.sol";

interface LaborMarketNetworkInterface {

    function setCapacityImplementation(
        address _implementation
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