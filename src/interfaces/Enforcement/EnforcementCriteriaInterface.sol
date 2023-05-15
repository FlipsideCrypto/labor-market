// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface EnforcementCriteriaInterface {
    /// @notice Announces the definition of the criteria configuration.
    event EnforcementConfigured(address indexed _market, uint256[] _auxiliaries, uint256[] _alphas, uint256[] _betas);

    /// @notice Announces change in Submission reviews.
    event SubmissionReviewed(
        address indexed _market,
        uint256 indexed _requestId,
        uint256 indexed _submissionId,
        uint256 intentChange,
        uint256 earnings,
        uint256 remainder,
        bool newSubmission
    );

    /**
     * @notice Set the configuration for a Labor Market using the generalized parameters.
     * @param _auxiliaries The auxiliary parameters for the Labor Market.
     * @param _alphas The alpha parameters for the Labor Market.
     * @param _betas The beta parameters for the Labor Market.
     */
    function setConfiguration(
        uint256[] calldata _auxiliaries,
        uint256[] calldata _alphas,
        uint256[] calldata _betas
    ) external;

    /**
     * @notice Submit a new score for a submission.
     * @param _requestId The ID of the request.
     * @param _submissionId The ID of the submission.
     * @param _score The score of the submission.
     * @param _availableShare The amount of the $pToken available for this submission.
     * @param _enforcer The individual submitting the score.
     */
    function enforce(
        uint256 _requestId,
        uint256 _submissionId,
        uint256 _score,
        uint256 _availableShare,
        address _enforcer
    ) external returns (bool, uint24);

    /**
     * @notice Retrieve and distribute the rewards for a submission.
     * @param _requestId The ID of the request.
     * @param _submissionId The ID of the submission.
     * @return amount The amount of $pToken to be distributed.
     * @return requiresSubmission Whether or not the submission requires a new score.
     */
    function rewards(uint256 _requestId, uint256 _submissionId)
        external
        returns (uint256 amount, bool requiresSubmission);

    /**
     * @notice Retrieve the amount of $pToken owed back to the Requester.
     * @param _requestId The ID of the request.
     * @return amount The amount of $pToken owed back to the Requester.
     */
    function remainder(uint256 _requestId) external returns (uint256 amount);
}
