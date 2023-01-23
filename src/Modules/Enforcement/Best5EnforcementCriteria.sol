// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {PayCurveInterface} from "../Payment/interfaces/PayCurveInterface.sol";

// TODO: Add multiple reviewers (get average)
// TODO: Find good averaging function
// TODO: Find good sorting function

contract Best5EnforcementCriteria {
    /// @notice Best 5 submissions on a curve get paid
    /// @notice Allow any number of submissions
    /// @notice Expects an N=100 curve with a frequency of x, where basepayout multiplier for winning submissions is set by the radius.

    /// @dev Submission format
    struct Submission {
        uint256 submissionId;
        uint256 score;
    }

    /// @dev Tracks all the submissions for a market to a requestId.
    mapping(address => mapping(uint256 => Submission[]))
        public marketSubmissions;

    /// @dev Tracks the winning submissions and their curve index
    mapping(uint256 => uint256) public submissionToIndex;

    /// @dev Tracks whether or not a submission has been paid out
    mapping(address => mapping(uint256 => bool)) public isSorted;

    /// @dev Max amount of winners
    uint256 private constant MAX_WINNERS = 5;

    /**
     * @notice Allows maintainer to review with either 0 (bad) or 1 (good)
     * @param submissionId The submission to review
     * @param score The score to give the submission
     */
    function review(uint256 submissionId, uint256 score)
        external
        returns (uint256)
    {
        require(score <= 100, "EnforcementCriteria::review: invalid score");

        Submission memory submission = Submission({
            submissionId: submissionId,
            score: score
        });

        marketSubmissions[msg.sender][getRid(submissionId)].push(submission);

        return score;
    }

    /**
     * @notice Sorts the submissions and returns the index of the submission
     * @param submissionId The submission to verify
     */
    function verify(uint256 submissionId) external returns (uint256) {
        uint256 requestId = getRid(submissionId);

        if (!isSorted[msg.sender][requestId]) {
            sort(requestId);
        }

        return submissionToIndex[submissionId];
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Sorts the submissions for a given requestId
    function sort(uint256 requestId) internal {
        for (
            uint256 i;
            i < marketSubmissions[msg.sender][requestId].length;
            ++i
        ) {
            for (
                uint256 j;
                j < marketSubmissions[msg.sender][requestId].length - 1;
                ++j
            ) {
                if (
                    marketSubmissions[msg.sender][requestId][j].score <
                    marketSubmissions[msg.sender][requestId][j + 1].score
                ) {
                    Submission memory temp = marketSubmissions[msg.sender][
                        requestId
                    ][j];
                    marketSubmissions[msg.sender][requestId][
                        j
                    ] = marketSubmissions[msg.sender][requestId][j + 1];
                    marketSubmissions[msg.sender][requestId][j + 1] = temp;
                }
            }
        }

        for (uint256 i = 1; i < 6; i++) {
            submissionToIndex[
                marketSubmissions[msg.sender][requestId][i].submissionId
            ] = i * 20;
        }

        isSorted[msg.sender][requestId] = true;
    }

    /// @dev Gets a users requestId from submissionId
    function getRid(uint256 submissionId) internal view returns (uint256) {
        return
            LaborMarketInterface(msg.sender)
                .getSubmission(submissionId)
                .requestId;
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the curve index for a given submission.
    function getIndex(uint256 submissionId) external view returns (uint256) {
        return submissionToIndex[submissionId];
    }

    /// @dev Returns the (sorted) submissions for a market
    function getSubmissions(address market, uint256 requestId)
        external
        view
        returns (Submission[] memory)
    {
        return marketSubmissions[market][requestId];
    }

    /// @dev Returns the remainder that is claimable by the requester of a requestId
    function getRemainder(uint256 requestId) public returns (uint256) {
        if (marketSubmissions[msg.sender][requestId].length >= MAX_WINNERS) {
            return 0;
        } else {
            uint256 claimable;

            LaborMarketInterface market = LaborMarketInterface(msg.sender);
            PayCurveInterface curve = PayCurveInterface(
                market.getConfiguration().modules.payment
            );
            uint256 submissions = marketSubmissions[msg.sender][requestId]
                .length;

            for (uint256 i; i < (MAX_WINNERS - submissions); i++) {
                uint256 index = ((submissions + i) + 1) * 20;
                claimable += curve.curvePoint(index);
            }
            return claimable;
        }
    }
}
