// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarket } from './LaborMarket.sol';
import { LaborMarketFactoryInterface } from './interfaces/LaborMarketFactoryInterface.sol';

/// @dev Helper libraries.
import { Clones } from '@openzeppelin/contracts/proxy/Clones.sol';

/// @dev Helpers interfaces.
import { EnforcementCriteriaInterface } from './interfaces/enforcement/EnforcementCriteriaInterface.sol';
import { NBadgeAuthInterface } from './interfaces/auth/NBadgeAuthInterface.sol';

/**
 * @title LaborMarketFactory
 * @dev Version: v2.0.0+unaudited (All usage is at your own risk!)
 * @author @flipsidecrypto // @metricsdao
 * @author @sftchance // @masonchain // @drakedanner // @jimmyerstech
 * @notice This factory contract instantiates new local versions of a Labor Market based on the configuration provided. The factory contract is
 *         intended to be deployed once and then used to deploy many Labor Markets to enable cross-market liquidity products.
 */
contract LaborMarketFactory is LaborMarketFactoryInterface {
    using Clones for address;

    /// @notice The address of the source contract for the paternal Labor Market.
    address public immutable implementation;

    /// @notice Instantiate the Labor Market Factory with an immutable implementation address.
    constructor(address _implementation) {
        implementation = _implementation;
    }

    /**
     * See {LaborMarketFactoryInterface-createLaborMarket}.
     */
    function createLaborMarket(
        address _deployer,
        EnforcementCriteriaInterface _criteria,
        uint256[] calldata _auxilaries,
        uint256[] calldata _alphas,
        uint256[] calldata _betas,
        bytes4[] calldata _sigs,
        NBadgeAuthInterface.Node[] calldata _nodes
    ) public virtual returns (address laborMarketAddress) {
        /// @notice Get the address of the target.
        address marketAddress = implementation.clone();

        /// @notice Interface with the newly created contract to initialize it.
        LaborMarket laborMarket = LaborMarket(marketAddress);

        /// @notice Deploy the clone contract to serve as the Labor Market.
        laborMarket.initialize(_deployer, _criteria, _auxilaries, _alphas, _betas, _sigs, _nodes);

        /// @notice Announce the creation of the Labor Market.
        emit LaborMarketCreated(marketAddress, _deployer, implementation);

        /// @notice Return the address of the newly created Labor Market.
        return marketAddress;
    }
}
