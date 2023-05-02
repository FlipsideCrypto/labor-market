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

contract LaborMarketManager is LaborMarkeInterface, ERC1155HolderUpgradeable, Delegatable('LaborMarket', 'v1.0.0') {
    /// @dev Performable actions.
    bytes32 public immutable HAS_SUBMITTED = keccak256('hasSubmitted');

    bytes32 public immutable HAS_CLAIMED = keccak256('hasClaimed');

    bytes32 public immutable HAS_REVIEWED = keccak256('hasReviewed');

    bytes32 public immutable HAS_SIGNALED = keccak256('hasSignaled');

    /*//////////////////////////////////////////////////////////////
                            STATE
    //////////////////////////////////////////////////////////////*/

    /// @dev The network contract.
    LaborMarketNetworkInterface internal network;

    /// @dev The enforcement criteria.
    EnforcementCriteriaInterface internal enforcementCriteria;

    /// @dev The delegate badge.
    IERC1155 internal delegateBadge;

    /// @dev The maintainer badge.
    IERC1155 internal maintainerBadge;

    /// @dev The configuration of the labor market.
    LaborMarketConfiguration public configuration;

    /// @dev Tracking the signals per service request.
    mapping(uint256 => uint256) public signalCount;

    /// @dev Tracking the service requests.
    mapping(uint256 => ServiceRequest) public serviceIdToRequest;

    /// @dev Tracking the service submissions.
    mapping(uint256 => ServiceSubmission) public serviceIdToSubmission;

    // / @dev Tracking the review signals.
    // mapping(uint256 => mapping(address => ReviewPromise)) public requestToAddressToReview;

    /// @dev Tracking whether an action has been performed.
    mapping(uint256 => mapping(address => uint24)) requestIdToAddressToPerformanceState;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when labor market parameters are updated.
    event LaborMarketConfigured(LaborMarketConfiguration indexed configuration);

    /// @notice emitted when a new service request is made.
    event RequestConfigured(
        address indexed requester,
        uint256 indexed requestId,
        string indexed uri,
        IERC20 pToken,
        uint256 pTokenQ,
        uint256 signalExp,
        uint256 submissionExp,
        uint256 enforcementExp
    );

    /// @notice emitted when a user signals a service request.
    event RequestSignal(address indexed signaler, uint256 indexed requestId);

    /// @notice emitted when a maintainer signals a review.
    event ReviewSignal(address indexed signaler, uint256 indexed requestId, uint256 indexed quantity);

    /// @notice emitted when a service request is withdrawn.
    event RequestWithdrawn(uint256 indexed requestId);

    /// @notice emitted when a service request is fulfilled.
    event RequestFulfilled(
        address indexed fulfiller,
        uint256 indexed requestId,
        uint256 indexed submissionId,
        string uri
    );

    /// @notice emitted when a service submission is reviewed
    event RequestReviewed(
        address indexed reviewer,
        uint256 indexed requestId,
        uint256 indexed submissionId,
        uint256 reviewScore
    );

    /// @notice emitted when a service submission is claimed.
    event RequestPayClaimed(
        address indexed claimer,
        uint256 indexed requestId,
        uint256 indexed submissionId,
        uint256 payAmount,
        address to
    );

    /// @notice emitted when a remainder is claimed.
    event RemainderClaimed(address indexed claimer, uint256 indexed requestId, uint256 remainderAmount);

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
        enforcementCriteria = EnforcementCriteriaInterface(_configuration.modules.enforcement);

        /// @dev Configure the Labor Market parameters.
        configuration = _configuration;

        emit LaborMarketConfigured(_configuration);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the amount of pending rewards for a submission.
     * @param _submissionId The id of the service submission.
     * @return pTokenToClaim The amount of pTokens to be claimed.
     * @return rTokenToClaim The amount of rTokens to be claimed.
     */
    function getRewards(uint256 _submissionId) external view returns (uint256 pTokenToClaim, uint256 rTokenToClaim) {
        address provider = serviceIdToSubmission[_submissionId].serviceProvider;

        /// @dev The provider must have not claimed rewards.
        if (requestIdToAddressToPerformanceState[_submissionId][provider][HAS_CLAIMED]) {
            return (0, 0);
        }

        return enforcementCriteria.getRewards(address(this), _submissionId);
    }
}
