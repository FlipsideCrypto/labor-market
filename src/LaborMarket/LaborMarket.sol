// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarketManager } from './LaborMarketManager.sol';

contract LaborMarket is LaborMarketManager {
    /// @dev The service request id counter.
    uint256 public serviceId;

    modifier onlyMaintainer(address _user) {
        require(isMaintainer(_user), 'LaborMarket::isMaintainer: Not a maintainer');
        _;
    }

    modifier onlyDelegate(address _user) {
        require(isDelegate(_user), 'LaborMarket::isDelegate: Not a delegate');
        _;
    }

    modifier onlyPermittedParticipant(address _user) {
        require(isPermittedParticipant(_user), 'LaborMarket::isPermittedParticipant: Not a permitted participant');
        _;
    }

    /**
     * @notice Creates a service request.
     * @param _request The request being submit for a work request in the Labor Market.
     * @return The id of the service request.
     *
     * Requirements:
     * - Caller has to have approved the LaborMarket contract to transfer the payment token.
     * - Timestamps must be valid and chronological.
     */
    function submitRequest(ServiceRequest memory _request) public virtual onlyDelegate(_msgSender()) returns (uint256) {
        /// @notice Ensure the timestamps of the request phases are valid.
        require(
            block.timestamp < _request.signalExp &&
                _request.signalExp < _request.submissionExp &&
                _request.submissionExp < _request.enforcementExp,
            'LaborMarket::submitRequest: Invalid timestamps'
        );

        /// @notice Provide the funding for the request.
        _request.pToken.transferFrom(_msgSender(), address(this), _request.pTokenQ);

        /// @notice Manage the hard-coded values of the request.
        _request.serviceRequester = _msgSender();
        _request.submissionCount = 0;

        /// @notice Store the request in the Labor Market.
        serviceIdToRequest[serviceId] = _request;

        /// @notice Increment the ecosystem service id.
        ++serviceId;

        /// @notice Announce the creation of a new request in the Labor Market.
        emit RequestConfigured(
            _msgSender(),
            serviceId,
            _request.uri,
            _request.pToken,
            _request.pTokenQ,
            _request.signalExp,
            _request.submissionExp,
            _request.enforcementExp
        );

        /// @notice Return the id of the newly created request.
        return serviceId;
    }

    /**
     * @notice Signals interest in fulfilling a service request.
     * @param _requestId The id of the service request.
     *
     * Requirements:
     * - The signal deadline has not passed.
     * - The user has not already signaled.
     */
    function signal(uint256 _requestId) public virtual onlyPermittedParticipant(_msgSender()) {
        /// @notice Ensure the signal phase is still active.
        require(
            block.timestamp <= serviceIdToRequest[_requestId].signalExp,
            'LaborMarket::signal: Signal deadline passed'
        );

        /// @notice Require the user has not signaled.
        /// @dev Get the first bit of the user's signal value.
        require(
            requestIdToAddressToPerformanceState[_requestId][_msgSender()] & 0x3 == 0,
            'LaborMarket::signal: Already signaled'
        );

        /// @notice Increment the signal count.
        ++signalCount[_requestId];

        /// @notice Set the user's signal.
        requestIdToAddressToPerformanceState[_requestId][_msgSender()] |= 0x1;

        /// @notice Announce the signalling of a service provider.
        emit RequestSignal(_msgSender(), _requestId);
    }

    /**
     * @notice Signals interest in reviewing a submission.
     * @param _requestId The id of the request a maintainer would like to assist in reviewing.
     * @param _quantity The amount of submissions a reviewer has intent to manage.
     *
     * Requirements:
     * - Quantity has to be less than 8,388,608.
     */
    function signalReview(uint256 _requestId, uint24 _quantity) public virtual onlyMaintainer(_msgSender()) {
        /// @notice Get the intent of the maintainer.
        /// @dev Shift the performance value to the right by two bits and then mask down to
        ///      the next 22 bits with an overlap of 0x3fffff.
        uint24 reviewIntent = ((requestIdToAddressToPerformanceState[_requestId][_msgSender()] >> 2) & 0x3fffff);

        /// @notice Ensure that we are the intent will not overflow the 22 bits saved for the quantity.
        /// @dev Mask the `_quantity` down to 22 bits to prevent overflow and user error.
        require(reviewIntent + (_quantity & 0x3fffff) <= 4_194_304, 'LaborMarket::signalReview: Too many reviews');

        /// @notice Update the intent of reviewing by summing already signaled quantity with the new quantity
        ///         and then shift it to the left by two bits to make room for the intent of providing.
        requestIdToAddressToPerformanceState[_requestId][_msgSender()] |= (reviewIntent + _quantity) << 2;

        /// @notice Announce the signalling of a service reviewer.
        emit ReviewSignal(_msgSender(), _requestId, _quantity);
    }

    /**
     * @notice Allows a service provider to fulfill a service request.
     * @param _requestId The id of the service request being fulfilled.
     * @param _uri The uri of the service submission data.
     * @return submissionId The id of the service submission.
     *
     * Requirements:
     * - The provider has to have signaled.
     * - The submission deadline has not passed.
     * - The provider has not already submitted.
     */
    function provide(uint256 _requestId, string calldata _uri) external returns (uint256) {
        /// @dev Get the request out of storage to warm the slot.
        ServiceRequest storage request = serviceIdToRequest[_requestId];

        /// @notice Require the submission phase is still active.
        require(block.timestamp <= request.submissionExp, 'LaborMarket::provide: Submission deadline passed');

        /// @notice Ensure that the provider has signaled, but has not already submitted.
        /// @dev Get the first two bits of the user's performance value.
        ///      0: Not signaled, 1: Signaled, 2: Submitted.
        require(
            requestIdToAddressToPerformanceState[_requestId][_msgSender()] & 0x3 == 1,
            'LaborMarket::provide: Not signaled'
        );

        /// @dev Increment the submission count and service ID.
        /// TODO: FIX THIS WHEN I FIGURE OUT WHAT THEY ARE USED FOR
        /// TODO: THIS SECTION IS SO CURSED -- THERE MAY OR MAY NOT BE A REASON FROM BRYAN?
        ++serviceId;
        ++serviceIdToRequest[_requestId].submissionCount;

        /// @dev Set the submission.
        /// TODO: FIX THIS ONCE THE ABOVE COUNTERS HAVE BEEN REMOVED
        serviceIdToSubmission[serviceId] = ServiceSubmission({ serviceProvider: _msgSender(), requestId: _requestId });

        /// @dev Provider has submitted.
        requestIdToAddressToPerformanceState[_requestId][_msgSender()] |= 0x2;

        /// @notice Announce the submission of a service provider.
        emit RequestFulfilled(_msgSender(), _requestId, serviceId, _uri);

        /// @notice Return the id of the newly created submission.
        return serviceId;
    }

    /**
     * @notice Allows a maintainer to review a service submission.
     * @param _requestId The id of the service request being fulfilled.
     * @param _submissionId The id of the service providers submission.
     * @param _score The score of the service submission.
     *
     * Requirements:
     * - The enforcement deadline has not passed.
     * - The maintainer has signaled.
     * - The maintainer has not already reviewed this submission.
     * - The maintainer is not the submission provider.
     */
    function review(
        uint256 _requestId,
        uint256 _submissionId,
        uint256 _score
    ) public virtual {
        /// @notice Ensure that no one is grading their own submission.
        require(
            serviceIdToSubmission[_submissionId].serviceProvider != _msgSender(),
            'LaborMarket::review: Cannot review own submission'
        );

        /// @notice Ensure the request is still in the enforcement phase.
        require(
            block.timestamp <= serviceIdToRequest[_requestId].enforcementExp,
            'LaborMarket::review: Enforcement deadline passed'
        );

        uint24 intent = requestIdToAddressToPerformanceState[_requestId][_msgSender()];

        /// @notice Get the remaining signal value of the maintainer.
        /// @dev Uses the last 22 bits of the performance value by shifting over 2 values and then
        ///      masking down to the last 22 bits with an overlap of 0x3fffff.
        uint24 remainingIntent = (requestIdToAddressToPerformanceState[_requestId][_msgSender()] >> 2) & 0x3fffff;

        /// @notice Ensure the maintainer is not exceeding their signaled intent.
        require(remainingIntent > 0, 'LaborMarket::review: Not signaled');

        /// @dev Require the maintainer has not reviewed this submission.
        // TODO: This should be stored in the enforcement criteria as not all enforcement criterias
        //       may apply the same rules as well as by moving ENFORCEMENT LOGIC into the enforcement module,
        //       new modules can actually be deployed without needing a whole new protocol version.
        // require(
        //     !hasPerformed[_submissionId][_msgSender()][HAS_REVIEWED],
        //     "LaborMarket::review: Already reviewed"
        // );

        /// @notice Lower the bitpacked value representing the remaining signal value of
        ///         the caller for this request.
        /// @dev This bitwise shifts shifts 22 bits to the left to clear the previous value
        ///      and then bitwise ORs the remaining signal value minus 1 to the left by 2 bits.
        requestIdToAddressToPerformanceState[_requestId][_msgSender()] =
            (intent & 0xff000003) |
            ((remainingIntent - 1) << 2);

        /// @dev Maintainer has reviewed this submission.
        /// TODO: Move this into enforcement criteria and delete once it is handled.
        // hasPerformed[_submissionId][_msgSender()][HAS_REVIEWED] = true;

        /// @notice Make the external call into the enforcement module to submit the callers score.
        /// TODO: The nomenclature of this should have been `criteria.enforce(submission, score)`
        enforcementCriteria.review(_submissionId, _score);

        /// @notice Announce the new submission of a score by a maintainer.
        emit RequestReviewed(_msgSender(), _requestId, _submissionId, _score);
    }

    /**
     * @notice Allows a service provider to claim payment for a service submission.
     * @param _requestId The id of the service request being fulfilled.
     * @param _submissionId The id of the service providers submission.
     * @param _to The address to send the payment to.
     * @return pTokenClaimed The amount of pTokens claimed.
     * @return rTokenClaimed The amount of rTokens claimed.
     *
     * Requirements:
     * - The submission has not already been claimed.
     * - The provider is the sender.
     * - The enforcement deadline has passed.
     */
    function claim(
        uint256 _requestId,
        uint256 _submissionId,
        address _to
    ) external returns (uint256 rewards) {
        /// @dev Get the request out of storage to warm the slot.
        ServiceRequest storage request = serviceIdToRequest[_requestId];

        /// @dev Require the submission has not been claimed.
        /// TODO: This needs to be enforced by the enforcement criteria.
        // require(
        //     !hasPerformed[_submissionId][_msgSender()][HAS_CLAIMED],
        //     // requestIdToAddressToPerformanceState[_submissionId][_msgSender()], // ??
        //     "LaborMarket::claim: Already claimed"
        // );

        /// @dev Ensure the request is no longer in the enforcement phase.
        require(block.timestamp >= request.enforcementExp, 'LaborMarket::claim: Enforcement deadline not passed');

        /// @dev Provider has claimed this submission.
        /// TODO: Handle the nullification of rewards upon a claim.
        // hasPerformed[_submissionId][_msgSender()][HAS_CLAIMED] = true;

        /// @dev Get the rewards.
        rewards = enforcementCriteria.getRewards(address(this), _submissionId);

        /// @dev Ensure there are rewards to be distributed to the participant.
        require(rewards > 0, 'LaborMarket::claim: No rewards');

        /// @dev Transfer the pTokens.
        request.pToken.transfer(_to, rewards);

        /// @notice Announce the claiming of a service provider reward.
        emit RequestPayClaimed(_msgSender(), _requestId, _submissionId, rewards, _to);
    }

    /**
     * @notice Allows a service requester to claim the remainder of funds not allocated to service providers.
     * @param _requestId The id of the service request.
     *
     * Requirements:
     * - The requester is the sender.
     * - The enforcement deadline has passed.
     * - The requester has not claimed the remainder.
     */
    function claimRemainder(uint256 _requestId) external {
        /// @dev Require the requester is the sender.
        require(
            serviceIdToRequest[_requestId].serviceRequester == _msgSender(),
            'LaborMarket::claimRemainder: Not requester'
        );

        /// @dev Require the enforcement deadline has passed.
        require(
            block.timestamp >= serviceIdToRequest[_requestId].enforcementExp,
            'LaborMarket::claimRemainder: Not enforcement deadline'
        );

        /// @dev Require the requester has not claimed the remainder.
        require(
            !hasPerformed[_requestId][_msgSender()][HAS_CLAIMED_REMAINDER],
            'LaborMarket::claimRemainder: Already claimed'
        );

        /// @dev Get the remainder.
        uint256 totalClaimable = enforcementCriteria.getRemainder(address(this), _requestId);

        /// @dev Requester has claimed the remainder.
        hasPerformed[_requestId][_msgSender()][HAS_CLAIMED_REMAINDER] = true;

        /// @dev Transfer the remainder.
        serviceIdToRequest[_requestId].pToken.transfer(_msgSender(), totalClaimable);

        /// @dev Announce the claiming of the remainder.
        emit RemainderClaimed(_msgSender(), _requestId, totalClaimable);
    }

    /**
     * @notice Allows a service requester to withdraw a request and refund the pToken.
     * @param _requestId The id of the service requesters request.
     *
     * Requirements:
     * - The request must not have been signaled.
     * - The request creator is the sender.
     */
    function withdrawRequest(uint256 _requestId) external {
        ServiceRequest storage request = serviceIdToRequest[_requestId];

        /// @dev Ensure that only the Requester may withdraw the request.
        require(request.serviceRequester == _msgSender(), 'LaborMarket::withdrawRequest: Not requester');

        /// @dev Require the request has not been signaled.
        // TODO: Would be nice to add a dynamic back off mechanism that lets people set their own risk tolerance
        ///      since this now has more of an impact with the removal of signal collateral. Will have to model and get approved.
        require(signalCount[_requestId] < 1, 'LaborMarket::withdrawRequest: Already active');

        /// @notice Delete the request and prevent further action.
        delete serviceIdToRequest[_requestId].serviceRequester;
        delete serviceIdToRequest[_requestId].pToken;
        delete serviceIdToRequest[_requestId].pTokenQ;
        delete serviceIdToRequest[_requestId].signalExp;
        delete serviceIdToRequest[_requestId].submissionExp;
        delete serviceIdToRequest[_requestId].enforcementExp;
        delete serviceIdToRequest[_requestId].submissionCount;
        delete serviceIdToRequest[_requestId].uri;

        /// @dev Return the $pToken back to the Requester.
        request.pToken.transfer(_msgSender(), request.pTokenQ);

        /// @dev Announce the withdrawal of a request.
        emit RequestWithdrawn(_requestId);
    }

    /// @notice Gets the delegate eligibility of a caller.
    /// @param _account The account to check.
    /// @return Whether the account is a delegate.
    function isDelegate(address _account) public view returns (bool) {
        // TODO: NBADGE or delete
        return true;
        // return (
        //     address(delegateBadge) == address(0) ||
        //     delegateBadge.balanceOf(_account, configuration.delegateBadge.tokenId) > 0
        // );
    }

    /// @notice Gets the maintainer eligibility of a caller.
    /// @param _account The account to check.
    /// @return Whether the account is a maintainer.
    function isMaintainer(address _account) public view returns (bool) {
        // TODO: NBADGE or delete
        return true;
        // return (
        //     address(maintainerBadge) == address(0) ||
        //     maintainerBadge.balanceOf(_account, configuration.maintainerBadge.tokenId) > 0
        // );
    }

    /// @notice Gets the eligibility of a caller to submit a service request.
    /// @param _account The account to check.
    /// @return Whether the account is eligible to submit a service request.
    /// TODO: Delete??
    function isPermittedParticipant(address _account) public view returns (bool) {
        return true;
    }
}
