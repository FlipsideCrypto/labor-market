// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {EnforcementCriteriaInterface} from "src/Modules/Enforcement/interfaces/EnforcementCriteriaInterface.sol";


/**
 * @title A contract that enforces a scalable likert scale.
 * @notice This contract takes in reviews on a 5 point Likert scale of SPAM, BAD, OK, GOOD, GREAT.
 *         Upon a review, the average score is calculated and the cumulative score is updated with
 *         the score multiplied by it's bucket multiplier.
 *         Once it is time to claim, the ratio of a submission's average score to the cumulative
 *         score is calculated. This ratio represents the % of the total reward pool that a submission
 *         has earned. The earnings are linearly distributed to the submission's based on their average score.
 *         If two total submissions have an average score of 4 and 2, the first submission will earn 2/3 of 
 *         the total reward pool and the second submission will earn 1/3. Thus, rewards are linear.
 */


contract VariableLikertEnforcement is EnforcementCriteriaInterface {

    /// @dev Tracks the scores given to service submissions.
    /// @dev Labor Market -> Submission Id -> Scores
    mapping(address => mapping(uint256 => Scores)) public submissionToScores;

    /// @dev Tracks the cumulative sum of average score.
    /// @dev Labor Market -> Request Id -> Total score
    mapping(address => mapping(uint256 => uint256)) public requestTotalScore;

    /// @dev Tracks the bucket criteria for a labor market.
    /// @dev Labor Market -> Buckets
    mapping(bytes32 => Buckets) internal bucketCriteria;

    /// @dev The relevant scoring data for a request.
    struct Buckets {
        uint256[] ranges;
        uint256[] weights;
    }

    /// @dev The Likert grading scale.
    enum Likert {
        SPAM,
        BAD,
        OK,
        GOOD,
        GREAT
    }

    /// @dev The scores given to a service submission.
    struct Scores {
        uint256[] scores;
        uint256 avg;
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

        /// @dev Load the submissions score state.
        Scores storage score = submissionToScores[msg.sender][_submissionId];

        /// @dev Get the request id.
        uint256 requestId = _getRequestId(_submissionId);

        /// @dev Remove the current score from the cumulative total.
        unchecked {
            requestTotalScore[msg.sender][requestId] -= score.avg;
        }

        /// @dev Convert scores to a scale of 100.
        _score = _score * 25;

        /// @dev Store the score and update the average.
        score.scores.push(_score);
        score.avg = _getWeightedAverage(
            score.scores
        );

        /// @dev Update the cumulative total earned score with the submission's new average.
        unchecked {
            requestTotalScore[msg.sender][requestId] += score.avg;
        }
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
            "ConstantLikertEnforcement::setBuckets: Criteria already set"
        );

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
                submissionToScores[_laborMarket][_submissionId].avg, 
                requestTotalScore[_laborMarket][requestId], 
                LaborMarketInterface(_laborMarket).getRequest(requestId).pTokenQ
            ),
            _calculateShare(
                submissionToScores[_laborMarket][_submissionId].avg, 
                requestTotalScore[_laborMarket][requestId], 
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
            submissionToScores[_laborMarket][_submissionId].avg, 
            requestTotalScore[_laborMarket][requestId], 
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
            submissionToScores[_laborMarket][_submissionId].avg, 
            requestTotalScore[_laborMarket][requestId], 
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
        LaborMarketInterface.ServiceRequest memory request = LaborMarketInterface(_laborMarket).getRequest(_requestId);

        /// @dev If the enforcement exp passed and the request total score is 0, return the total pool.
        if (
            block.timestamp > request.enforcementExp && 
            requestTotalScore[_laborMarket][_requestId] == 0
        ) return request.pTokenQ;

        return 0;
    }

    /**
     * @notice Gets the scores given to a submission.
     * @param _laborMarket The labor market the submission is in.
     * @param _submissionId The submission to get the scores for.
     * @return The scores given to a submission.
     */
    function getScores(
          address _laborMarket
        , uint256 _submissionId
    )
        external
        view
        returns (
            uint256[] memory
        )
    {
        return submissionToScores[_laborMarket][_submissionId].scores;
    }

    /*////////////////////////////////////////////////// 
                        INTERNAL
    //////////////////////////////////////////////////*/

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
        return (_userScore * _totalPool) / _totalCumulativeScore;
    }


    function _getWeightedAverage(
        uint256[] memory _scores
    )
        internal
        view
        returns (
            uint256
        )
    {
        uint256 cumulativeScore;
        uint256 qScores = _scores.length;

        for (uint256 i; i < qScores; ++i) {
            cumulativeScore += _scores[i];
        }

        uint256 bucketMultiplier = _getBucketWeight(msg.sender, cumulativeScore / qScores);

        return cumulativeScore * bucketMultiplier / qScores;
    }

    /** 
     * @notice Gets the average of the scores given to a submission.
     * @param _scores The scores given to a submission.
     * @return The average of the scores.
     */ 
    function _getAvg(
        uint256[] memory _scores
    )
        internal 
        view 
        returns (
            uint256
        ) 
    {
        uint256 cumulativeScore;
        uint256 qScores = _scores.length;

        for (uint256 i; i < qScores; ++i) {
            cumulativeScore += _scores[i];
        }

        return cumulativeScore / qScores;
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