// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { EnforcementCriteriaInterface } from '../interfaces/enforcement/EnforcementCriteriaInterface.sol';

/// @dev Helper libraries.
import { EnumerableSet } from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import 'hardhat/console.sol';

contract ScalableLikertEnforcement is EnforcementCriteriaInterface {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev The definition how the scoring rubric is applied to a submission.
    struct Buckets {
        uint256 maxScore;
        uint256[] ranges;
        uint256[] weights;
    }

    /// @dev The scores given to a service submission.
    struct Score {
        uint256 reviewSum;
        uint256 earnings;
        uint256 remainder;
        EnumerableSet.AddressSet enforcers;
    }

    /// @dev The relevant storage data for a request.
    struct Request {
        uint256 scaledAvgSum;
        uint256 remainder;
        mapping(uint256 => Score) scores;
    }

    /// @dev The number of decimals to use for the average score.
    uint256 public constant MATH_AVG_DECIMALS = 1e8;

    /// @notice The maximum score that can be provided relative to a market.
    mapping(address => uint256) public marketToMaxScore;

    /// @dev Tracks the bucket criteria for a labor market.
    mapping(address => Buckets) internal marketToBuckets;

    /// @dev Tracks the cumulative sum of average score.
    mapping(address => mapping(uint256 => Request)) internal marketToRequestIdToRequest;

    /**
     * See {EnforcementCriteriaInterface.setConfiguration}
     */
    function setConfiguration(
        uint256[] calldata _auxilaries,
        uint256[] calldata _ranges,
        uint256[] calldata _weights
    ) public virtual {
        /// @notice Pull the bucket criteria for the respective Labor Market.
        Buckets storage buckets = marketToBuckets[msg.sender];

        /// @dev Criteria can only be set once.
        require(buckets.maxScore == 0, 'ScalableLikertEnforcement::setBuckets: Criteria already in use');

        /// @notice Ensure a value for max score has been provided.
        require(_auxilaries[0] != 0, 'ScalableLikertEnforcement::setBuckets: Max score not set');

        /// @dev The ranges and weights must be the same length.
        require(_ranges.length == _weights.length, 'ScalableLikertEnforcement::setBuckets: Invalid input');

        /// @dev The ranges must be in ascending order.
        for (uint256 i; i < _ranges.length - 1; i++) {
            /// @dev Confirm the ranges are sequential.
            require(_ranges[i] < _ranges[i + 1], 'ScalableLikertEnforcement::setBuckets: Buckets not sequential');
        }

        /// @dev Set the criteria.
        buckets.maxScore = _auxilaries[0];
        buckets.ranges = _ranges;
        buckets.weights = _weights;

        /// @dev Announce the configuration to enable complex analytics.
        emit EnforcementConfigured(msg.sender, _auxilaries, _ranges, _weights);
    }

    /**
     * See {EnforcementCriteriaInterface.enforce}
     */
    function enforce(
        uint256 _requestId,
        uint256 _submissionId,
        uint256 _score,
        uint256 _availableShare,
        address _enforcer
    ) public virtual returns (bool, uint24) {
        /// @notice Pull the score data for the respective Submission.
        Score storage score = marketToRequestIdToRequest[msg.sender][_requestId].scores[_submissionId];

        /// @notice Confirm that a score for this submission and enforcer is not already submitted.
        require(
            !score.enforcers.contains(_enforcer),
            'ScalableLikertEnforcement::review: Enforcer already submit a review'
        );

        /// @dev Retrieve the buckets state from the storage slot.
        Buckets storage buckets = marketToBuckets[msg.sender];

        /// @notice Confirm the score stays within bounds of defintion.
        require(_score <= buckets.maxScore, 'ScalableLikertEnforcement::review: Invalid score');

        /// @notice Add the enforcer to the list of enforcers to prevent double-reviewing.
        score.enforcers.add(_enforcer);

        /// @notice Pull the enforcement data for the respective Request.
        Request storage request = marketToRequestIdToRequest[msg.sender][_requestId];

        /// @notice Add the score to the cumulative total.
        score.reviewSum += _score;

        /// @notice Remove the scaled average from the cumulative total to prevent double-count.
        /// @dev This removes the previously set remainder for this submission because the value is
        ///      about to change and we want to update the value on request 1:1.
        request.remainder -= score.remainder;

        /// @notice Determine the average score for the submission.
        /// @dev This is padded with decimals to increase the level of precision when applying buckets.
        uint256 avgWithDecimals = (MATH_AVG_DECIMALS * score.reviewSum) / score.enforcers.length();

        /// @notice Determine the bucket weight for the average score.
        uint256 bucketWeight = _getScoreToBucket(buckets, avgWithDecimals);

        /// @notice Scale the average by the corresponsing bucket weight for the score.
        uint256 scaledAvg = ((avgWithDecimals * bucketWeight) / MATH_AVG_DECIMALS);

        /// @notice Calculate the amount owed to the Provider for their contribution.
        score.earnings = (scaledAvg * _availableShare) / buckets.maxScore / bucketWeight;

        /// @dev Determine the amount of funding should be refunded to the Requester
        score.remainder = _availableShare - score.earnings;

        /// @notice Keep a global tracker of the total remainder available to enable Requester reclaims.
        request.remainder += score.remainder;

        console.log('score.earnings: %s', score.earnings);
        console.log('score.remainder: %s', score.remainder);

        /// @notice Announce the update in the reviewing status of the submission.
        emit SubmissionReviewed(msg.sender, _requestId, _submissionId, 1, score.earnings, score.remainder, true);

        /// @notice Return the intent change.
        /// @dev `newSubmission` is always `true` because editing a submission is forbidden in this module.
        return (true, 1);
    }

    /**
     * See {EnforcementCriteriaInterface.rewards}
     */
    function rewards(uint256 _requestId, uint256 _submissionId)
        public
        virtual
        returns (uint256 amount, bool requiresSubmission)
    {
        amount = _rewards(msg.sender, _requestId, _submissionId);

        /// @notice Delete their earnings that has been saved.
        /// @dev This prevents re-entrancy in this specific module.
        delete marketToRequestIdToRequest[msg.sender][_requestId].scores[_submissionId].earnings;

        /// @notice In this version of the module `requiresSubmission` remains a
        ///         helpful as it serves as a "re-entrancy guard" due to earnings
        ///         being final upon claim.
        return (amount, true);
    }

    /**
     * See {EnforcementCriteriaInterface.remainder}
     */
    function remainder(uint256 _requestId) public virtual returns (uint256 amount) {
        amount = _remainder(msg.sender, _requestId);

        /// @notice Delete their earnings that has been saved.
        /// @dev This prevents re-entrancy in this specific module.
        delete marketToRequestIdToRequest[msg.sender][_requestId].remainder;
    }

    function getRewards(
        address _market,
        uint256 _requestId,
        uint256 _submissionId
    ) public virtual returns (uint256) {
        return _rewards(_market, _requestId, _submissionId);
    }

    function getRemainder(address _market, uint256 _requestId) public virtual returns (uint256) {
        return _remainder(_market, _requestId);
    }

    /**
     * @notice Get the rewards for a given market and submission.
     * @param _market The address of the Labor Market to check the Request of.
     * @param _requestId The id of the request the submission is related to.
     * @param _submissionId The id of the Provider submission.
     * @return amount The earnings available owed to the Provider.
     */
    function _rewards(
        address _market,
        uint256 _requestId,
        uint256 _submissionId
    ) internal view returns (uint256 amount) {
        /// @notice Retrieve the request data out of the storage slot.
        Request storage request = marketToRequestIdToRequest[_market][_requestId];

        /// @dev Determine how much the submission has earned.
        amount = request.scores[_submissionId].earnings;
    }

    /**
     * @notice Get the remainder for a given Market and Request.
     * @param _market The address of the Labor Market to check the Request of.
     * @param _requestId The id to check the remainder of.
     * @param amount The surprlus of funding remaining after currently calculated Provider distributions.
     */
    function _remainder(address _market, uint256 _requestId) internal view returns (uint256 amount) {
        /// @notice Retrieve the request data out of the storage slot.
        Request storage request = marketToRequestIdToRequest[_market][_requestId];

        /// @notice Determine how much the submission has earned.
        amount = request.remainder;
    }

    /**
     * @notice Determines where a score falls in the buckets and returns the weight.
     * @param _buckets The distribution buckets applied to the score.
     * @param _score The score to get the weight for.
     */
    function _getScoreToBucket(Buckets memory _buckets, uint256 _score) internal pure returns (uint256) {
        /// @dev Loop through the buckets from the end and return the first weight that the range is less than the score.
        uint256 i = _buckets.ranges.length;

        /// @dev If the buckets are not configured, utilize a scalable likert scale.
        if (i == 0) return 1;

        /// @notice Loop down through the bucket to find the one it belongs to.
        /// @dev Elementary loop employed due to the non-standard spacing of bucket ranges.
        for (i; i > 0; i--) {
            if (_score > _buckets.ranges[i - 1]) return _buckets.weights[i - 1];
        }

        /// @dev If the score is less than the first bucket, return the first weight.
        return _buckets.weights[0];
    }
}
