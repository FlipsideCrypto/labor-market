// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarketInterface } from './interfaces/LaborMarketInterface.sol';
import { ERC1155HolderUpgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol';
import { Delegatable } from 'delegatable/Delegatable.sol';

/// @dev Helper interfaces.
import { LaborMarketNetworkInterface } from '../Network/interfaces/LaborMarketNetworkInterface.sol';
import { EnforcementCriteriaInterface } from '../Modules/Enforcement/interfaces/EnforcementCriteriaInterface.sol';
import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @dev Supported interfaces.
import { IERC1155ReceiverUpgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol';
import { EnumerableSet } from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

contract LaborMarketManager is LaborMarketInterface, ERC1155HolderUpgradeable, Delegatable('LaborMarket', 'v1.0.0') {

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/

    /// @dev The network contract.
    // TODO: Need to fix this
    LaborMarketNetworkInterface internal network;

    /// @dev The enforcement criteria.
    // TODO: Will need to finalize with the implementation of the enforcement criteria.
    EnforcementCriteriaInterface internal criteria;

    /// @dev The configuration of the labor market.
    // TODO: Why is this a struct?
    LaborMarketConfiguration public configuration;


    /*//////////////////////////////////////////////////////////////
                            SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Prevent implementation from being initialized.
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the labor market.
    function initialize(LaborMarketConfiguration calldata _configuration) external override initializer {
        network = LaborMarketNetworkInterface(_configuration.modules.network);

        /// @dev Configure the Labor Market state control.
        criteria = EnforcementCriteriaInterface(_configuration.modules.enforcement);

        /// @dev Configure the Labor Market parameters.
        configuration = _configuration;

        emit LaborMarketConfigured(_configuration);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    // // TODO: What is this function for? // <-- Easy getter for frontend. Can remove or move out to enforcement tho
    // /**
    //  * @notice Gets the amount of pending rewards for a submission.
    //  * @param _submissionId The id of the service submission.
    //  * @return pTokenToClaim The amount of pTokens to be claimed.
    //  * @return rTokenToClaim The amount of rTokens to be claimed.
    //  */
    // function getRewards(uint256 _submissionId) external view returns (uint256 pTokenToClaim, uint256 rTokenToClaim) {
    //     return (0, 0);

    //     address provider = serviceIdToSubmission[_submissionId].serviceProvider;

    //     /// @dev The provider must have not claimed rewards.
    //     if (requestIdToAddressToPerformance[_submissionId][provider][HAS_CLAIMED]) {
    //         return (0, 0);
    //     }

    //     return enforcementCriteria.getRewards(address(this), _submissionId);
    // }
}
