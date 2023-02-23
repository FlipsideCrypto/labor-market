// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarketManager } from "./LaborMarketManager.sol";

/// @dev Helper interfaces.
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract LaborMarket is LaborMarketManager {
    /**
     * @notice Creates a service request.
     * @param _pToken The address of the payment token.
     * @param _pTokenQ The quantity of the payment token.
     * @param _signalExp The signal deadline expiration.
     * @param _submissionExp The submission deadline expiration.
     * @param _enforcementExp The enforcement deadline expiration.
     * @param _requestUri The uri of the service request data.
     * @return requestId The id of the service request.
     *
     * Requirements:
     * - Caller has to have approved the LaborMarket contract to transfer the payment token.
     * - Timestamps must be valid and chronological.
     */
    function submitRequest(
          address _pToken
        , uint256 _pTokenQ
        , uint256 _signalExp
        , uint256 _submissionExp
        , uint256 _enforcementExp
        , string calldata _requestUri
    ) 
        external 
        returns (
            uint256 requestId
        ) 
    {
        /// @dev Ensure the caller is approved to create a request.
        require(
            isDelegate(_msgSender()), 
            "LaborMarket::submitRequest: Not a delegate"
        );

        /// @dev Ensure the timestamps are valid.
        require(
            _isValidTimestamps(_signalExp, _submissionExp, _enforcementExp),
            "LaborMarket::submitRequest: Invalid timestamps"
        );

        /// @dev Increment the service id.
        unchecked {
            ++serviceId;
        }

        /// @dev Set the request.
        _setRequest(
              serviceId
            , _pToken
            , _pTokenQ
            , _signalExp
            , _submissionExp
            , _enforcementExp
            , _requestUri
        );

        return serviceId;
    }

    /**
     * @notice Signals interest in fulfilling a service request.
     * @param _requestId The id of the service request.
     *
     * Requirements:
     * - A user has to have the reputation balance necessary for this request.
     * - The signal deadline has not passed.
     * - The user has not already signaled.
     */
    function signal(
        uint256 _requestId
    ) 
        external  
    {
        /// @dev Require the caller is a permitted participant.
        require(
            isPermittedParticipant(_msgSender()), 
            "LaborMarket::signal: Not a permitted participant"
        );

        /// @dev Require the signal deadline has not passed.
        require(
            block.timestamp <= serviceRequests[_requestId].signalExp,
            "LaborMarket::signal: Signal deadline passed"
        );

        /// @dev Require the user has not signaled.
        require(
            !hasPerformed[_requestId][_msgSender()][HAS_SIGNALED],
            "LaborMarket::signal: Already signaled"
        );

        /// @dev Increment the signal count.
        unchecked {
            ++signalCount[_requestId];
        }

        /// @dev Use the user's reputation.
        reputationModule.useReputation(
            _msgSender(), 
            configuration.reputationParams.provideStake
        );

        /// @dev Set the user's signal.
        hasPerformed[_requestId][_msgSender()][HAS_SIGNALED] = true;

        emit RequestSignal(_msgSender(), _requestId, configuration.reputationParams.provideStake);
    }

    /**
     * @notice Signals interest in reviewing a submission.
     * @param _requestId The id of the request a maintainer would like to review.
     * @param _quantity The amount of submissions a maintainer is willing to review.
     *
     * Requirements:
     * - The maintainer has to have signaled.
     * - The maintainer has to have enough rToken for the signal quantity.
     */
    function signalReview(
          uint256 _requestId
        , uint256 _quantity
    ) 
        external  
    {
        ReviewPromise storage reviewPromise = reviewSignals[_requestId][_msgSender()];

        /// @dev Require the caller is a maintainer.
        require(
            isMaintainer(_msgSender()),
            "LaborMarket::signalReview: Not a maintainer"
        );
        
        /// @dev Require the maintainer has no outstanding review signals.
        require(
            reviewPromise.remainder == 0,
            "LaborMarket::signalReview: Already signaled"
        );

        /// @dev Calculate the total review stake.
        uint256 reviewStake = _quantity * configuration.reputationParams.reviewStake;

        /// @dev Use the maintainer's reputation.
        reputationModule.useReputation(_msgSender(), reviewStake);

        /// @dev Set the maintainer's review signal.
        reviewPromise.total += _quantity;
        reviewPromise.remainder = _quantity;

        emit ReviewSignal(_msgSender(), _requestId, _quantity, reviewStake);
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
    function provide(
          uint256 _requestId
        , string calldata _uri
    )
        external
        returns (
            uint256
        )
    {
        /// @dev Require the submission deadline has not passed.
        require(
            block.timestamp <= serviceRequests[_requestId].submissionExp,
            "LaborMarket::provide: Submission deadline passed"
        );

        /// @dev Require the user has signaled.
        require(
            hasPerformed[_requestId][_msgSender()][HAS_SIGNALED],
            "LaborMarket::provide: Not signaled"
        );

        /// @dev Require the user has not submitted.
        require(
            !hasPerformed[_requestId][_msgSender()][HAS_SUBMITTED],
            "LaborMarket::provide: Already submitted"
        );

        /// @dev Increment the submission count and service ID.
        unchecked {
            ++serviceId;
            ++serviceRequests[_requestId].submissionCount;
        }

        /// @dev Set the submission.
        serviceSubmissions[serviceId] = ServiceSubmission({
            serviceProvider: _msgSender(),
            requestId: _requestId,
            timestamp: block.timestamp,
            uri: _uri
        });

        /// @dev Provider has submitted.
        hasPerformed[_requestId][_msgSender()][HAS_SUBMITTED] = true;

        /// @dev Use the user's reputation.
        reputationModule.mintReputation(_msgSender(), configuration.reputationParams.provideStake);

        emit RequestFulfilled(_msgSender(), _requestId, serviceId, _uri);

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
          uint256 _requestId
        , uint256 _submissionId
        , uint256 _score
    ) 
        external
    {
        /// @dev Require the enforcement deadline has not passed.
        require(
            block.timestamp <= serviceRequests[_requestId].enforcementExp,
            "LaborMarket::review: Enforcement deadline passed"
        );

        /// @dev Require the maintainer has signaled.
        require(
            reviewSignals[_requestId][_msgSender()].remainder > 0,
            "LaborMarket::review: Not signaled"
        );

        /// @dev Require the maintainer has not reviewed this submission.
        require(
            !hasPerformed[_submissionId][_msgSender()][HAS_REVIEWED],
            "LaborMarket::review: Already reviewed"
        );

        /// @dev Require the maintainer is not the provider.
        require(
            serviceSubmissions[_submissionId].serviceProvider != _msgSender(),
            "LaborMarket::review: Cannot review own submission"
        );

        /// @dev Decrement the maintainer's review signal.
        unchecked {
            --reviewSignals[_requestId][_msgSender()].remainder;
        }

        /// @dev Maintainer has reviewed this submission.
        hasPerformed[_submissionId][_msgSender()][HAS_REVIEWED] = true;

        /// @dev Review the submission.
        enforcementCriteria.review(_submissionId, _score);

        /// @dev Use the maintainer's reputation.
        reputationModule.mintReputation(
            _msgSender(),
            configuration.reputationParams.reviewStake
        );

        emit RequestReviewed(_msgSender(), _requestId, _submissionId, _score);
    }

    /**
     * @notice Allows a service provider to claim payment for a service submission.
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
          uint256 _submissionId
        , address _to
    ) 
        external 
        returns (
              uint256 pTokenClaimed
            , uint256 rTokenClaimed
        ) 
    {
        /// @dev Require the submission has not been claimed.
        require(
            !hasPerformed[_submissionId][_msgSender()][HAS_CLAIMED],
            "LaborMarket::claim: Already claimed"
        );

        /// @dev Require the provider is the sender.
        require(
            serviceSubmissions[_submissionId].serviceProvider == _msgSender(),
            "LaborMarket::claim: Not provider"
        );

        uint256 requestId = serviceSubmissions[_submissionId].requestId;

        /// @dev Require the enforcement deadline has passed.
        require(
            block.timestamp >=
                serviceRequests[requestId]
                    .enforcementExp,
            "LaborMarket::claim: Not enforcement deadline"
        );

        /// @dev Provider has claimed this submission.
        hasPerformed[_submissionId][_msgSender()][HAS_CLAIMED] = true;

        /// @dev Get the rewards.
        (pTokenClaimed, rTokenClaimed) = enforcementCriteria.getRewards(
            address(this),
            _submissionId
        );

        /// @dev Transfer the pTokens.
        IERC20(
            serviceRequests[requestId].pToken
        ).transfer(
            _to,
           pTokenClaimed
        );

        /// @dev Mint the rToken reward.
        reputationModule.mintReputation(
            _msgSender(), 
            rTokenClaimed
        );

        emit RequestPayClaimed(_msgSender(), requestId, _submissionId, pTokenClaimed, _to);
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
    function claimRemainder(
        uint256 _requestId
    ) 
        external 
    {
        /// @dev Require the requester is the sender.
        require(
            serviceRequests[_requestId].serviceRequester == _msgSender(),
            "LaborMarket::claimRemainder: Not requester"
        );

        /// @dev Require the enforcement deadline has passed.
        require(
            block.timestamp >= serviceRequests[_requestId].enforcementExp,
            "LaborMarket::claimRemainder: Not enforcement deadline"
        );

        /// @dev Require the requester has not claimed the remainder.
        require(
            !hasPerformed[_requestId][_msgSender()][HAS_CLAIMED_REMAINDER],
            "LaborMarket::claimRemainder: Already claimed"
        );
        
        /// @dev Get the remainder.
        uint256 totalClaimable = enforcementCriteria.getRemainder(address(this), _requestId);

        /// @dev Requester has claimed the remainder.
        hasPerformed[_requestId][_msgSender()][HAS_CLAIMED_REMAINDER] = true;

        /// @dev Transfer the remainder.
        IERC20(serviceRequests[_requestId].pToken).transfer(
            _msgSender(),
            totalClaimable
        );

        emit RemainderClaimed(_msgSender(), _requestId, totalClaimable);
    }

    /**
     * @notice Allows a maintainer to retrieve reputation that is stuck in review signals.
     * @param _requestId The id of the service request.
     *
     * Requirements:
     * - The enforcement deadline has passed.
     * - The maintainer has reviewed all possible submissions.
     */
    function retrieveReputation(
        uint256 _requestId
    ) 
        external
    {
        /// @dev Require the enforcement deadline has passed.
        require(
            block.timestamp >
                serviceRequests[serviceSubmissions[serviceId].requestId].enforcementExp,
            "LaborMarket::retrieveReputation: Not enforcement deadline"
        );

        ReviewPromise storage reviewPromise = reviewSignals[_requestId][_msgSender()];

        /// @dev Require the maintainer has signaled.
        require(
            reviewPromise.total >=
            serviceRequests[_requestId].submissionCount,
            "LaborMarket::retrieveReputation: Insufficient reviews"
        );

        /// @dev Transfer the reputation.
        reputationModule.mintReputation(
            _msgSender(),
            configuration.reputationParams.reviewStake * reviewPromise.remainder
        );

        /// @dev Reset the review promise.
        reviewPromise.total = 0;
        reviewPromise.remainder = 0;
    }

    /**
     * @notice Allows a service requester to withdraw a request and refund the pToken.
     * @param _requestId The id of the service requesters request.
     *
     * Requirements:
     * - The request must not have been signaled.
     * - The request creator is the sender.
     */
    function withdrawRequest(
        uint256 _requestId
    ) 
        external 
    {
        /// @dev Require the requester is the sender.
        require(
            serviceRequests[_requestId].serviceRequester == _msgSender(),
            "LaborMarket::withdrawRequest: Not requester"
        );

        /// @dev Require the request has not been signaled.
        require(
            signalCount[_requestId] < 1,
            "LaborMarket::withdrawRequest: Already active"
        );

        /// @dev Get the pToken and pToken quantity.
        address pToken = serviceRequests[_requestId].pToken;
        uint256 pTokenQ = serviceRequests[_requestId].pTokenQ;

        /// @dev Delete the request.
        delete serviceRequests[_requestId];

        /// @dev Transfer out the pToken pool.
        IERC20(pToken).transfer(
            _msgSender(),
            pTokenQ
        );

        emit RequestWithdrawn(_requestId);
    }

    /**
     * @notice Allows a service requester to edit a request.
     * @dev Refunds the previous pToken and transfers in the new pToken.
     * @param _requestId The id of the service requesters request.
     * @param _pToken The address of the payment token.
     * @param _pTokenQ The quantity of payment tokens.
     * @param _signalExp The expiration of the signal period.
     * @param _submissionExp The expiration of the submission period.
     * @param _enforcementExp The expiration of the enforcement period.
     * @param _requestUri The uri of the request.
     *
     * Requirements:
     * - The requester is the sender.
     * - The request must not have been signaled.
     * - The timestamps are valid.
     */
    function editRequest(
          uint256 _requestId
        , address _pToken
        , uint256 _pTokenQ
        , uint256 _signalExp
        , uint256 _submissionExp
        , uint256 _enforcementExp
        , string calldata _requestUri
    )
        external
    {
        /// @dev Ensure the requester is the sender.
        require(
            serviceRequests[_requestId].serviceRequester == _msgSender(),
            "LaborMarket::editRequest: Not requester"
        );

        /// @dev Ensure there have been no signals.
        require(
            signalCount[_requestId] < 1,
            "LaborMarket::editRequest: Already active"
        );

        /// @dev Ensure the timestamps are valid.
        require(
            _isValidTimestamps(_signalExp, _submissionExp, _enforcementExp),
            "LaborMarket::editRequest: Invalid timestamps"
        );

        /// @dev Refund the prior payment token.
        IERC20(
            serviceRequests[_requestId].pToken
        ).transfer(
            _msgSender(),
            serviceRequests[_requestId].pTokenQ
        );
    
        /// @dev Change the request config.
        _setRequest(
            _requestId,
            _pToken,
            _pTokenQ,
            _signalExp,
            _submissionExp,
            _enforcementExp,
            _requestUri
        );
    }
}
