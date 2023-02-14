// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {EnforcementCriteriaInterface} from "src/Modules/Enforcement/interfaces/EnforcementCriteriaInterface.sol";


/**
 * @title A contract that enforces a constant likert scale.
 * @notice This contract takes in reviews on a 5 point Likert scale of SPAM, BAD, OK, GOOD, GREAT.
 *         Upon a review, the average score is calculated and the cumulative score is updated.
 *         Once it is time to claim, the ratio of a submission's average score to the cumulative
 *         score is calculated. This ratio represents the % of the total reward pool that a submission
 *         has earned. The earnings are linearly distributed to the submission's based on their average score.
 *         If two total submissions have an average score of 4 and 2, the first submission will earn 2/3 of 
 *         the total reward pool and the second submission will earn 1/3. Thus, rewards are linear.
 */


contract ConstantLikertEnforcement is EnforcementCriteriaInterface {
    /// @dev Tracks the scores given to service submissions.
    /// @dev Labor Market -> Submission Id -> Scores
    mapping(address => mapping(uint256 => Scores)) public submissionToScores;

    /// @dev Tracks the cumulative sum of average score.
    /// @dev Labor Market -> Request Id -> Total score
    mapping(address => mapping(uint256 => uint256)) public requestTotalScore;

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

    /// @notice Allows a maintainer to review a submission.
    /// @param _submissionId The submission to review.
    /// @param _score The score to give the submission.
    /// @return The average score of the submission.
    function review(
          uint256 _submissionId
        , uint256 _score
    )
        external
        override
        returns (
            uint256
        )
    {
        require(
            _score <= uint256(Likert.GREAT),
            "ConstantLikertEnforcement::review: Invalid score"
        );

        Scores storage score = submissionToScores[msg.sender][_submissionId];

        // Utilize 4 decimals of precision.
        _score = _score * 2500;

        uint256 requestId = _getRequestId(_submissionId);

        // Update the cumulative total earned score.
        unchecked {
            requestTotalScore[msg.sender][requestId] -= score.avg;
        }

        score.scores.push(_score);
        score.avg = _getAvg(
            score.scores
        );

        // Update the cumulative total earned score with the submission's new average.
        unchecked {
            requestTotalScore[msg.sender][requestId] += score.avg;
        }

        return _score;
    }

    /*////////////////////////////////////////////////// 
                        GETTERS
    //////////////////////////////////////////////////*/

    function getRewards(
          address _laborMarket
        , uint256 _submissionId
        , bytes calldata
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

    function getPaymentReward(
          address _laborMarket
        , uint256 _submissionId
        , bytes calldata
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

    function getReputationReward(
          address _laborMarket
        , uint256 _submissionId
        , bytes calldata
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

    /// @notice Get the remaining unclaimed.
    /// @param _laborMarket The labor market the request is in.
    /// @param _requestId The request to get the remaining unclaimed for.
    /// @return unclaimed Total that can be reclaimed by the requester.
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

    /// @notice Returns the % of the total pool a submission has earned.
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

    /// @notice Gets the average of the scores given to a submission.
    /// @param _scores The scores given to a submission.
    /// @return The average of the scores.
    function _getAvg(
        uint256[] memory _scores
    )
        internal 
        pure 
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

    /// @notice Get the request id of a submission.
    /// @param _submissionId The submission id.
    /// @return The request id.
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