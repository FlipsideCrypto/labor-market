// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarketInterface } from './interfaces/LaborMarketInterface.sol';
import { NBadgeAuth } from './auth/NBadgeAuth.sol';

/// @dev Helper interfaces
import { EnforcementCriteriaInterface } from './interfaces/enforcement/EnforcementCriteriaInterface.sol';

/// @dev Helper libraries.
import { EnumerableSet } from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

contract LaborMarket is LaborMarketInterface, NBadgeAuth {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev The enforcement criteria module used for this Labor Market.
    EnforcementCriteriaInterface internal criteria;

    /// @dev Primary struct containing the definition of a Request.
    mapping(uint256 => ServiceRequest) public requestIdToRequest;

    /// @dev State id for a user relative to a single Request.
    mapping(uint256 => mapping(address => uint24)) public requestIdToAddressToPerformance;

    /// @dev Tracking the amount of Provider and Reviewer interested that has been signaled.
    mapping(uint256 => ServiceSignalState) public requestIdToSignalState;

    /// @dev Definition of active Provider submissions for a request.
    mapping(uint256 => EnumerableSet.AddressSet) internal requestIdToProviders;

    /// @dev Prevent implementation from being initialized.
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the Labor Market contract.
     * @param _deployer The address of the deployer.
     * @param _criteria The enforcement criteria module used for this Labor Market.
     * @param _auxilaries The auxiliary values for the criteria that is being used.
     * @param _alphas The alpha values for the criteria that is being used.
     * @param _betas The beta values for the criteria that is being used.
     */
    function initialize(
        address _deployer,
        EnforcementCriteriaInterface _criteria,
        uint256[] calldata _auxilaries,
        uint256[] calldata _alphas,
        uint256[] calldata _betas
    ) external initializer {
        // TODO: uncomment -- just wanted to see if this was the only thing preventing compilation.
        // __NBadgeAuth_init(_deployer);

        /// @dev Configure the Labor Market state control.
        criteria = _criteria;

        /// @notice Set the auxiliary value for the criteria that is being used.
        /// @dev This is stored as a relative `uint256` however you may choose to bitpack
        ///      this value with a segment of smaller bits which is only measurable by
        ///      enabled enforcement criteria.
        /// @dev Cross-integration of newly connected modules CANNOT be audited therefore,
        ///      all onus and liability of the integration is on the individual market
        ///      instantiator and the module developer.
        criteria.setConfiguration(_auxilaries, _alphas, _betas);

        /// @dev Announce the configuration of the Labor Market.
        emit LaborMarketConfigured(_deployer, address(criteria));
    }

    /**
     * @notice Creates a service request.
     * @param _request The request being submit for a work request in the Labor Market.
     * @param _uri The uri of the request.
     * @return requestId The id of the service request.
     *
     * Requirements:
     * - Caller has to have approved the LaborMarket contract to transfer the payment token.
     * - Timestamps must be valid and chronological.
     */
    function submitRequest(
        uint8 _blockNonce,
        ServiceRequest calldata _request,
        string calldata _uri
    ) public virtual requiresAuth returns (uint256 requestId) {
        /// @notice Ensure the timestamps of the request phases are valid.
        require(
            block.timestamp < _request.signalExp &&
                _request.signalExp < _request.submissionExp &&
                _request.submissionExp < _request.enforcementExp,
            'LaborMarket::submitRequest: Invalid timestamps'
        );

        /// @notice Ensure the reviewer and provider limit are not zero.
        require(_request.providerLimit > 0 && _request.reviewerLimit > 0, 'LaborMarket::submitRequest: Invalid limits');

        /// @notice Generate the uuid for the request using the timestamp and address.
        requestId = uint256(keccak256(abi.encodePacked(_blockNonce, uint88(block.timestamp), uint160(msg.sender))));

        /// @notice Ensure the request does not already exist.
        require(requestIdToRequest[requestId].signalExp == 0, 'LaborMarket::submitRequest: Request already exists');

        /// @notice Store the request in the Labor Market.
        requestIdToRequest[requestId] = _request;

        /// @notice Announce the creation of a new request in the Labor Market.
        emit RequestConfigured(
            msg.sender,
            requestId,
            _request.signalExp,
            _request.submissionExp,
            _request.enforcementExp,
            _request.providerLimit,
            _request.reviewerLimit,
            _request.pTokenProviderTotal,
            _request.pTokenReviewerTotal,
            _request.pTokenProvider,
            _request.pTokenReviewer,
            _uri
        );

        /// @notice Provide the funding for the request.
        if (_request.pTokenProviderTotal > 0) {
            /// @dev Transfer the provider tokens that support the compensation of the Request.
            _request.pTokenProvider.transferFrom(msg.sender, address(this), _request.pTokenProviderTotal);
        }

        /// @notice Provide the funding for the request.
        if (_request.pTokenReviewerTotal > 0) {
            /// @dev Transfer the reviewer tokens that support the compensation of the Request.
            _request.pTokenReviewer.transferFrom(msg.sender, address(this), _request.pTokenReviewerTotal);
        }
    }

    /**
     * @notice Signals interest in fulfilling a service request.
     * @param _requestId The id of the service request.
     *
     * Requirements:
     * - The signal deadline has not passed.
     * - The user has not already signaled.
     * - The Signal Limit has not been reached.
     */
    function signal(uint256 _requestId) public virtual requiresAuth {
        /// @dev Pull the request out of the storage slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @notice Ensure the signal phase is still active.
        require(
            block.timestamp <= requestIdToRequest[_requestId].signalExp,
            'LaborMarket::signal: Signal deadline passed'
        );

        /// @dev Retrieve the state of the providers for this request.
        ServiceSignalState storage signalState = requestIdToSignalState[_requestId];

        /// @dev Confirm the maximum number of providers is never exceeded.
        require(signalState.providers + 1 <= request.providerLimit, 'LaborMarket::signal: Exceeds signal limit');

        /// @notice Increment the number of providers that have signaled.
        ++signalState.providers;

        /// @notice Get the performance state of the user.
        uint24 performance = requestIdToAddressToPerformance[_requestId][msg.sender];

        /// @notice Require the user has not signaled.
        /// @dev Get the first bit of the user's signal value.
        require(performance & 0x3 == 0, 'LaborMarket::signal: Already signaled');

        /// @notice Set the first two bits of the performance state to 1 to indicate the user has signaled
        ///         without affecting the rest of the performance state.
        requestIdToAddressToPerformance[_requestId][msg.sender] =
            /// @dev Keep the last 22 bits but clear the first two bits.
            (performance & 0xFFFFFC) |
            /// @dev Set the first two bits of the performance state to 1 to indicate the user has signaled.
            0x1;

        /// @notice Announce the signalling of a service provider.
        emit RequestSignal(msg.sender, _requestId);
    }

    /**
     * @notice Signals interest in reviewing a submission.
     * @param _requestId The id of the request a maintainer would like to assist in reviewing.
     * @param _quantity The amount of submissions a reviewer has intent to manage.
     *
     * Requirements:
     * - Quantity has to be less than 4,194,304.
     */
    function signalReview(uint256 _requestId, uint24 _quantity) public virtual requiresAuth {
        /// @dev Pull the request out of the storage slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @notice Ensure the enforcement phase is still active.
        require(block.timestamp <= request.enforcementExp, 'LaborMarket::signalReview: Enforcement deadline passed');

        /// @dev Retrieve the state of the providers for this request.
        ServiceSignalState storage signalState = requestIdToSignalState[_requestId];

        /// @notice Ensure the signal limit is not exceeded.
        require(
            signalState.reviewers + _quantity <= request.reviewerLimit,
            'LaborMarket::signalReview: Exceeds signal limit'
        );

        /// @notice Increment the number of reviewers that have signaled.
        signalState.reviewers += _quantity;

        /// @notice Get the performance state of the user.
        uint24 performance = requestIdToAddressToPerformance[_requestId][msg.sender];

        /// @notice Get the intent of the maintainer.
        /// @dev Shift the performance value to the right by two bits and then mask down to
        ///      the next 22 bits with an overlap of 0x3fffff.
        uint24 reviewIntent = ((performance >> 2) & 0x3fffff);

        /// @notice Ensure that we are the intent will not overflow the 22 bits saved for the quantity.
        /// @dev Mask the `_quantity` down to 22 bits to prevent overflow and user error.
        require(
            reviewIntent + (_quantity & 0x3fffff) <= 4_194_304,
            'LaborMarket::signalReview: Exceeds maximum signal value'
        );

        /// @notice Update the intent of reviewing by summing already signaled quantity with the new quantity
        ///         and then shift it to the left by two bits to make room for the intent of providing.
        requestIdToAddressToPerformance[_requestId][msg.sender] =
            /// @dev Set the last 22 bits of the performance state to the sum of the current intent and the new quantity.
            ((reviewIntent + _quantity) << 2) |
            /// @dev Keep the first two bits of the performance state the same.
            (performance & 0x3);

        /// @notice Announce the signalling of a service reviewer.
        emit ReviewSignal(msg.sender, _requestId, _quantity);
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
    function provide(uint256 _requestId, string calldata _uri) external returns (uint256 submissionId) {
        /// @dev Get the request out of storage to warm the slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @notice Require the submission phase is still active.
        require(block.timestamp <= request.submissionExp, 'LaborMarket::provide: Submission deadline passed');

        /// @notice Get the performance state of the user.
        uint24 performance = requestIdToAddressToPerformance[_requestId][msg.sender];

        /// @notice Ensure that the provider has signaled, but has not already submitted.
        /// @dev Get the first two bits of the user's performance value.
        ///      0: Not signaled, 1: Signaled, 2: Submitted.
        require(performance & 0x3 == 1, 'LaborMarket::provide: Not signaled');

        /// @dev Add the Provider to the list of submissions.
        requestIdToProviders[_requestId].add(msg.sender);

        /// @dev Set the submission ID to reflect the providers address.
        submissionId = uint256(uint160(msg.sender));

        /// @dev Provider has submitted and set the value of the first two bits to 2.
        requestIdToAddressToPerformance[_requestId][msg.sender] =
            /// @dev Keep the last 22 bits but clear the first two bits.
            (performance & 0xFFFFFC) |
            /// @dev Set the first two bits to 2.
            0x2;

        /// @dev Add signal state to the request.
        requestIdToSignalState[_requestId].providersArrived += 1;

        /// @notice Announce the submission of a service provider.
        emit RequestFulfilled(msg.sender, _requestId, submissionId, _uri);
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
        uint256 _score,
        string calldata _uri
    ) public virtual {
        /// @notice Ensure that no one is grading their own submission.
        require(_submissionId != uint256(uint160(msg.sender)), 'LaborMarket::review: Cannot review own submission');

        /// @notice Get the request out of storage to warm the slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @notice Ensure the request is still in the enforcement phase.
        require(block.timestamp <= request.enforcementExp, 'LaborMarket::review: Enforcement deadline passed');

        /// @notice Make the external call into the enforcement module to submit the callers score.
        (bool newSubmission, uint24 intentChange) = criteria.enforce(
            _requestId,
            _submissionId,
            _score,
            request.pTokenProviderTotal / request.providerLimit,
            msg.sender
        );

        /// @notice If the user is scoring a new submission, then deduct their signal.
        /// @dev This implicitly enables the ability to have an enforcement criteria that supports
        ///       many different types of scoring rubrics, but also submitting a score multiple times.
        ///       In the case that only one submission is wanted, then the enforcement criteria should
        ///       return `true` to indicate signal deduction is owed.
        if (newSubmission) {
            /// @notice Calculate the active intent value of the maintainer.
            uint24 intent = requestIdToAddressToPerformance[_requestId][msg.sender];

            /// @notice Get the remaining signal value of the maintainer.
            /// @dev Uses the last 22 bits of the performance value by shifting over 2 values and then
            ///      masking down to the last 22 bits with an overlap of 0x3fffff.
            uint24 remainingIntent = (requestIdToAddressToPerformance[_requestId][msg.sender] >> 2) & 0x3fffff;

            /// @notice Ensure the maintainer is not exceeding their signaled intent.
            require(remainingIntent > 0, 'LaborMarket::review: Not signaled');

            /// @notice Lower the bitpacked value representing the remaining signal value of
            ///         the caller for this request.
            /// @dev This bitwise shifts shifts 22 bits to the left to clear the previous value
            ///      and then bitwise ORs the remaining signal value minus 1 to the left by 2 bits.
            requestIdToAddressToPerformance[_requestId][msg.sender] =
                /// @dev Keep all the bits besides the 22 bits that represent the remaining signal value.
                (intent & 0x3) |
                /// @dev Shift the remaining signal value minus 1 to the left by 2 bits to fill the 22.
                ((remainingIntent - intentChange) << 2);

            /// @dev Decrement the total amount of enforcement capacity needed to finalize this request.
            requestIdToSignalState[_requestId].reviewersArrived += intentChange;

            /// @notice Determine if the request incentivized reviewers to participate.
            if (request.pTokenReviewerTotal > 0)
                /// @notice Transfer the tokens from the Market to the Reviewer.
                request.pTokenReviewer.transferFrom(
                    address(this),
                    msg.sender,
                    request.pTokenReviewerTotal / request.reviewerLimit
                );

            /// @notice Announce the new submission of a score by a maintainer.
            emit RequestReviewed(msg.sender, _requestId, _submissionId, _score, _uri);
        }
    }

    /**
     * @notice Allows a service provider to claim payment for a service submission.
     * @dev When you want to determine what the earned amount is, you can use this
     *      function with a static call to determine the qausi-state of claiming.
     * @param _requestId The id of the service request being fulfilled.
     * @param _submissionId The id of the service providers submission.
     * @return success Whether or not the claim was successful.
     * @return amount The amount of tokens earned by the submission.
     *
     * Requirements:
     * - The submission has not already been claimed.
     * - The provider is the sender.
     * - The enforcement deadline has passed.
     */
    function claim(uint256 _requestId, uint256 _submissionId) external returns (bool success, uint256) {
        /// @notice Get the request out of storage to warm the slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @notice Ensure the request is no longer in the enforcement phase.
        require(block.timestamp >= request.enforcementExp, 'LaborMarket::claim: Enforcement deadline not passed');

        /// @notice Get the rewards attributed to this submission.
        (uint256 amount, bool requiresSubmission) = criteria.rewards(_requestId, _submissionId);

        /// @notice Ensure the submission has funds to claim.
        if (amount != 0) {
            /// @notice Recover the address of the submission id.
            address provider = address(uint160(_submissionId));

            /// @notice Remove the submission from the list of submissions.
            /// @dev This is done before the transfer to prevent reentrancy attacks.
            bool removed = requestIdToProviders[_requestId].remove(provider);

            /// @dev Allow the enforcement criteria to perform any additional logic.
            require(!requiresSubmission || removed, 'LaborMarket::claim: Invalid submission claim');

            /// @notice Transfer the pTokens to the network participant.
            request.pTokenProvider.transfer(provider, amount);

            /// @notice Update health status for bulk processing offchain.
            success = true;

            /// @notice Announce the claiming of a service provider reward.
            emit RequestPayClaimed(msg.sender, _requestId, _submissionId, amount, provider);
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
    function claimRemainder(uint256 _requestId)
        public
        virtual
        returns (
            bool pTokenProviderSuccess,
            bool pTokenReviewerSuccess,
            uint256 pTokenProviderSurplus,
            uint256 pTokenReviewerSurplus
        )
    {
        /// @dev Get the request out of storage to warm the slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @dev Ensure the request is no longer in the enforcement phase.
        require(
            block.timestamp >= request.enforcementExp,
            'LaborMarket::claimRemainder: Enforcement deadline not passed'
        );

        /// @notice Get the signal state of the request.
        ServiceSignalState storage signalState = requestIdToSignalState[_requestId];

        /// @notice Determine how many of the expected providers never showed up.
        uint64 unarrivedProviders = signalState.providers - signalState.providersArrived;

        /// @notice Determine the amount of available provider shares never redeemed.
        pTokenProviderSurplus = unarrivedProviders * (request.pTokenProviderTotal / request.providerLimit);

        /// @notice Determine how many of the expected reviewers never showed up.
        uint64 unarrivedReviewers = signalState.reviewers - signalState.reviewersArrived;

        /// @notice Determine the amount of available reviewer shares never redeemed.
        pTokenReviewerSurplus = unarrivedReviewers * (request.pTokenReviewerTotal / request.reviewerLimit);

        /// @notice Determine the amount of undistributed money remaining in the request.
        /// @dev This accounts for funds that were attempted to be earned, but failed to be by
        ///      not meeting the enforcement standards of the criteria module enabled.
        pTokenProviderSurplus += criteria.remainder(_requestId);

        /// @dev Pull the address of the requester out of storage.
        address requester = address(uint160(_requestId));

        /// @notice This model has been implemented to allow for bulk distribution of unclaimed rewards to
        ///         assist in keeping the economy as healthy as possible.

        /// @notice Redistribute the Provider allocated funds that were not earned.
        if (pTokenProviderSurplus != 0) {
            /// @notice Transfer the remainder of the deposit funds back to the requester.
            request.pTokenProvider.transfer(requester, pTokenProviderSurplus);

            /// @dev Bubble up the success to the return.
            pTokenProviderSuccess = true;
        }

        /// @notice Redistribute the Reviewer allocated funds that were not earned.
        if (pTokenReviewerSurplus != 0) {
            /// @notice Transfer the remainder of the deposit funds back to the requester.
            request.pTokenReviewer.transfer(requester, pTokenReviewerSurplus);

            /// @notice Bubble up the success to the return.
            pTokenReviewerSuccess = true;
        }

        /// @notice Announce a simple event to allow for offchain processing.
        if (pTokenProviderSuccess || pTokenReviewerSuccess) {
            /// @dev Determine if there will be a remainder after the claim.
            bool settled = pTokenProviderSurplus == 0 && pTokenReviewerSurplus == 0;

            /// @notice Announce the claiming of a service requester reward.
            emit RemainderClaimed(msg.sender, _requestId, requester, settled);
        }

        /// @notice If there were no funds to reclaim, acknowledge the failure of the claim
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
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @dev Ensure that only the Requester may withdraw the request.
        require(address(uint160(_requestId)) == msg.sender, 'LaborMarket::withdrawRequest: Not requester');

        /// @dev Require the request has not been signaled.
        require(
            keccak256(abi.encode(requestIdToSignalState[_requestId])) == bytes32(0),
            'LaborMarket::withdrawRequest: Already active'
        );

        /// @notice Delete the request and prevent further action.
        delete request.signalExp;
        delete request.submissionExp;
        delete request.enforcementExp;
        delete request.providerLimit;
        delete request.reviewerLimit;
        delete request.pTokenProviderTotal;
        delete request.pTokenReviewerTotal;
        delete request.pTokenProvider;
        delete request.pTokenReviewer;

        if (request.pTokenProviderTotal > 0) {
            /// @notice Return the $pToken back to the Requester.
            request.pTokenProvider.transferFrom(address(this), msg.sender, request.pTokenProviderTotal);
        }

        if (request.pTokenReviewerTotal > 0) {
            /// @dev Transfer the reviewer tokens that support the compensation of the Request.
            request.pTokenReviewer.transferFrom(address(this), msg.sender, request.pTokenReviewerTotal);
        }

        /// @dev Announce the withdrawal of a request.
        emit RequestWithdrawn(_requestId);
    }
}
