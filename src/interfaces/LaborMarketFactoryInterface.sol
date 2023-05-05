// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Helpers interfaces.
import { EnforcementCriteriaInterface } from './enforcement/EnforcementCriteriaInterface.sol';

interface LaborMarketFactoryInterface {
    /// @dev Announces when a new Labor Market is created through the protocol Factory.
    event LaborMarketCreated(address indexed marketAddress, address indexed deployer, address indexed implementation);

    /**
     * @notice Allows an individual to deploy a new Labor Market given they meet the version funding requirements.
     */
    function createLaborMarket(
        address _deployer,
        EnforcementCriteriaInterface _criteria,
        uint256[] calldata _auxilaries,
        uint256[] calldata _alphas,
        uint256[] calldata _betas
    ) external returns (address laborMarketAddress);
}
