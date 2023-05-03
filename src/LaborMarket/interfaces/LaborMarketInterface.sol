// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { EnumerableSet } from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

interface LaborMarketInterface {
    struct LaborMarketConfiguration {
        string marketUri;
        address owner;
        Modules modules;
    }

    struct Modules {
        address network;
        address enforcement;
        bytes32 enforcementKey;
    }

    struct ServiceRequest {
        uint48 signalExp;
        uint48 submissionExp;
        uint48 enforcementExp;
        uint256 pTokenQ;
        address serviceRequester;
        IERC20 pToken;
        EnumerableSet.AddressSet submissions;
    }

    struct ServiceSignalState {
        uint128 providers;
        uint128 reviewers;
    }

    /// @notice emitted when labor market parameters are updated.
    event LaborMarketConfigured(LaborMarketConfiguration indexed configuration);

    /// @notice emitted when a new service request is made.
    event RequestConfigured(
        address indexed requester,
        uint256 indexed requestId,
        uint256 signalExp,
        uint256 submissionExp,
        uint256 enforcementExp,
        IERC20 pToken,
        uint256 pTokenQ,
        string uri
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
    event RemainderClaimed(address indexed claimer, uint256 indexed requestId, uint256 remainderAmount, address to);

    function initialize(LaborMarketConfiguration calldata _configuration) external;
}
