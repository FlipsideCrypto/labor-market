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
     * Requirements:
     * - A user has to be conform to the reputational restrictions imposed by the labor market.
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

        // Keep accounting in mind for ERC20s with transfer fees.
        uint256 pTokenBefore = IERC20(_pToken).balanceOf(address(this));

        IERC20(_pToken).transferFrom(_msgSender(), address(this), _pTokenQ);

        uint256 pTokenAfter = IERC20(_pToken).balanceOf(address(this));

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
            "LaborMarket::signal: Signal deadline passed."
        );
        require(
            !hasPerformed[_requestId][_msgSender()][HAS_SIGNALED],
            "LaborMarket::signal: Already signaled."
        );

        reputationModule.useReputation(_msgSender(), configuration.signalStake);

        hasPerformed[_requestId][_msgSender()][HAS_SIGNALED] = true;

        unchecked {
            ++signalCount[_requestId];
        }

        emit RequestSignal(_msgSender(), _requestId, configuration.signalStake);
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
            "LaborMarket::signalReview: Already signaled."
        );

        uint256 signalStake = _quantity * configuration.signalStake;

        reputationModule.useReputation(_msgSender(), signalStake);

        reviewPromise.total = _quantity;
        reviewPromise.remainder = _quantity;

        emit ReviewSignal(_msgSender(), _quantity, signalStake);
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
            "LaborMarket::provide: Submission deadline passed."
        );
        require(
            hasPerformed[_requestId][_msgSender()][HAS_SIGNALED],
            "LaborMarket::provide: Not signaled."
        );
        require(
            !hasPerformed[_requestId][_msgSender()][HAS_SUBMITTED],
            "LaborMarket::provide: Already submitted."
        );

        unchecked {
            ++serviceId;
            ++serviceRequests[_requestId].submissionCount;
        }

        ServiceSubmission memory serviceSubmission = ServiceSubmission({
            serviceProvider: _msgSender(),
            requestId: _requestId,
            timestamp: block.timestamp,
            uri: _uri,
            scores: new uint256[](0),
            reviewed: false
        });

        serviceSubmissions[serviceId] = serviceSubmission;

        hasPerformed[_requestId][_msgSender()][HAS_SUBMITTED] = true;

        reputationModule.mintReputation(_msgSender(), configuration.signalStake);

        emit RequestFulfilled(_msgSender(), _requestId, serviceId);

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
            "LaborMarket::review: Enforcement deadline passed."
        );

        require(
            reviewSignals[_requestId][_msgSender()].remainder > 0,
            "LaborMarket::review: Not signaled."
        );

        require(
            !hasPerformed[_submissionId][_msgSender()][HAS_REVIEWED],
            "LaborMarket::review: Already reviewed."
        );

        require(
            serviceSubmissions[_submissionId].serviceProvider != _msgSender(),
            "LaborMarket::review: Cannot review own submission."
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
            (configuration.signalStake) / reviewSignals[_requestId][_msgSender()].total
        );

        emit RequestReviewed(_msgSender(), _requestId, _submissionId, _score);
    }

    /**
     * @notice Allows a service provider to claim payment for a service submission.
     * @param _submissionId The id of the service providers submission.
     */
    function claim(
          uint256 _submissionId
        , address _to
        , bytes calldata _data
    ) 
        external 
        returns (
            uint256
        ) 
    {
        require(
            !hasPerformed[_submissionId][_msgSender()][HAS_CLAIMED],
            "LaborMarket::claim: Already claimed."
        );

        require(
            serviceSubmissions[_submissionId].reviewed,
            "LaborMarket::claim: Not reviewed."
        );

        require(
            serviceSubmissions[_submissionId].serviceProvider == _msgSender(),
            "LaborMarket::claim: Not service provider."
        );

        require(
            block.timestamp >=
                serviceRequests[serviceSubmissions[_submissionId].requestId]
                    .enforcementExp,
            "LaborMarket::claim: Enforcement deadline not passed."
        );

        uint256 curveIndex = (_data.length > 0)
            ? enforcementCriteria.verifyWithData(_submissionId, _data)
            : enforcementCriteria.verify(_submissionId);

        uint256 amount = paymentCurve.curvePoint(curveIndex);

        hasPerformed[_submissionId][_msgSender()][HAS_CLAIMED] = true;

        IERC20(
            serviceRequests[serviceSubmissions[_submissionId].requestId].pToken
        ).transfer(_to, amount);

        emit RequestPayClaimed(_msgSender(), _submissionId, amount, _to);

        return amount;
    }

    /**
     * @notice Allows a service requester to claim the remainder of funds not allocated to service providers.
     * @param _requestId The id of the service request.
     */
    function claimRemainder(
        uint256 _requestId
    ) 
        public 
    {
        require(
            serviceRequests[_requestId].serviceRequester == _msgSender(),
            "LaborMarket::claimRemainder: Not service requester."
        );
        require(
            block.timestamp >= serviceRequests[_requestId].enforcementExp,
            "LaborMarket::claimRemainder: Enforcement deadline not passed."
        );
        require(
            !hasPerformed[_requestId][_msgSender()][HAS_CLAIMED_REMAINDER],
            "LaborMarket::claimRemainder: Already claimed."
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
    function retrieveReputation(uint256 _requestId) 
        public 
    {
        require(
            reviewSignals[_requestId][_msgSender()].remainder > 0,
            "LaborMarket::retrieveReputation: No reputation to retrieve."
        );

        require(
            block.timestamp >
                serviceRequests[serviceSubmissions[serviceId].requestId].enforcementExp,
            "LaborMarket::retrieveReputation: Enforcement deadline not passed."
        );

        ReviewPromise storage reviewPromise = reviewSignals[_requestId][_msgSender()];

        require(
            reviewPromise.total >=
            serviceRequests[_requestId].submissionCount,
            "LaborMarket::retrieveReputation: Insufficient reviews."
        );

        reputationModule.mintReputation(
            _msgSender(),
            configuration.signalStake * reviewPromise.remainder
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
            "LaborMarket::withdrawRequest: Not service requester."
        );
        require(
            signalCount[_requestId] < 1,
            "LaborMarket::withdrawRequest: Already active."
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
            "LaborMarket::withdrawRequest: Not service requester."
        );
        require(
            signalCount[_requestId] < 1,
            "LaborMarket::withdrawRequest: Already active."
        );

        // Refund the prior payment token.
        IERC20(serviceRequests[_requestId].pToken).transfer(
            _msgSender(),
            serviceRequests[_requestId].pTokenQ
        );
    
        // Keep accounting in mind for ERC20s with transfer fees.
        uint256 pTokenBefore = IERC20(_pToken).balanceOf(address(this));

        IERC20(_pToken).transferFrom(_msgSender(), address(this), _pTokenQ);

        uint256 pTokenAfter = IERC20(_pToken).balanceOf(address(this));

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
    }

    /**
     * @notice Allows a network governor to set the configuration.
     * @param _configuration The new configuration.
     * Requirements:
     * - The caller must be a governor at the network level.
     */
    function setConfiguration(
        LaborMarketConfiguration calldata _configuration
    )
        external
    {
        /// @dev Requires the caller to be a governor in the current network.
        network.validateGovernor(_msgSender());
        
        _setConfiguration(_configuration);
    }
}
