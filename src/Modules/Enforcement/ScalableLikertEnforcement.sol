// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { EnforcementCriteriaInterface } from './interfaces/EnforcementCriteriaInterface.sol';

import { LaborMarketInterface } from '../../LaborMarket/interfaces/LaborMarketInterface.sol';
import { LaborMarket } from '../../LaborMarket/LaborMarket.sol';

import { Context } from '@openzeppelin/contracts/utils/Context.sol';

import { EnumerableSet } from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

contract ScalableLikertEnforcement is EnforcementCriteriaInterface, Context {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev The number of decimals to use for the average score.
    uint256 public constant MATH_AVG_DECIMALS = 1e8;

    /// @dev Tracks the bucket criteria for a labor market.
    mapping(address => Buckets) internal marketToBuckets;

    /// @dev Tracks the cumulative sum of average score.
    mapping(address => mapping(uint256 => Request)) internal marketToRequestIdToRequest;

    /// @dev Tracks the scores given to service submissions.
    /// @dev Labor Market -> Submission Id -> Scores
    // mapping(address => mapping(uint256 => mapping(uint256 => Score))) internal submissionToScore;

    /// @dev The Likert grading scale.
    enum Likert {
        SPAM,
        BAD,
        OK,
        GOOD,
        GREAT
    }

    /*////////////////////////////////////////////////// 
                        SETTERS
    //////////////////////////////////////////////////*/

    // TODO: To support: https://github.com/MetricsDAO/xyz/issues/620
    // TODO: The labor market should pass the maximum score when setting buckets
    // TODO: The labor market should pass the score scalar

    /**
     * See {EnforcementCriteriaInterface.review}
     */
    function enforce(
        uint256 _requestId,
        uint256 _submissionId,
        uint256 _score,
        address _enforcer
    ) public virtual returns (bool, uint24) {
        /// @notice Pull the score data for the respective Submission.
        /// @TODO: Would there be collision if there are two marketToRequestIdToRequest with the same submission id?
        Score storage score = marketToRequestIdToRequest[_msgSender()][_requestId].scores[_submissionId];

        /// @notice Confirm the score stays within bounds of defintion.
        require(_score <= uint256(Likert.GREAT), 'ScalableLikertEnforcement::review: Invalid score');

        /// @notice Confirm that a score for this submission and enforcer is not already submitted.
        require(
            !score.enforcers.contains(_enforcer),
            'ScalableLikertEnforcement::review: Enforcer already submit a review'
        );

        /// @notice Add the enforcer to the list of enforcers.
        score.enforcers.add(_enforcer);

        /// @notice Pull the enforcement data for the respective Request.
        Request storage request = marketToRequestIdToRequest[_msgSender()][_requestId];

        /// @notice Add the score to the cumulative total.
        // TODO: 25 is an arbitrary number due to the initial spec of Likert and a 100pt scale.
        /// because the max score is a 4? yes, it's an enum.
        score.reviewSum += _score * 25; /// @dev Scale the score to a 100pt scale.

        /// @notice Remove the scaled average from the cumulative total to prevent double-count.
        request.scaledAvgSum -= score.scaledAvg;

        /// @notice Determine the average score for the submission.
        uint256 avg = (MATH_AVG_DECIMALS * score.reviewSum) / score.enforcers.length();

        /// @notice Scale the average by the corresponsing bucket weight for the score.
        score.scaledAvg = (avg * _getScoreToBucket(avg)) / MATH_AVG_DECIMALS;

        /// @notice Add the scaled score to the cumulative total.
        request.scaledAvgSum += score.scaledAvg;

        /// @notice If the score for the submission meets the standard, qualify the Provider.
        if (score.scaledAvg > 0)
            /// @notice Add the Provider to the list of earning recipients.
            request.qualifiedProviders.add(address(uint160(_submissionId)));
            /// @notice Remove the Provider from the list of earning recipients.
        else request.qualifiedProviders.remove(address(uint160(_submissionId)));

        /// @notice Return the intent change.
        /// @dev `newSubmission` is always `true` because editing a submission is forbidden in this module.
        return (true, 1);
    }

    /**
     * @dev Sets the criteria for an Enforcement type.
     * @param _ranges The ranges for the criteria.
     * @param _weights The weights for the criteria.
     */
    function setBuckets(uint256[] calldata _ranges, uint256[] calldata _weights) public virtual {
        /// @dev The ranges and weights must be the same length.
        require(_ranges.length == _weights.length, 'ScalableLikertEnforcement::setBuckets: Invalid input');

        /// @notice Pull the bucket criteria for the respective Labor Market.
        Buckets storage buckets = marketToBuckets[_msgSender()];

        /// @dev Criteria can only be set once.
        require(buckets.ranges.length == 0, 'ScalableLikertEnforcement::setBuckets: Criteria already in use');

        /// @dev The ranges must be in ascending order.
        for (uint256 i; i < _ranges.length - 1; i++) {
            /// @dev Confirm the ranges are sequential.
            require(_ranges[i] < _ranges[i + 1], 'ScalableLikertEnforcement::setBuckets: Buckets not sequential');
        }

        /// @dev Set the criteria.
        buckets.ranges = _ranges;
        buckets.weights = _weights;
    }

    /*////////////////////////////////////////////////// 
                        GETTERS
    //////////////////////////////////////////////////*/

    /**
     * See {EnforcementCriteriaInterface.getPaymentReward}
     */
    function rewards(
        uint256 _requestId,
        uint256 _submissionId,
        uint256 _pTokenQ
    ) public virtual returns (uint256 amount, bool requiresSubmission) {
        Request storage request = marketToRequestIdToRequest[_msgSender()][_requestId];

        /// @dev Determine how much the submission has earned.
        amount = _calculateShare(
            request.scores[_submissionId].scaledAvg,
            marketToRequestIdToRequest[_msgSender()][_requestId].scaledAvgSum,
            _pTokenQ
        );

        /// @notice Delete their score that has been saved.
        /// @dev This prevents re-entrancy in this specific module.
        delete request.scores[_submissionId].scaledAvg;

        /// @dev In this version of the module `requiresSubmission` remains a
        ///      helpful as it serves as a "re-entrancy guard" due to earnings
        ///      being final upon claim.
        return (amount, true);
    }

    /**
     * See {EnforcementCriteriaInterface.getRemainder}
     */
    function remainder(uint256 _requestId, uint256 _pTokenQ) public virtual returns (uint256) {
        /// @dev If there are no qualifying submissions, return the total pool.
        if (marketToRequestIdToRequest[_msgSender()][_requestId].qualifiedProviders.length() == 0) {
            return _pTokenQ;
        }

        /// @dev No remainder, the pool is in play!
        return 0;
    }

    /**
     * @notice Determines where a score falls in the buckets and returns the weight.
     * @param _score The score to get the weight for.
     */
    function _getScoreToBucket(uint256 _score) internal view returns (uint256) {
        /// @dev Get the buckets.
        Buckets memory buckets = marketToBuckets[_msgSender()];

        /// @dev Loop through the buckets from the end and return the first weight that the range is less than the score.
        uint256 i = buckets.ranges.length;

        /// @dev If the buckets are not configured, utilize a scalable likert scale.
        if (i == 0) return 1;

        /// @notice Loop down through the bucket to find the one it belongs to.
        /// @dev Elementary loop employed due to the non-standard spacing of bucket ranges.
        for (i; i > 0; i--) {
            if (_score > buckets.ranges[i - 1]) return buckets.weights[i - 1];
        }

        /// @dev If the score is less than the first bucket, return the first weight.
        return buckets.weights[0];
    }

    /**
     * @notice Calculates the share of the total pool a user is entitled to.
     * @param _userScore The user's score.
     * @param _totalCumulativeScore The total cumulative score of all submissions.
     * @param _totalPool The total pool of tokens to distribute.
     */
    function _calculateShare(
        uint256 _userScore,
        uint256 _totalCumulativeScore,
        uint256 _totalPool
    ) internal pure returns (uint256 share) {
        /// TODO: Implement support for: https://github.com/MetricsDAO/xyz/issues/661

        /// @dev If there are no submissions, return 0.
        if (_totalCumulativeScore == 0) return 0;

        /// @dev Determine the share of earnings this score is entitled to.
        return (_userScore * _totalPool) / _totalCumulativeScore;
    }
}
