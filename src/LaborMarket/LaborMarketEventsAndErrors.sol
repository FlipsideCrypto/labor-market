// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract LaborMarketEventsAndErrors {
    /// @dev LaborMarket Events and Errors



    /// @notice thrown if a market is active
    error MarketActive();

    /// @notice thrown if anyone but the requester withdraws a request
    error NotTheRequester(address invalidRequester);

    /// @notice thrown if a request is already active
    error RequestActive(uint256 requestId);

    /// @notice thrown if a requestId does not exist
    error RequestDoesNotExist(uint256 requestId);

    /// @notice thrown if a user tries to signal twice
    error AlreadySignaled();

    /// @notice thrown if user tries to signal after deadline
    error SignalDeadlinePassed();

    /// @notice thrown if user tries to provide after deadline
    error SubmissionDeadlinePassed();

    /// @notice thrown if maintainer tries to review after deadline
    error EnforcementDeadlinePassed();

    /// @notice thrown if user does not meet requirements
    error NotQualified();

    /// @notice thrown if a user tries to provide without signaling
    error NotSignaled();

    /// @notice thrown if a submission does not exist
    error SubmissionDoesNotExist(uint256 submissionId);

    /// @notice thrown if a maintainer tries to review a submission twice
    error AlreadyReviewed();

    /// @notice thrown if a service submission has not been reviewed
    error NotReviewed();

    /// @notice thrown if a user tries to claim reward without being the submitter
    error NotServiceProvider();

    /// @notice thrown if a user tries to claim reward twice
    error AlreadyClaimed();

    /// @notice Thrown if a user tries to fulfill a request twice
    error AlreadySubmitted();

    /// @notice Thrown if a maintainer tries to review own submission
    error CannotReviewOwnSubmission();

    /// @notice Thrown if a user tries to claim while still in review
    error InReview();
}
