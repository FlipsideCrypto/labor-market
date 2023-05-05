// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @dev Helper interfaces.
import { EnforcementCriteriaInterface } from './enforcement/EnforcementCriteriaInterface.sol';

interface LaborMarketInterface {
    struct ServiceRequest {
        uint48 signalExp;
        uint48 submissionExp;
        uint48 enforcementExp;
        uint64 providerLimit;
        uint64 reviewerLimit;
        uint256 pTokenProviderTotal;
        uint256 pTokenReviewerTotal;
        IERC20 pTokenProvider;
        IERC20 pTokenReviewer;
    }

    struct ServiceSignalState {
        uint64 providers;
        uint64 reviewers;
        uint64 providersArrived;
        uint64 reviewersArrived;
    }

    /// @notice Emitted when labor market parameters are updated.
    event LaborMarketConfigured(address deployer, address criteria);

    /// @notice emitted when a new service request is made.
    event RequestConfigured(
        address indexed requester,
        uint256 requestId,
        uint48 signalExp,
        uint48 submissionExp,
        uint48 enforcementExp,
        uint64 providerLimit,
        uint64 reviewerLimit,
        uint256 pTokenProviderTotal,
        uint256 pTokenReviewerTotal,
        IERC20 indexed pTokenProvider,
        IERC20 indexed pTokenReviewer,
        string uri
    );

    /// @notice emitted when a user signals a service request.
    event RequestSignal(address indexed signaler, uint256 indexed requestId);

    /// @notice emitted when a maintainer signals a review.
    event ReviewSignal(address indexed signaler, uint256 indexed requestId, uint256 indexed quantity);

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
        uint256 reviewScore,
        string uri
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
    event RemainderClaimed(address indexed claimer, uint256 indexed requestId, address indexed to, bool settled);

    /// @notice emitted when a service request is withdrawn.
    event RequestWithdrawn(uint256 indexed requestId);

    // TODO: Put the correct functions here. This is not LaborMarketManagerInterface
}
