// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import {LaborMarketInterface} from "./interfaces/LaborMarketInterface.sol";
import {NBadgeAuth} from "./auth/NBadgeAuth.sol";

/// @dev Helper interfaces
import {EnforcementCriteriaInterface} from "./interfaces/enforcement/EnforcementCriteriaInterface.sol";

/// @dev Helper libraries.
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract LaborMarket is LaborMarketInterface, NBadgeAuth {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev The enforcement criteria module used for this Labor Market.
    EnforcementCriteriaInterface internal criteria;

    /// @dev Primary struct containing the definition of a Request.
    mapping(uint256 => ServiceRequest) public requestIdToRequest;

    /// @dev State id for a user relative to a single Request.
    mapping(uint256 => mapping(address => uint24))
        public requestIdToAddressToPerformance;

    /// @dev Tracking the amount of Provider and Reviewer interested that has been signaled.
    mapping(uint256 => ServiceSignalState) public requestIdToSignalState;

    /// @dev Definition of active Provider submissions for a request.
    mapping(uint256 => EnumerableSet.AddressSet) internal requestIdToProviders;

    /// @dev Prevent implementation from being initialized.
    constructor() {
        _disableInitializers();
    }

    /**
     * See {LaborMarketInterface-initialize}.
     */
    function initialize(
        address _deployer,
        string calldata _uri,
        EnforcementCriteriaInterface _criteria,
        uint256[] calldata _auxilaries,
        uint256[] calldata _alphas,
        uint256[] calldata _betas,
        bytes4[] calldata _sigs,
        Node[] calldata _nodes
    ) external override initializer {
        /// @dev Initialize the access controls of N-Badge.
        __NBadgeAuth_init(_deployer, _sigs, _nodes);

        /// @dev Configure the Labor Market enforcement criteria module.
        criteria = _criteria;

        /// @notice Set the auxiliary value for the criteria that is being used.
        /// @dev This is stored as a relative `uint256` however you may choose to bitpack
        ///      this value with a segment of smaller bits which is only measurable by
        ///      enabled enforcement criteria.
        /// @dev Cross-integration of newly connected modules CANNOT be audited therefore,
        ///      all onus and liability of the integration is on the individual market
        ///      instantiator and the module developer. Risk is mitigated by the fact that
        ///      the module developer is required to deploy the module and the market
        ///      instantiator is required to deploy the market.
        criteria.setConfiguration(_auxilaries, _alphas, _betas);

        /// @dev Announce the configuration of the Labor Market.
        emit LaborMarketConfigured(_deployer, _uri, address(criteria));
    }

    /**
     * See {LaborMarketInterface-submitRequest}.
     */
    function submitRequest(
        uint8 _blockNonce,
        ServiceRequest calldata _request,
        string calldata _uri
    ) public virtual requiresAuth returns (uint256 requestId) {
        /// @notice Ensure the timestamps of the Request phases are valid.
        require(
            block.timestamp < _request.signalExp &&
                _request.signalExp < _request.submissionExp &&
                _request.submissionExp < _request.enforcementExp,
            "LaborMarket::submitRequest: Invalid timestamps"
        );

        /// @notice Ensure the Reviewer and Provider limit are not zero.
        require(
            _request.providerLimit > 0 && _request.reviewerLimit > 0,
            "LaborMarket::submitRequest: Invalid limits"
        );

        /// @notice Generate the uuid for the Request using the nonce, timestamp and address.
        requestId = uint256(
            bytes32(
                abi.encodePacked(
                    _blockNonce,
                    uint88(block.timestamp),
                    uint160(msg.sender)
                )
            )
        );

        /// @notice Ensure the Request does not already exist.
        require(
            requestIdToRequest[requestId].signalExp == 0,
            "LaborMarket::submitRequest: Request already exists"
        );

        /// @notice Store the Request in the Labor Market.
        requestIdToRequest[requestId] = _request;

        /// @notice Announce the creation of a new Request in the Labor Market.
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

        /// @notice Determine the active balances of the tokens held.
        /// @notice Get the balance of tokens denoted for providers.
        uint256 providerBalance = _request.pTokenProvider.balanceOf(msg.sender);

        /// @notice Provide the funding for the Request.
        if (_request.pTokenProviderTotal > 0) {
            /// @dev Transfer the Provider tokens that support the compensation of the Request.
            _request.pTokenProvider.transferFrom(
                msg.sender,
                address(this),
                _request.pTokenProviderTotal
            );

            /// @notice Ensure the Provider balance is correct.
            require(
                _request.pTokenProvider.balanceOf(msg.sender) ==
                    providerBalance - _request.pTokenProviderTotal,
                "LaborMarket::submitRequest: Invalid Provider balance."
            );
        }

        /// @notice Retrieve the balance of Reviewer tokens.
        /// @dev Is calculated down here as Provider and Reviewer token may be the same.
        uint256 reviewerBalance = _request.pTokenReviewer.balanceOf(msg.sender);

        /// @notice Provide the funding for the Request to incentivize Reviewers.
        if (_request.pTokenReviewerTotal > 0) {
            /// @dev Transfer the Reviewer tokens that support the compensation of the Request.
            _request.pTokenReviewer.transferFrom(
                msg.sender,
                address(this),
                _request.pTokenReviewerTotal
            );

            /// @notice Ensure the Reviewer balance is correct.
            require(
                _request.pTokenReviewer.balanceOf(msg.sender) ==
                    reviewerBalance - _request.pTokenReviewerTotal,
                "LaborMarket::submitRequest: Invalid Provider balance."
            );
        }
    }

    /**
     * See {LaborMarketInterface-signal}.
     */
    function signal(uint256 _requestId) public virtual requiresAuth {
        /// @dev Pull the Request out of the storage slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @notice Ensure the signal phase is still active.
        require(
            block.timestamp <= requestIdToRequest[_requestId].signalExp,
            "LaborMarket::signal: Signal deadline passed"
        );

        /// @dev Retrieve the state of the Providers for this Request.
        ServiceSignalState storage signalState = requestIdToSignalState[
            _requestId
        ];

        /// @dev Confirm the maximum number of Providers is never exceeded.
        require(
            signalState.providers + 1 <= request.providerLimit,
            "LaborMarket::signal: Exceeds signal limit"
        );

        /// @notice Increment the number of Providers that have signaled.
        ++signalState.providers;

        /// @notice Get the performance state of the user.
        uint24 performance = requestIdToAddressToPerformance[_requestId][
            msg.sender
        ];

        /// @notice Require the user has not signaled.
        /// @dev Get the first bit of the user's signal value.
        require(
            performance & 0x3 == 0,
            "LaborMarket::signal: Already signaled"
        );

        /// @notice Set the first two bits of the performance state to 1 to indicate the user has signaled
        ///         without affecting the rest of the performance state.
        requestIdToAddressToPerformance[_requestId][msg.sender] =
            /// @dev Keep the last 22 bits but clear the first two bits.
            (performance & 0xFFFFFC) |
            /// @dev Set the first two bits of the performance state to 1 to indicate the user has signaled.
            0x1;

        /// @notice Announce the signaling of a Provider.
        emit RequestSignal(msg.sender, _requestId);
    }

    /**
     * See {LaborMarketInterface-signalReview}.
     */
    function signalReview(
        uint256 _requestId,
        uint24 _quantity
    ) public virtual requiresAuth {
        /// @dev Pull the Request out of the storage slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @notice Ensure the enforcement phase is still active.
        require(
            block.timestamp <= request.enforcementExp,
            "LaborMarket::signalReview: Enforcement deadline passed"
        );

        /// @dev Retrieve the state of the Providers for this Request.
        ServiceSignalState storage signalState = requestIdToSignalState[
            _requestId
        ];

        /// @notice Ensure the signal limit is not exceeded.
        require(
            signalState.reviewers + _quantity <= request.reviewerLimit,
            "LaborMarket::signalReview: Exceeds signal limit"
        );

        /// @notice Increment the number of Reviewers that have signaled.
        signalState.reviewers += _quantity;

        /// @notice Get the performance state of the caller.
        uint24 performance = requestIdToAddressToPerformance[_requestId][
            msg.sender
        ];

        /// @notice Get the intent of the Reviewer.
        /// @dev Shift the performance value to the right by two bits and then mask down to
        ///      the next 22 bits with an overlap of 0x3fffff.
        uint24 reviewIntent = ((performance >> 2) & 0x3fffff);

        /// @notice Ensure that we are the intent will not overflow the 22 bits saved for the quantity.
        /// @dev Mask the `_quantity` down to 22 bits to prevent overflow and user error.
        require(
            reviewIntent + (_quantity & 0x3fffff) <= 4_194_304,
            "LaborMarket::signalReview: Exceeds maximum signal value"
        );

        /// @notice Update the intent of reviewing by summing already signaled quantity with the new quantity
        ///         and then shift it to the left by two bits to make room for the intent of providing.
        requestIdToAddressToPerformance[_requestId][msg.sender] =
            /// @dev Set the last 22 bits of the performance state to the sum of the current intent and the new quantity.
            ((reviewIntent + _quantity) << 2) |
            /// @dev Keep the first two bits of the performance state the same.
            (performance & 0x3);

        /// @notice Announce the signaling of a Reviewer.
        emit ReviewSignal(msg.sender, _requestId, _quantity);
    }

    /**
     * See {LaborMarketInterface-provide}.
     */
    function provide(
        uint256 _requestId,
        string calldata _uri
    ) public virtual returns (uint256 submissionId) {
        /// @dev Get the Request out of storage to warm the slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @notice Require the submission phase is still active.
        require(
            block.timestamp <= request.submissionExp,
            "LaborMarket::provide: Submission deadline passed"
        );

        /// @notice Get the performance state of the caller.
        uint24 performance = requestIdToAddressToPerformance[_requestId][
            msg.sender
        ];

        /// @notice Ensure that the Provider has signaled, but has not already submitted.
        /// @dev Get the first two bits of the user's performance value.
        ///      0: Not signaled, 1: Signaled, 2: Submitted.
        require(performance & 0x3 == 1, "LaborMarket::provide: Not signaled");

        /// @dev Add the Provider to the list of submissions.
        requestIdToProviders[_requestId].add(msg.sender);

        /// @dev Set the submission ID to reflect the Providers address.
        submissionId = uint256(uint160(msg.sender));

        /// @dev Provider has submitted and set the value of the first two bits to 2.
        requestIdToAddressToPerformance[_requestId][msg.sender] =
            /// @dev Keep the last 22 bits but clear the first two bits.
            (performance & 0xFFFFFC) |
            /// @dev Set the first two bits to 2.
            0x2;

        /// @dev Add signal state to the request.
        requestIdToSignalState[_requestId].providersArrived += 1;

        /// @notice Announce the submission of a Provider.
        emit RequestFulfilled(msg.sender, _requestId, submissionId, _uri);
    }

    /**
     * See {LaborMarketInterface-review}.
     */
    function review(
        uint256 _requestId,
        uint256 _submissionId,
        uint256 _score,
        string calldata _uri
    ) public virtual {
        /// @notice Determine the number-derived id of the caller.
        uint256 reviewId = uint256(uint160(msg.sender));

        /// @notice Ensure that no one is grading their own Submission.
        require(
            _submissionId != reviewId,
            "LaborMarket::review: Cannot review own submission"
        );

        /// @notice Ensure reviewing a valid submission.
        require(
            requestIdToProviders[_requestId].contains(
                address(uint160(_submissionId))
            ),
            "LaborMarket::review: Cannot review submission that does not exist"
        );

        /// @notice Get the Request out of storage to warm the slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @notice Ensure the Request is still in the enforcement phase.
        require(
            block.timestamp <= request.enforcementExp,
            "LaborMarket::review: Enforcement deadline passed"
        );

        /// @notice Make the external call into the enforcement module to submit the callers score.
        (bool newSubmission, uint24 intentChange) = criteria.enforce(
            _requestId,
            _submissionId,
            _score,
            request.pTokenProviderTotal / request.providerLimit,
            msg.sender
        );

        /// @notice If the user is submitting a "new score" according to the module, then deduct their signal.
        /// @dev This implicitly enables the ability to have an enforcement criteria that supports
        ///       many different types of scoring rubrics, but also "submitting a score multiple times."
        ///       In the case that only one response from each reviewer is wanted, then the enforcement
        ///       criteria should return `true` to indicate signal deduction is owed at all times.
        if (newSubmission) {
            /// @notice Calculate the active intent value of the Reviewer.
            uint24 intent = requestIdToAddressToPerformance[_requestId][
                msg.sender
            ];

            /// @notice Get the remaining signal value of the Reviewer.
            /// @dev Uses the last 22 bits of the performance value by shifting over 2 values and then
            ///      masking down to the last 22 bits with an overlap of 0x3fffff.
            uint24 remainingIntent = (requestIdToAddressToPerformance[
                _requestId
            ][msg.sender] >> 2) & 0x3fffff;

            /// @notice Ensure the Reviewer is not exceeding their signaled intent.
            require(remainingIntent > 0, "LaborMarket::review: Not signaled");

            /// @notice Lower the bitpacked value representing the remaining signal value of
            ///         the caller for this Request.
            /// @dev This bitwise shifts shifts 22 bits to the left to clear the previous value
            ///      and then bitwise ORs the remaining signal value minus 1 to the left by 2 bits.
            requestIdToAddressToPerformance[_requestId][msg.sender] =
                /// @dev Keep all the bits besides the 22 bits that represent the remaining signal value.
                (intent & 0x3) |
                /// @dev Shift the remaining signal value minus 1 to the left by 2 bits to fill the 22.
                ((remainingIntent - intentChange) << 2);

            /// @dev Decrement the total amount of enforcement capacity needed to finalize this Request.
            requestIdToSignalState[_requestId].reviewersArrived += intentChange;

            /// @notice Determine if the Request incentivized Reviewers to participate.
            if (request.pTokenReviewerTotal > 0)
                /// @notice Transfer the tokens from the Market to the Reviewer.
                request.pTokenReviewer.transfer(
                    msg.sender,
                    request.pTokenReviewerTotal / request.reviewerLimit
                );

            /// @notice Announce the new submission of a score by a maintainer.
            emit RequestReviewed(
                msg.sender,
                _requestId,
                _submissionId,
                reviewId,
                _score,
                _uri
            );
        }
    }

    /**
     * See {LaborMarketInterface-claim}.
     */
    function claim(
        uint256 _requestId,
        uint256 _submissionId
    ) external returns (bool success, uint256) {
        /// @notice Get the Request out of storage to warm the slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @notice Ensure the Request is no longer in the enforcement phase.
        require(
            block.timestamp >= request.enforcementExp,
            "LaborMarket::claim: Enforcement deadline not passed"
        );

        /// @notice Get the rewards attributed to this Submission.
        (uint256 amount, bool requiresSubmission) = criteria.rewards(
            _requestId,
            _submissionId
        );

        /// @notice Ensure the Submission has funds to claim.
        if (amount != 0) {
            /// @notice Recover the address by truncating the Submission id.
            address provider = address(uint160(_submissionId));

            /// @notice Remove the Submission from the list of Submissions.
            /// @dev This is done before the transfer to prevent reentrancy attacks.
            bool removed = requestIdToProviders[_requestId].remove(provider);

            /// @dev Allow the enforcement criteria to perform any additional logic.
            require(
                !requiresSubmission || removed,
                "LaborMarket::claim: Invalid submission claim"
            );

            /// @notice Transfer the pTokens to the network participant.
            /// @dev Update health status for bulk processing offchain.
            success = request.pTokenProvider.transfer(provider, amount);

            /// @notice Announce the claiming of a service provider reward.
            emit RequestPayClaimed(
                msg.sender,
                _requestId,
                _submissionId,
                amount,
                provider
            );
        }

        /// @notice If there were no funds to claim, acknowledge the failure of the transfer
        ///         and return false without blocking the transaction.

        /// @notice Return the amount of pTokens claimed.
        return (success, amount);
    }

    /**
     * See {LaborMarketInterface-claimRemainder}.
     */
    function claimRemainder(
        uint256 _requestId
    )
        public
        virtual
        returns (
            bool pTokenProviderSuccess,
            bool pTokenReviewerSuccess,
            uint256 pTokenProviderSurplus,
            uint256 pTokenReviewerSurplus
        )
    {
        /// @dev Get the Request out of storage to warm the slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @dev Ensure the Request is no longer in the enforcement phase.
        require(
            block.timestamp >= request.enforcementExp,
            "LaborMarket::claimRemainder: Enforcement deadline not passed"
        );

        /// @notice Get the signal state of the Request.
        ServiceSignalState storage signalState = requestIdToSignalState[
            _requestId
        ];

        /// @notice Determine the amount of available Provider payments never redeemed.
        pTokenProviderSurplus =
            (request.providerLimit - signalState.providersArrived) *
            (request.pTokenProviderTotal / request.providerLimit);

        /// @notice Determine the amount of available Reviewer payments never redeemed.
        pTokenReviewerSurplus =
            (request.reviewerLimit - signalState.reviewersArrived) *
            (request.pTokenReviewerTotal / request.reviewerLimit);

        /// @notice Determine the amount of undistributed money remaining in the Request.
        /// @dev This accounts for funds that were attempted to be earned, but failed to be by
        ///      not meeting the enforcement standards of the criteria module enabled.
        pTokenProviderSurplus += criteria.remainder(_requestId);

        /// @dev Pull the address of the Requester out of storage.
        address requester = address(uint160(_requestId));

        /// @notice Redistribute the Provider allocated funds that were not earned.
        if (pTokenProviderSurplus != 0) {
            /// @notice Transfer the remainder of the deposit funds back to the requester.
            request.pTokenProvider.transfer(requester, pTokenProviderSurplus);

            /// @dev Bubble up the success to the return.
            pTokenProviderSuccess = true;
        }

        /// @notice Redistribute the Reviewer allocated funds that were not earned.
        if (pTokenReviewerSurplus != 0) {
            /// @notice Transfer the remainder of the deposit funds back to the Requester.
            request.pTokenReviewer.transfer(requester, pTokenReviewerSurplus);

            /// @notice Bubble up the success to the return.
            pTokenReviewerSuccess = true;
        }

        /// @notice Announce a simple event to allow for offchain processing.
        if (pTokenProviderSuccess || pTokenReviewerSuccess) {
            /// @dev Determine if there will be a remainder after the claim.
            bool settled = pTokenProviderSurplus == 0 &&
                pTokenReviewerSurplus == 0;

            /// @notice Announce the claiming of a service requester reward.
            emit RemainderClaimed(msg.sender, _requestId, requester, settled);
        }

        /// @notice If there were no funds to reclaim, acknowledge the failure of the claim
        ///         and return false without blocking the transaction.
    }

    /**
     * See {LaborMarketInterface-withdrawRequest}.
     */
    function withdrawRequest(uint256 _requestId) public virtual {
        /// @dev Get the Request out of storage to warm the slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @dev Ensure that only the Requester may withdraw the Request.
        require(
            address(uint160(_requestId)) == msg.sender,
            "LaborMarket::withdrawRequest: Not requester"
        );

        /// @dev Require that the Request does not have any signal state.
        require(
            (requestIdToSignalState[_requestId].providers |
                requestIdToSignalState[_requestId].reviewers |
                requestIdToSignalState[_requestId].providersArrived |
                requestIdToSignalState[_requestId].reviewersArrived) == 0,
            "LaborMarket::withdrawRequest: Already active"
        );

        /// @dev Initialize the refund amounts before clearing storage.
        uint256 pTokenProviderRemainder = request.pTokenProviderTotal;
        uint256 pTokenReviewerRemainder = request.pTokenReviewerTotal;

        /// @notice Delete the Request and prevent further action.
        delete request.signalExp;
        delete request.submissionExp;
        delete request.enforcementExp;
        delete request.providerLimit;
        delete request.reviewerLimit;
        delete request.pTokenProviderTotal;
        delete request.pTokenReviewerTotal;

        /// @notice Return the Provider payment token back to the Requester.
        if (pTokenProviderRemainder > 0)
            request.pTokenProvider.transfer(
                msg.sender,
                pTokenProviderRemainder
            );

        /// @notice Return the Reviewer payment token back to the Requester.
        if (pTokenReviewerRemainder > 0)
            request.pTokenReviewer.transfer(
                msg.sender,
                pTokenReviewerRemainder
            );

        /// @dev Delete the pToken interface references.
        delete request.pTokenProvider;
        delete request.pTokenReviewer;

        /// @dev Announce the withdrawal of a Request.
        emit RequestWithdrawn(_requestId);
    }
}
