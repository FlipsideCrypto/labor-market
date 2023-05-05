// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarket } from './LaborMarket.sol';
import { LaborMarketFactoryInterface } from './interfaces/LaborMarketFactoryInterface.sol';

/// @dev Helpers interfaces.
import { EnforcementCriteriaInterface } from './interfaces/enforcement/EnforcementCriteriaInterface.sol';

/// @dev Helper libraries.
import { Clones } from '@openzeppelin/contracts/proxy/Clones.sol';

// TODO: Add a disclaimer to the top of this contract warning people to not use it unless they want to watch their money vanish as this is unaudited

contract LaborMarketFactory is LaborMarketFactoryInterface {
    using Clones for address;

    /// @notice The address of the source contract for the paternal Labor Market.
    address public immutable implementation;

    /// @dev Instantiate the Labor Market Factory with an immutable implementation address.
    constructor(address _implementation) {
        implementation = _implementation;
    }

    /**
     * @notice Allows an individual to deploy a new Labor Market given they meet version and badge requirements.
     * @param _deployer The address of the individual intended to own the Labor Market.
     * @param _criteria The address of the Enforcement Criteria contract.
     * @param _auxilaries The array of uints configuring the application of enforcement.
     * @param _alphas The array of uints configuring the application of enforcement.
     * @param _betas The array of uints configuring the application of enforcement.
     * @return laborMarketAddress The address of the newly created Labor Market.
     */
    function createLaborMarket(
        address _deployer,
        EnforcementCriteriaInterface _criteria,
        uint256[] calldata _auxilaries,
        uint256[] calldata _alphas,
        uint256[] calldata _betas
    ) public virtual returns (address laborMarketAddress) {
        /// @notice Get the address of the target.
        address marketAddress = implementation.clone();

        /// @notice Interface with the newly created contract to initialize it.
        LaborMarket laborMarket = LaborMarket(marketAddress);

        /// @notice Deploy the clone contract to serve as the Labor Market.
        laborMarket.initialize(_deployer, _criteria, _auxilaries, _alphas, _betas);

        /// @notice Announce the creation of the Labor Market.
        emit LaborMarketCreated(marketAddress, _deployer, implementation);

        /// @notice Return the address of the newly created Labor Market.
        return marketAddress;
    }
}
