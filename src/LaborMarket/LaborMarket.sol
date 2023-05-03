// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarketManager } from './LaborMarketManager.sol';

contract LaborMarket is LaborMarketManager {
    /**
     * @notice Creates a service request.
     * @param _request The request being submit for a work request in the Labor Market.
     * @return The id of the service request.
     *
     * Requirements:
     * - Caller has to have approved the LaborMarket contract to transfer the payment token.
     * - Timestamps must be valid and chronological.
     */
    function submitRequest(ServiceRequest calldata _request, string calldata _uri)
        public
        virtual
        returns (uint256 requestId)
    {
        /// @notice Ensure the timestamps of the request phases are valid.
        require(
            block.timestamp < _request.signalExp &&
                _request.signalExp < _request.submissionExp &&
                _request.submissionExp < _request.enforcementExp,
            'LaborMarket::submitRequest: Invalid timestamps'
        );

        /// @dev Generate the uuid for the request using the timestamp and address.
        requestId = uint256(keccak256(abi.encodePacked(uint96(block.timestamp), _msgSender())));

        /// @notice Store the request in the Labor Market.
        serviceIdToRequest[requestId] = _request;

        /// @notice Announce the creation of a new request in the Labor Market.
        emit RequestConfigured(
            _msgSender(),
            uuid,
            _request.signalExp,
            _request.submissionExp,
            _request.enforcementExp,
            _request.pTokenQ,
            _request.pToken,
            _uri
        );

        /// @notice Provide the funding for the request.
        /// @dev This call is made after the request is stored to prevent re-entrancy.
        _request.pToken.transferFrom(_msgSender(), address(this), _request.pTokenQ);
    }

    /**
     * @notice Signals interest in fulfilling a service request.
     * @param _requestId The id of the service request.
     *
     * Requirements:
     * - The signal deadline has not passed.
     * - The user has not already signaled.
     */
    function signal(uint256 _requestId) public virtual {
        /// @notice Ensure the signal phase is still active.
        require(
            block.timestamp <= serviceIdToRequest[_requestId].signalExp,
            'LaborMarket::signal: Signal deadline passed'
        );

        /// @notice Get the performance state of the user.
        uint24 performance = requestIdToAddressToPerformance[_requestId][_msgSender()];

        /// @notice Require the user has not signaled.
        /// @dev Get the first bit of the user's signal value.
        require(performance & 0x3 == 0, 'LaborMarket::signal: Already signaled');

        /// @notice Increment the number of providers that have signaled.
        ++signalCount[_requestId].providers;

        // TODO: Add check that signal does not exceed max providers:
        // require(
        //     signalCount[_requestId].providers <= request.maxProviders,
        //     'LaborMarket::signal: Exceeds signal capacity'
        // );

        /// @notice Set the first two bits of the performance state to 1 to indicate the user has signaled
        ///         without affecting the rest of the performance state.
        requestIdToAddressToPerformance[_requestId][_msgSender()] =
            /// @dev Keep the last 22 bits but clear the first two bits.
            (performance & 0xFFFFFC) |
            /// @dev Set the first two bits of the performance state to 1 to indicate the user has signaled.
            0x1;

        /// @notice Announce the signalling of a service provider.
        emit RequestSignal(_msgSender(), _requestId);
    }

    /**
     * @notice Signals interest in reviewing a submission.
     * @param _requestId The id of the request a maintainer would like to assist in reviewing.
     * @param _quantity The amount of submissions a reviewer has intent to manage.
     *
     * Requirements:
     * - Quantity has to be less than 4,194,304.
     */
    function signalReview(uint256 _requestId, uint24 _quantity) public virtual {
        /// @notice Ensure the signal phase is still active.
        require(
            block.timestamp <= serviceIdToRequest[_requestId].signalExp,
            'LaborMarket::signalReview: Signal deadline passed'
        );

        /// @notice Get the performance state of the user.
        uint24 performance = requestIdToAddressToPerformance[_requestId][_msgSender()];

        /// @notice Get the intent of the maintainer.
        /// @dev Shift the performance value to the right by two bits and then mask down to
        ///      the next 22 bits with an overlap of 0x3fffff.
        uint24 reviewIntent = ((performance >> 2) & 0x3fffff);

        /// @notice Ensure that we are the intent will not overflow the 22 bits saved for the quantity.
        /// @dev Mask the `_quantity` down to 22 bits to prevent overflow and user error.
        /// TODO: We may want to lower this.
        require(
            reviewIntent + (_quantity & 0x3fffff) <= 4_194_304,
            'LaborMarket::signalReview: Exceeds signal capacity'
        );

        /// @notice Increment the number of reviewers that have signaled.
        signalCount[_requestId].reviewers += _quantity;

        // TODO: Add check that signal does not exceed max review: https://github.com/MetricsDAO/xyz/issues/633

        /// @notice Update the intent of reviewing by summing already signaled quantity with the new quantity
        ///         and then shift it to the left by two bits to make room for the intent of providing.
        requestIdToAddressToPerformance[_requestId][_msgSender()] =
            /// @dev Set the last 22 bits of the performance state to the sum of the current intent and the new quantity.
            ((reviewIntent + _quantity) << 2) |
            /// @dev Keep the first two bits of the performance state the same.
            (performance & 0x3);

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
    function provide(uint256 _requestId, string calldata _uri) external returns (uint256 participationId) {
        /// @dev Get the request out of storage to warm the slot.
        ServiceRequest storage request = serviceIdToRequest[_requestId];

        /// @notice Require the submission phase is still active.
        require(block.timestamp <= request.submissionExp, 'LaborMarket::provide: Submission deadline passed');

        /// @notice Get the performance state of the user.
        uint24 performance = requestIdToAddressToPerformance[_requestId][_msgSender()];

        /// @notice Ensure that the provider has signaled, but has not already submitted.
        /// @dev Get the first two bits of the user's performance value.
        ///      0: Not signaled, 1: Signaled, 2: Submitted.
        /// TODO: Add or check to see if req = 0 in the case that signal was not required
        require(performance & 0x3 == 1, 'LaborMarket::provide: Not signaled');

        /// @dev Add the Provider to the list of submissions.
        serviceIdToRequest[_requestId].submissions.add(_msgSender);

        /// @dev Set the participation ID to reflect the providers address.
        participationId = uint256(uint160(_msgSender()));

        /// @dev Provider has submitted and set the value of the first two bits to 2.
        requestIdToAddressToPerformance[_requestId][_msgSender()] =
            /// @dev Keep the last 22 bits but clear the first two bits.
            (performance & 0xFFFFFC) |
            /// @dev Set the first two bits to 2.
            0x2;

        /// @notice Announce the submission of a service provider.
        emit RequestFulfilled(_msgSender(), _requestId, participationId, _uri);
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
        require(_submissionId != uint256(uint160(_msgSender())), 'LaborMarket::review: Cannot review own submission');

        /// @notice Ensure the request is still in the enforcement phase.
        require(
            block.timestamp <= serviceIdToRequest[_requestId].enforcementExp,
            'LaborMarket::review: Enforcement deadline passed'
        );

        /// @notice Make the external call into the enforcement module to submit the callers score.
        /// TODO: How is it even possible that we don't need to pass the reviewer address?
        /// TODO: Pretty sure that we are going to have to.
        (bool newSubmission, uint24 intentChange) = criteria.enforce(_requestId, _submissionId, _score);

        /// @notice If the user is scoring a new submission, then deduct their signal.
        /// @dev This implicitly enables the ability to have an enforcement criteria that supports
        ///       many different types of scoring rubrics, but also submitting a score multiple times.
        ///       In the case that only one submission is wanted, then the enforcement criteria should
        ///       return `true` to indicate signal deduction is owed.
        if (newSubmission) {
            /// @notice Calculate the active intent value of the maintainer.
            uint24 intent = requestIdToAddressToPerformance[_requestId][_msgSender()];

            /// @notice Get the remaining signal value of the maintainer.
            /// @dev Uses the last 22 bits of the performance value by shifting over 2 values and then
            ///      masking down to the last 22 bits with an overlap of 0x3fffff.
            uint24 remainingIntent = (requestIdToAddressToPerformance[_requestId][_msgSender()] >> 2) & 0x3fffff;

            /// @notice Ensure the maintainer is not exceeding their signaled intent.
            require(remainingIntent > 0, 'LaborMarket::review: Not signaled');

            /// @notice Lower the bitpacked value representing the remaining signal value of
            ///         the caller for this request.
            /// @dev This bitwise shifts shifts 22 bits to the left to clear the previous value
            ///      and then bitwise ORs the remaining signal value minus 1 to the left by 2 bits.
            requestIdToAddressToPerformance[_requestId][_msgSender()] =
                /// @dev Keep all the bits besides the 22 bits that represent the remaining signal value.
                (intent & 0xff000003) |
                /// @dev Shift the remaining signal value minus 1 to the left by 2 bits to fill the 22.
                ((remainingIntent - intentChange) << 2);

            /// @notice Announce the new submission of a score by a maintainer.
            emit RequestReviewed(_msgSender(), _requestId, _submissionId, _score);
        }
    }

    /**
     * @notice Allows a service provider to claim payment for a service submission.
     * @dev When you want to determine what the earned amount is, you can use this
     *      function with a static call to determine the qausi-state of claiming.
     * @param _requestId The id of the service request being fulfilled.
     * @param _submissionId The id of the service providers submission.
     * @return pTokenClaimed The amount of pTokens claimed.
     * @return rTokenClaimed The amount of rTokens claimed.
     *
     * Requirements:
     * - The submission has not already been claimed.
     * - The provider is the sender.
     * - The enforcement deadline has passed.
     */
    function claim(uint256 _requestId, uint256 _submissionId) external returns (bool success, uint256) {
        /// @notice Get the request out of storage to warm the slot.
        ServiceRequest storage request = serviceIdToRequest[_requestId];

        /// @notice Ensure the request is no longer in the enforcement phase.
        require(block.timestamp >= request.enforcementExp, 'LaborMarket::claim: Enforcement deadline not passed');

        /// @notice Get the rewards attributed to this submission.
        (uint256 amount, bool requiresSubmission) = criteria.rewards(address(this), _requestId, _submissionId);

        if (amount != 0) {
            /// @notice Remove the submission from the list of submissions.
            /// @dev This is done before the transfer to prevent reentrancy attacks.
            bool removed = request.submissions.remove(_submissionId);

            /// @dev Allow the enforcement criteria to perform any additional logic.
            require(!requiresSubmission || removed, 'LaborMarket::claim: Invalid submission claim');

            /// @notice Transfer the pTokens to the network participant.
            request.pToken.transfer(address(uint160(_submissionId)), amount);

            /// @notice Update health status for bulk processing offchain.
            success = true;

            /// @notice Announce the claiming of a service provider reward.
            emit RequestPayClaimed(_msgSender(), _requestId, _submissionId, amount, provider);
        }

        /// @notice If there were no funds to claim, acknowledge the failure of the transfer
        ///         and return false without blocking the transaction.

        /// @notice Return the amount of pTokens claimed.
        return (success, amount);
    }

    /**
     * @notice Allows a service requester to claim the remainder of funds not allocated to service providers.
     * @param _requestId The id of the service request.
     *
     * Requirements:
     * - The enforcement deadline has passed.
     * - The requester has a remainder to claim.
     */
    function claimRemainder(uint256 _requestId) public virtual returns (bool success, uint256 amount) {
        /// @dev Get the request out of storage to warm the slot.
        ServiceRequest storage request = serviceIdToRequest[_requestId];

        /// @dev Ensure the request is no longer in the enforcement phase.
        require(
            block.timestamp >= request.enforcementExp,
            'LaborMarket::claimRemainder: Enforcement deadline not passed'
        );

        /// @dev Determine the amount of undistributed money remaining in the request.
        amount = criteria.remainder(address(this), _requestId);

        /// @notice Redistribute the funds that were not earned.
        /// @dev This model has been implemented to allow for bulk distribution of unclaimed rewards to
        ///      assist in keeping the economy as healthy as possible.
        if (amount != 0) {
            /// @dev Pull the address of the requester out of storage.
            address requester = request.serviceRequester;

            /// @dev Transfer the remainder of the deposit funds back to the requester.
            request.pToken.transfer(requester, amount);

            /// @dev Update health status for bulk processing offchain.
            success = true;

            /// @dev Announce the claiming of the remainder.
            emit RemainderClaimed(_msgSender(), _requestId, amount, requester);
        }

        /// @notice If there were no funds to reclaim, acknowledge the failure of the transaction
        ///         and return false without blocking the transaction.
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
        /// @dev Get the request out of storage to warm the slot.
        ServiceRequest storage request = serviceIdToRequest[_requestId];

        /// @dev Ensure that only the Requester may withdraw the request.
        require(request.serviceRequester == _msgSender(), 'LaborMarket::withdrawRequest: Not requester');

        /// @dev Require the request has not been signaled.
        // TODO: This should be updated to check if is still in signalling phase.
        require(signalCount[_requestId] < 1, 'LaborMarket::withdrawRequest: Already active');

        /// @notice Delete the request and prevent further action.
        delete request.serviceRequester;
        delete request.pToken;
        delete request.pTokenQ;
        delete request.signalExp;
        delete request.submissionExp;
        delete request.enforcementExp;
        delete request.submissionCount;
        delete request.uri;
        delete request;

        /// @notice Return the $pToken back to the Requester.
        /// @dev This is done last to prevent reentrancy attacks.
        request.pToken.transfer(_msgSender(), request.pTokenQ);

        /// @dev Announce the withdrawal of a request.
        emit RequestWithdrawn(_requestId);
    }
}
