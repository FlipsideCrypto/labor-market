// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { EnumerableSet } from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

interface EnforcementCriteriaInterface {
    /// @dev The relevant scoring criteria for a request.
    struct Buckets {
        uint256[] ranges;
        uint256[] weights;
    }

    /// @dev The scores given to a service submission.
    struct Score {
        uint256 reviewSum;
        uint256 scaledAvg;
        EnumerableSet.AddressSet enforcers;
    }

    /// @dev The relevant storage data for a request.
    struct Request {
        uint256 scaledAvgSum;
        mapping(uint256 => Score) scores;
        EnumerableSet.AddressSet qualifiedProviders;
    }

    function enforce(
        uint256 _requestId,
        uint256 _submissionId,
        uint256 _score,
        address _enforcer
    ) external returns (bool, uint24);

    function rewards(
        uint256 _requestId,
        uint256 _submissionId,
        uint256 _pTokenQ
    ) external returns (uint256 amount, bool requiresSubmission);

    function remainder(uint256 _requestId, uint256 _pTokenQ) external returns (uint256);
}
