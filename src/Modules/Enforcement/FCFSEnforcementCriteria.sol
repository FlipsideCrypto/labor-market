// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract FCFSEnforcementCriteria {
    /// @dev First come first servce on linear decreasing payout curve
    /// @dev First 100 submissions that are marked as good get paid

    mapping(address => mapping(uint256 => uint256)) public submissionToIndex;

    uint256 public constant MAX_SCORE = 100;
    uint256 public payCount;

    /**
     * @notice Allows maintainer to review with either 0 (bad) or 1 (good)
     * @param submissionId The submission to review
     * @param score The score to give the submission
     */
    function review(uint256 submissionId, uint256 score)
        external
        returns (uint256)
    {
        require(score <= 1, "EnforcementCriteria::review: invalid score");
        require(payCount < 100, "EnforcementCriteria::review: no more payouts");

        if (score == 1) {
            submissionToIndex[msg.sender][submissionId] = payCount;

            unchecked {
                payCount++;
            }
        }

        return score;
    }

    function verify(uint256 submissionId) external view returns (uint256) {
        return submissionToIndex[msg.sender][submissionId];
    }
}
