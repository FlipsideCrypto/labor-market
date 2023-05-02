// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface EnforcementCriteriaInterface {

    /**
     * @notice Allows a maintainer to review and updates the payout state.
     * @param _submissionId The submission to review.
     * @param _score The score to give the submission.
     */
    function review(
          uint256 _submissionId
        , uint256 _score
    )
        external;

    /**
     * @notice Calculates the amount of payment tokens a submission is entitled to.
     * @param _laborMarket The labor market the submission is in.
     * @param _submissionId The submission to calculate the payment reward for.
     * @return The amount of payment tokens a submission is entitled to.
     */
    function getReward(
          address _laborMarket
        , uint256 _submissionId
    )
        external
        view
        returns (
            uint256
        );

    /** 
     *  @notice Get the remaining payment tokens not allocated.
     *  @param _laborMarket The labor market the request is in.
     *  @param _requestId The request to get the remaining unclaimed for.
     *  @return unclaimed Total that can be reclaimed by the requester.
     */
    function getRemainder(
          address _laborMarket
        , uint256 _requestId
    ) 
        external 
        view 
        returns (
            uint256
        );
}