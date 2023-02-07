// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {EnforcementCriteriaInterface} from "src/Modules/Enforcement/interfaces/EnforcementCriteriaInterface.sol";

import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";

/**
 * @dev A contract that enforces a constant likert scale.
 * @notice This contract takes in reviews on a 5 point Likert scale of SPAM, BAD, OK, GOOD, GREAT.
 *         Upon a review, the average score is calculated and the cumulative score is updated.
 *         Once it is time to claim, the ratio of a submission's average score to the cumulative
 *         score is calculated. This ratio represents the % of the total reward pool that a submission
 *         has earned. The earnings are linearly distributed to the submission's based on their average score.
 *         If two total submissions have an average score of 4 and 2, the first submission will earn 2/3 of 
 *         the total reward pool and the second submission will earn 1/3. Thus, rewards are linear.
 **/

import "hardhat/console.sol";

contract ConstantLikertEnforcement is EnforcementCriteriaInterface {
    /// @dev Tracks the scores given to service submissions.
    /// @dev Labor Market -> Submission Id -> Scores
    mapping(address => mapping(uint256 => Scores)) private submissionToScores;

    /// @dev Tracks the cumulative sum of average score.
    /// @dev Labor Market -> Request Id -> Total score
    /// @dev Note: stored with 18 decimals.
    mapping(address => mapping(uint256 => uint256)) private requestTotalScore;

    /// @dev The Likert grading scale.
    enum Likert {
        SPAM,
        BAD,
        OK,
        GOOD,
        GREAT
    }

    /// @dev The scores given to a service submission.
    /// @dev Note: uint256 stored with 18 decimals.
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

        uint256 requestId = _getRequestId(_submissionId);

        // Update the cumulative total earned score.
        unchecked {
            requestTotalScore[msg.sender][requestId] -= score.avg;
        }

        // Update the submission's scores
        score.scores.push(_score * 1e18);
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

    /// @notice Returns the % of the total pool a submission has earned.
    /// @param _submissionId The submission id.
    function getShareOfPool(
        uint256 _submissionId
    )
        external
        override
        view
        returns (
            uint256 share
        )
    {
        return _calculateShare(_submissionId);
    }

    /// @notice Returns the % of the total pool a submission has earned.
    /// @dev This function is not used in this contract.
    /// @param _submissionId The submission id.
    function getShareOfPoolWithData(
          uint256 _submissionId
        , bytes calldata
    )
        external
        override
        view
        returns (
            uint256 share
        )
    {
        return _calculateShare(_submissionId);
    }

    /// @notice Get the remaining unclaimed.
    /// @dev This function is not used in this contract.
    function getRemainder(
        uint256
    )
        external
        override
        pure
        returns (
            uint256
        )
    {
        return 0;
    }

    /*////////////////////////////////////////////////// 
                        INTERNAL
    //////////////////////////////////////////////////*/

    /// @notice Returns the % of the total pool a submission has earned.
    /// @param _submissionId The submission id.
    function _calculateShare(
        uint256 _submissionId
    )
        internal
        view
        returns (
            uint256
        )
    {
        uint256 score = submissionToScores[msg.sender][_submissionId].avg;

        uint256 requestId = _getRequestId(_submissionId);

        return (score * 1e10) / requestTotalScore[msg.sender][requestId];
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