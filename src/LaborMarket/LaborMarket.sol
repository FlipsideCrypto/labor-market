// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarketManager } from "./LaborMarketManager.sol";

/// @dev Helper interfaces.
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";

contract LaborMarket is LaborMarketManager {
    /**
     * @notice Creates a service request.
     * @param _pToken The address of the payment token.
     * @param _pTokenQ The quantity of the payment token.
     * @param _signalExp The signal deadline expiration.
     * @param _submissionExp The submission deadline expiration.
     * @param _enforcementExp The enforcement deadline expiration.
     * @param _requestUri The uri of the service request data.
     * Requirements:
     * - A user has to be conform to the reputational restrictions imposed by the labor market.
     * - Caller has to have approved the LaborMarket contract to transfer the payment token.
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
        onlyDelegate 
        returns (
            uint256 requestId
        ) 
    {
        unchecked {
            ++serviceId;
        }

        IERC20 pToken = IERC20(_pToken);

        // Keep accounting in mind for ERC20s with transfer fees.
        uint256 pTokenBefore = pToken.balanceOf(address(this));

        pToken.transferFrom(_msgSender(), address(this), _pTokenQ);

        uint256 pTokenAfter = pToken.balanceOf(address(this));

        ServiceRequest memory serviceRequest = ServiceRequest({
            serviceRequester: _msgSender(),
            pToken: _pToken,
            pTokenQ: (pTokenAfter - pTokenBefore),
            signalExp: _signalExp,
            submissionExp: _submissionExp,
            enforcementExp: _enforcementExp,
            submissionCount: 0,
            uri: _requestUri
        });

        serviceRequests[serviceId] = serviceRequest;

        emit RequestConfigured(
            _msgSender(),
            serviceId,
            _requestUri,
            _pToken,
            _pTokenQ,
            _signalExp,
            _submissionExp,
            _enforcementExp
        );

        return serviceId;
    }

    /**
     * @notice Signals interest in fulfilling a service request.
     * @param _requestId The id of the service request.
     */
    function signal(
        uint256 _requestId
    ) 
        external 
        permittedParticipant 
    {
        require(
            block.timestamp <= serviceRequests[_requestId].signalExp,
            "LaborMarket::signal: Signal deadline passed"
        );
        require(
            !hasPerformed[_requestId][_msgSender()][HAS_SIGNALED],
            "LaborMarket::signal: Already signaled"
        );

        reputationModule.useReputation(_msgSender(), configuration.reputationParams.signalStake);

        hasPerformed[_requestId][_msgSender()][HAS_SIGNALED] = true;

        unchecked {
            ++signalCount[_requestId];
        }

        emit RequestSignal(_msgSender(), _requestId, configuration.reputationParams.signalStake);
    }

    /**
     * @notice Signals interest in reviewing a submission.
     * @param _requestId The id of the request a maintainer would like to review.
     * @param _quantity The amount of submissions a maintainer is willing to review.
     */
    function signalReview(
          uint256 _requestId
        , uint256 _quantity
    ) 
        external 
        onlyMaintainer 
    {
        ReviewPromise storage reviewPromise = reviewSignals[_requestId][_msgSender()];

        require(
            reviewPromise.remainder == 0,
            "LaborMarket::signalReview: Already signaled"
        );

        uint256 signalStake = _quantity * configuration.reputationParams.signalStake;

        reputationModule.useReputation(_msgSender(), signalStake);

        reviewPromise.total = _quantity;
        reviewPromise.remainder = _quantity;

        emit ReviewSignal(_msgSender(), _requestId, _quantity, signalStake);
    }

    /**
     * @notice Allows a service provider to fulfill a service request.
     * @param _requestId The id of the service request being fulfilled.
     * @param _uri The uri of the service submission data.
     */
    function provide(
          uint256 _requestId
        , string calldata _uri
    )
        external
        returns (
            uint256 submissionId
        )
    {
        require(
            block.timestamp <= serviceRequests[_requestId].submissionExp,
            "LaborMarket::provide: Submission deadline passed"
        );
        require(
            hasPerformed[_requestId][_msgSender()][HAS_SIGNALED],
            "LaborMarket::provide: Not signaled"
        );
        require(
            !hasPerformed[_requestId][_msgSender()][HAS_SUBMITTED],
            "LaborMarket::provide: Already submitted"
        );

        unchecked {
            ++serviceId;
            ++serviceRequests[_requestId].submissionCount;
        }

        serviceSubmissions[serviceId] = ServiceSubmission({
            serviceProvider: _msgSender(),
            requestId: _requestId,
            timestamp: block.timestamp,
            uri: _uri,
            scores: new uint256[](0),
            reviewed: false
        });

        hasPerformed[_requestId][_msgSender()][HAS_SUBMITTED] = true;

        reputationModule.mintReputation(_msgSender(), configuration.reputationParams.signalStake);

        emit RequestFulfilled(_msgSender(), _requestId, serviceId, _uri);

        return serviceId;
    }

    /**
     * @notice Allows a maintainer to review a service submission.
     * @param _requestId The id of the service request being fulfilled.
     * @param _submissionId The id of the service providers submission.
     * @param _score The score of the service submission.
     */
    function review(
          uint256 _requestId
        , uint256 _submissionId
        , uint256 _score
    ) 
        external
    {
        require(
            block.timestamp <= serviceRequests[_requestId].enforcementExp,
            "LaborMarket::review: Enforcement deadline passed"
        );

        require(
            reviewSignals[_requestId][_msgSender()].remainder > 0,
            "LaborMarket::review: Not signaled"
        );

        require(
            !hasPerformed[_submissionId][_msgSender()][HAS_REVIEWED],
            "LaborMarket::review: Already reviewed"
        );

        require(
            serviceSubmissions[_submissionId].serviceProvider != _msgSender(),
            "LaborMarket::review: Cannot review own submission"
        );

        _score = enforcementCriteria.review(_submissionId, _score);

        serviceSubmissions[_submissionId].scores.push(_score);

        if (!serviceSubmissions[_submissionId].reviewed)
            serviceSubmissions[_submissionId].reviewed = true;

        hasPerformed[_submissionId][_msgSender()][HAS_REVIEWED] = true;

        unchecked {
            --reviewSignals[_requestId][_msgSender()].remainder;
        }

        reputationModule.mintReputation(
            _msgSender(),
            configuration.reputationParams.signalStake
        );

        emit RequestReviewed(_msgSender(), _requestId, _submissionId, _score);
    }

    /**
     * @notice Allows a service provider to claim payment for a service submission.
     * @param _submissionId The id of the service providers submission.
     * @param _to The address to send the payment to.
     * @param _data The data to send with the payment.
     * @return pTokenClaimed The amount of pTokens claimed.
     */
    function claim(
          uint256 _submissionId
        , address _to
        , bytes calldata _data
    ) 
        external 
        returns (
            uint256 pTokenClaimed
        ) 
    {
        require(
            !hasPerformed[_submissionId][_msgSender()][HAS_CLAIMED],
            "LaborMarket::claim: Already claimed"
        );

        require(
            serviceSubmissions[_submissionId].reviewed,
            "LaborMarket::claim: Not reviewed"
        );

        require(
            serviceSubmissions[_submissionId].serviceProvider == _msgSender(),
            "LaborMarket::claim: Not provider"
        );

        uint256 requestId = serviceSubmissions[_submissionId].requestId;

        require(
            block.timestamp >=
                serviceRequests[requestId]
                    .enforcementExp,
            "LaborMarket::claim: Not enforcement deadline"
        );

        uint256 percentOfPool = enforcementCriteria.getShareOfPoolWithData(
            _submissionId,
            _data
        );

        pTokenClaimed = (serviceRequests[requestId].pTokenQ * percentOfPool) / 1e18;
        console.log("LaborMarket Address: %s", address(this));
        console.log("percentOfPool: %s", percentOfPool);
        console.log("pTokenClaimed: %s", pTokenClaimed);
        console.log("pTokenQ: %s", serviceRequests[requestId].pTokenQ);
        console.log("Before divisor: %s", (serviceRequests[requestId].pTokenQ * percentOfPool));

        hasPerformed[_submissionId][_msgSender()][HAS_CLAIMED] = true;

        IERC20(
            serviceRequests[requestId].pToken
        ).transfer(
            _to, 
            pTokenClaimed
        );

        reputationModule.mintReputation(
            _msgSender(), 
            (configuration.reputationParams.rewardPool * 1e18 * percentOfPool) / 1e18
        );

        emit RequestPayClaimed(_msgSender(), requestId, _submissionId, pTokenClaimed, _to);

        return pTokenClaimed;
    }

    /**
     * @notice Allows a service requester to claim the remainder of funds not allocated to service providers.
     * @param _requestId The id of the service request.
     */
    function claimRemainder(
        uint256 _requestId
    ) 
        external 
    {
        require(
            serviceRequests[_requestId].serviceRequester == _msgSender(),
            "LaborMarket::claimRemainder: Not requester"
        );
        require(
            block.timestamp >= serviceRequests[_requestId].enforcementExp,
            "LaborMarket::claimRemainder: Not enforcement deadline"
        );
        require(
            !hasPerformed[_requestId][_msgSender()][HAS_CLAIMED_REMAINDER],
            "LaborMarket::claimRemainder: Already claimed"
        );
        uint256 totalClaimable = enforcementCriteria.getRemainder(_requestId);

        hasPerformed[_requestId][_msgSender()][HAS_CLAIMED_REMAINDER] = true;

        IERC20(serviceRequests[_requestId].pToken).transfer(
            _msgSender(),
            totalClaimable
        );

        emit RemainderClaimed(_msgSender(), _requestId, totalClaimable);
    }

    /**
     * @notice Allows a maintainer to retrieve reputation that is stuck in review signals.
     * @param _requestId The id of the service request.
     */
    function retrieveReputation(
        uint256 _requestId
    ) 
        external
    {
        require(
            reviewSignals[_requestId][_msgSender()].remainder > 0,
            "LaborMarket::retrieveReputation: No reputation to retrieve"
        );

        require(
            block.timestamp >
                serviceRequests[serviceSubmissions[serviceId].requestId].enforcementExp,
            "LaborMarket::retrieveReputation: Not enforcement deadline"
        );

        ReviewPromise storage reviewPromise = reviewSignals[_requestId][_msgSender()];

        require(
            reviewPromise.total >=
            serviceRequests[_requestId].submissionCount,
            "LaborMarket::retrieveReputation: Insufficient reviews"
        );

        reputationModule.mintReputation(
            _msgSender(),
            configuration.reputationParams.signalStake * reviewPromise.remainder
        );

        reviewPromise.total = 0;
        reviewPromise.remainder = 0;
    }

    /**
     * @notice Allows a service requester to withdraw a request.
     * @param _requestId The id of the service requesters request.
     * Requirements:
     * - The request must not have been signaled.
     */
    function withdrawRequest(
        uint256 _requestId
    ) 
        external 
    {
        require(
            serviceRequests[_requestId].serviceRequester == _msgSender(),
            "LaborMarket::withdrawRequest: Not requester"
        );
        require(
            signalCount[_requestId] < 1,
            "LaborMarket::withdrawRequest: Already active"
        );
        address pToken = serviceRequests[_requestId].pToken;
        uint256 amount = serviceRequests[_requestId].pTokenQ;

        delete serviceRequests[_requestId];

        IERC20(pToken).transfer(_msgSender(), amount);

        emit RequestWithdrawn(_requestId);
    }

    /**
     * @notice Allows a service requester to edit a request.
     * @param _requestId The id of the service requesters request.
     * @param _pToken The address of the payment token.
     * @param _pTokenQ The quantity of payment tokens.
     * @param _signalExp The expiration of the signal period.
     * @param _submissionExp The expiration of the submission period.
     * @param _enforcementExp The expiration of the enforcement period.
     * @param _requestUri The uri of the request.
     * Requirements:
     * - The request must not have been signaled.
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
        require(
            serviceRequests[_requestId].serviceRequester == _msgSender(),
            "LaborMarket::withdrawRequest: Not requester"
        );
        require(
            signalCount[_requestId] < 1,
            "LaborMarket::withdrawRequest: Already active"
        );

        IERC20 pToken = IERC20(_pToken);

        // Refund the prior payment token.
        pToken.transferFrom(
            address(this),
            _msgSender(),
            serviceRequests[_requestId].pTokenQ
        );
    
        // Keep accounting in mind for ERC20s with transfer fees.
        uint256 pTokenBefore = pToken.balanceOf(address(this));

        pToken.transferFrom(_msgSender(), address(this), _pTokenQ);

        uint256 pTokenAfter = pToken.balanceOf(address(this));

        serviceRequests[serviceId] = ServiceRequest({
            serviceRequester: _msgSender(),
            pToken: _pToken,
            pTokenQ: (pTokenAfter - pTokenBefore),
            signalExp: _signalExp,
            submissionExp: _submissionExp,
            enforcementExp: _enforcementExp,
            submissionCount: 0,
            uri: _requestUri
        });

        emit RequestConfigured(
            _msgSender(),
            serviceId,
            _requestUri,
            _pToken,
            _pTokenQ,
            _signalExp,
            _submissionExp,
            _enforcementExp
        );
    }
}
