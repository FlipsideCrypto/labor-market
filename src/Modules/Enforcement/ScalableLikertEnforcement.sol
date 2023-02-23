// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {EnforcementCriteriaInterface} from "src/Modules/Enforcement/interfaces/EnforcementCriteriaInterface.sol";

/**
 * @title Scalable Likert Enforcement
 * @notice A contract that enforces a scalable likert scale.
 * @dev This contract takes in reviews on a 5 point Likert scale of SPAM, BAD, OK, GOOD, GREAT.
 *         Upon a review, the average score is calculated and the cumulative score is updated with
 *         the score multiplied by it's bucket multiplier.
 *         Once it is time to claim, the ratio of a submission's average scaled score to the cumulative
 *         score is calculated. This ratio represents the % of the total reward pool that a submission
 *         has earned. The earnings are distributed to the submission's based on their average score and
 *         where it falls on the bucket criteria.
 */


contract ScalableLikertEnforcement is EnforcementCriteriaInterface {
    /// @dev Tracks the scores given to service submissions.
    /// @dev Labor Market -> Submission Id -> Scores
    mapping(address => mapping(uint256 => Score)) public submissionToScore;

    /// @dev Tracks the cumulative sum of average score.
    /// @dev Labor Market -> Request Id -> Total score
    mapping(address => mapping(uint256 => Request)) public requests;

    /// @dev Tracks the bucket criteria for a labor market.
    /// @dev Labor Market -> Buckets
    mapping(bytes32 => Buckets) internal bucketCriteria;

    /// @dev The relevant scoring criteria for a request.
    struct Buckets {
        uint256[] ranges;
        uint256[] weights;
    }

    /// @dev The relevant storage data for a request.
    struct Request {
        uint256 scaledAvgSum;
        uint256 qualifyingCount;
    }

    /// @dev The scores given to a service submission.
    struct Score {
        uint256 reviewCount;
        uint256 reviewSum;
        uint256 avg;
        bool qualified;
    }

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

    /**
     * See {EnforcementCriteriaInterface.review}
     */
    function review(
          uint256 _submissionId
        , uint256 _score
    )
        external
        override
    {
        require(
            _score <= uint256(Likert.GREAT),
            "VariableLikertEnforcement::review: Invalid score"
        );

        uint256 requestId = _getRequestId(_submissionId);

        _review(
            msg.sender, 
            requestId, 
            _submissionId, 
            _score
        );
    }

    /**
     * @dev Sets the criteria for an Enforcement type.
     * @param _key The enforcement key.
     * @param _ranges The ranges for the criteria.
     * @param _weights The weights for the criteria.
     */
    function setBuckets(
          bytes32 _key
        , uint256[] calldata _ranges
        , uint256[] calldata _weights
    )
        external
    {
        /// @dev The ranges and weights must be the same length.
        require(
            _ranges.length == _weights.length,
            "ConstantLikertEnforcement::setBuckets: Invalid input"
        );
        
        Buckets storage buckets = bucketCriteria[_key];
        
        /// @dev Criteria can only be set once.
        require(
            buckets.ranges.length == 0, 
            "ConstantLikertEnforcement::setBuckets: Criteria already in use"
        );

        /// @dev Opting for cleaning user input, as this will not 
        ///      be the V2 version of range and weight storage.
        for (uint256 i = 0; i < _ranges.length - 1; i++) {
            /// @dev The ranges must be in ascending order.
            require(
                _ranges[i] < _ranges[i + 1],
                "ConstantLikertEnforcement::setBuckets: Buckets not sequential"
            );
        }

        /// @dev Set the criteria.
        buckets.ranges = _ranges;
        buckets.weights = _weights;
    }

    /*////////////////////////////////////////////////// 
                        GETTERS
    //////////////////////////////////////////////////*/

    
    /**
     * See {EnforcementCriteriaInterface.getRewards}
     */
    function getRewards(
          address _laborMarket
        , uint256 _submissionId
    )
        external
        override
        view
        returns (
            uint256,
            uint256
        )
    {
        uint256 requestId = _getRequestId(_submissionId);

        return (
            _calculateShare(
                submissionToScore[_laborMarket][_submissionId].avg, 
                requests[_laborMarket][requestId].scaledAvgSum, 
                LaborMarketInterface(_laborMarket).getRequest(requestId).pTokenQ
            ),
            _calculateShare(
                submissionToScore[_laborMarket][_submissionId].avg, 
                requests[_laborMarket][requestId].scaledAvgSum, 
                LaborMarketInterface(_laborMarket).getConfiguration().reputationParams.rewardPool
            )
        );
    }

    
    /**
     * See {EnforcementCriteriaInterface.getPaymentReward}
     */
    function getPaymentReward(
          address _laborMarket
        , uint256 _submissionId
    )
        external
        override
        view
        returns (
            uint256
        )
    {
        uint256 requestId = _getRequestId(_submissionId);

        return _calculateShare(
            submissionToScore[_laborMarket][_submissionId].avg, 
            requests[_laborMarket][requestId].scaledAvgSum, 
            LaborMarketInterface(_laborMarket).getRequest(requestId).pTokenQ
        );
    }

    /**
     * See {EnforcementCriteriaInterface.getReputationReward}
     */
    function getReputationReward(
          address _laborMarket
        , uint256 _submissionId
    )
        external
        override
        view
        returns (
            uint256
        )
    {
        uint256 requestId = _getRequestId(_submissionId);

        return _calculateShare(
            submissionToScore[_laborMarket][_submissionId].avg, 
            requests[_laborMarket][requestId].scaledAvgSum, 
            LaborMarketInterface(_laborMarket).getConfiguration().reputationParams.rewardPool
        );
    }

    /**
     * See {EnforcementCriteriaInterface.getRemainder}
     */
    function getRemainder(
          address _laborMarket
        , uint256 _requestId
    )
        external
        override
        view
        returns (
            uint256
        )
    {
        /// @dev Load the request.
        LaborMarketInterface.ServiceRequest memory request = LaborMarketInterface(
            _laborMarket
        ).getRequest(_requestId);

        /// @dev If the enforcement exp passed and the request total score is 0, return the total pool.
        if (
            block.timestamp > request.enforcementExp && 
            requests[_laborMarket][_requestId].qualifyingCount == 0
        ) return request.pTokenQ;

        return 0;
    }

    /**
     * See {EnforcementCriteriaInterface.review}
     */
    function _review(
          address _laborMarket
        , uint256 _requestId
        , uint256 _submissionId
        , uint256 _score
    )
        internal
    {
        /// @dev Load the submissions score state and the request data.
        Score storage score = submissionToScore[_laborMarket][_submissionId];
        Request storage request = requests[_laborMarket][_getRequestId(_submissionId)];

        /// @dev Set the score data and remove the scaled average from the cumulative total.
        unchecked {
            score.reviewCount++;
            score.reviewSum += _score * 25; /// @dev Scale the score to 100.
            request.scaledAvgSum -= score.avg;
        }

        /// @dev Get the scaled average.
        uint256 avg = score.reviewSum / score.reviewCount;
        score.avg = avg * _getBucketWeight(_laborMarket, avg);

        /// @dev Add the scaled score to the cumulative total.
        request.scaledAvgSum += score.avg;

        /// @dev Is there a better way to handle this?
        /// @dev If not qualified, increment the number of qualifying scores and mark score as qualified.
        if (score.avg > 0 && !score.qualified) {
            score.qualified = true;
            request.qualifyingCount++;
        }

        /// @dev If qualified, decrement number of scores and set score as qualified.
        if (score.avg == 0 && score.qualified) {
            score.qualified = false;
            request.qualifyingCount--;
        }
    }

    /**
     * @notice Determines where a score falls in the buckets and returns the weight.
     * @param _laborMarket The labor market the submission is in.
     * @param _score The score to get the weight for.
     */
    function _getBucketWeight(
        address _laborMarket,
        uint256 _score
    )
        internal
        view
        returns (
            uint256
        )
    {
        /// @dev Get the enforcement key.
        bytes32 key = LaborMarketInterface(_laborMarket).getConfiguration().modules.enforcementKey;

        /// @dev Get the buckets.
        Buckets memory buckets = bucketCriteria[key];

        /// @dev Loop through the buckets from the end and return the first weight that the range is less than the score.
        uint256 i = buckets.ranges.length;

        /// @dev If the buckets are not configured, utilize a scalable likert scale.
        if (i == 0) return 1;

        for (i; i > 0; i--) {
            if (_score > buckets.ranges[i - 1]) return buckets.weights[i - 1];
        }

        return buckets.weights[0];
    }

    /**
     * @notice Calculates the share of the total pool a user is entitled to.
     * @param _userScore The user's score.
     * @param _totalCumulativeScore The total cumulative score of all submissions.
     * @param _totalPool The total pool of tokens to distribute.
     */
    function _calculateShare(
          uint256 _userScore
        , uint256 _totalCumulativeScore
        , uint256 _totalPool
    )
        internal
        view
        returns (
            uint256
        )
    {
        return (
            _totalCumulativeScore > 0 ?
            _userScore * _totalPool / _totalCumulativeScore :
            0
        );
    }

    /**
     * @notice Gets the request id of a submission.
     * @param _submissionId The submission id.
     * @return The request id.
     */
    function _getRequestId(
        uint256 _submissionId
    )
        internal
        view
        returns (
            uint256
        )
    {
        return 
            LaborMarketInterface(msg.sender)
                .getSubmission(_submissionId)
                .requestId;
    }
}