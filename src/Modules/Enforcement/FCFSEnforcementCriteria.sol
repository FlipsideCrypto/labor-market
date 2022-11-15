// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";

contract FCFSEnforcementCriteria {
    /// @dev First come first servce on linear decreasing payout curve
    /// @dev First 100 submissions that are marked as good get paid

    mapping(address => mapping(uint256 => uint256)) public submissionToIndex;

    /// @dev Max number of submissions that can be paid out
    uint256 public constant MAX_SCORE = 10;

    /// @dev Tracks the number of submissions per requestId that have been paid out
    mapping(uint256 => uint256) public payCount;

    /**
     * @notice Allows maintainer to review with either 0 (bad) or 1 (good)
     * @param submissionId The submission to review
     * @param score The score to give the submission
     */
    function review(uint256 submissionId, uint256 score)
        external
        returns (uint256)
    {
        uint256 requestId = getRid(submissionId);

        require(score <= 1, "EnforcementCriteria::review: invalid score");

        if (score > 0 && payCount[requestId] < MAX_SCORE) {
            submissionToIndex[msg.sender][submissionId] = payCount[requestId];

            unchecked {
                payCount[requestId]++;
            }
        }

        return score;
    }

    function verify(uint256 submissionId) external view returns (uint256) {
        return submissionToIndex[msg.sender][submissionId];
    }

    /// @dev Gets a users requestId from submissionId
    function getRid(uint256 submissionId) internal view returns (uint256) {
        return
            LaborMarketInterface(msg.sender)
                .getSubmission(submissionId)
                .requestId;
    }
}
