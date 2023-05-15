// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Helpers interfaces.
import { EnforcementCriteriaInterface } from './enforcement/EnforcementCriteriaInterface.sol';
import { NBadgeAuthInterface } from './auth/NBadgeAuthInterface.sol';

interface LaborMarketFactoryInterface {
    /// @dev Announces when a new Labor Market is created through the protocol Factory.
    event LaborMarketCreated(address indexed marketAddress, address indexed deployer, address indexed implementation);

    /**
     * @notice Allows an individual to deploy a new Labor Market.
     * @param _deployer The address of the individual intended to own the Labor Market.
     * @param _criteria The address of enforcement criteria contract.
     * @param _auxilaries The array of uints configuring the application of enforcement.
     * @param _alphas The array of uints configuring the application of enforcement.
     * @param _betas The array of uints configuring the application of enforcement.
     * @param _sigs The array of bytes4 configuring the functions with applied permissions.
     * @param _nodes The array of nodes configuring permission definition.
     * @return laborMarketAddress The address of the newly created Labor Market.
     */
    function createLaborMarket(
        address _deployer,
        EnforcementCriteriaInterface _criteria,
        uint256[] calldata _auxilaries,
        uint256[] calldata _alphas,
        uint256[] calldata _betas,
        bytes4[] calldata _sigs,
        NBadgeAuthInterface.Node[] calldata _nodes
    ) external returns (address laborMarketAddress);
}
