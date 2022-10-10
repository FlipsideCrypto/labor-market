// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Interfacing
import {MetricNetwork} from "./MetricNetwork.sol";
import {ERC1155, ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

// Structs
import {ServiceRequest} from "./Structs/ServiceRequest.sol";
import {ServiceSubmission} from "./Structs/ServiceSubmission.sol";

// Events & Errors
import {LaborMarketEventsAndErrors} from "./EventsAndErrors/LaborMarketEventsAndErrors.sol";

contract LaborMarket is LaborMarketEventsAndErrors, ERC1155TokenReceiver {
    MetricNetwork public metricNetwork;

    ERC1155 public delegateBadge;
    ERC1155 public participationBadge;

    uint256 public delegateTokenId;
    uint256 public participationTokenId;

    address public payCurve;
    address public enforcementCriteria;

    uint256 public repMultiplier;
    string public marketUri;
    uint256 public immutable marketId;

    mapping(uint256 => uint256) public signalCount;

    mapping(uint256 => ServiceRequest) public serviceRequests;
    mapping(uint256 => ServiceSubmission) public serviceSubmissions;

    mapping(uint256 => mapping(address => bool)) public hasSignaled;
    mapping(uint256 => mapping(address => bool)) public hasSubmitted;
    mapping(uint256 => mapping(address => bool)) public hasClaimed;

    mapping(address => bool) public permissioned;

    uint256 public serviceRequestId;
    uint256 public serviceSubmissionId;

    constructor(
        address _metricNetwork,
        address _delegateBadge,
        uint256 _delegateTokenId,
        address _participationBadge,
        uint256 _participationTokenId,
        address _payCurve,
        address _enforcementCriteria,
        uint256 _repMultiplier,
        string memory _marketUri,
        uint256 _marketId
    ) {
        metricNetwork = MetricNetwork(_metricNetwork);
        delegateBadge = ERC1155(_delegateBadge);
        delegateTokenId = _delegateTokenId;
        participationBadge = ERC1155(_participationBadge);
        participationTokenId = _participationTokenId;
        payCurve = _payCurve;
        enforcementCriteria = _enforcementCriteria;
        repMultiplier = _repMultiplier;
        marketUri = _marketUri;
        marketId = _marketId;
    }

    // Submit a service request
    function submitRequest(
        address pToken,
        uint256 pTokenId,
        uint256 pTokenQ,
        uint256 signalExp,
        uint256 submissionExp,
        uint256 enforcementExp,
        string calldata requestUri
    ) external onlyPermissioned returns (uint256 requestId) {
        unchecked {
            ++serviceRequestId;
        }

        ServiceRequest memory serviceRequest = ServiceRequest({
            serviceRequester: msg.sender,
            pToken: pToken,
            pTokenId: pTokenId,
            pTokenQ: pTokenQ,
            signalExp: signalExp,
            submissionExp: submissionExp,
            enforcementExp: enforcementExp,
            uri: requestUri
        });

        serviceRequests[serviceRequestId] = serviceRequest;

        emit RequestCreated(
            msg.sender,
            serviceRequestId,
            requestUri,
            pToken,
            pTokenId,
            pTokenQ,
            signalExp,
            submissionExp,
            enforcementExp
        );

        return serviceRequestId;
    }

    // Signal a service request
    function signal(uint256 requestId) external permittedParticipant {
        if (requestId > serviceRequestId) {
            revert RequestDoesNotExist(requestId);
        }
        if (block.timestamp > serviceRequests[requestId].signalExp) {
            revert SignalDeadlinePassed();
        }
        if (hasSignaled[requestId][msg.sender]) {
            revert AlreadySignaled();
        }

        uint256 signalAmt = _balanceReputation(
            msg.sender,
            address(this),
            metricNetwork.baseSignal()
        );

        hasSignaled[requestId][msg.sender] = true;

        unchecked {
            ++signalCount[requestId];
        }

        emit RequestSignal(msg.sender, requestId, signalAmt);
    }

    // Fulfill a service request
    function provide(uint256 requestId, string calldata uri)
        external
        permittedParticipant
        returns (uint256 submissionId)
    {
        if (requestId > serviceRequestId) {
            revert RequestDoesNotExist(requestId);
        }
        if (block.timestamp > serviceRequests[requestId].submissionExp) {
            revert SubmissionDeadlinePassed();
        }
        if (!hasSignaled[requestId][msg.sender]) {
            revert NotSignaled();
        }
        if (hasSubmitted[requestId][msg.sender]) {
            revert AlreadySubmitted();
        }

        unchecked {
            ++serviceSubmissionId;
        }

        ServiceSubmission memory serviceSubmission = ServiceSubmission({
            serviceProvider: msg.sender,
            timestamp: block.timestamp,
            uri: uri,
            score: 0
        });

        serviceSubmissions[serviceSubmissionId] = serviceSubmission;

        hasSubmitted[requestId][msg.sender] = true;

        //_balanceReputation(from, to, amount);

        emit RequestFulfilled(msg.sender, requestId, serviceSubmissionId);

        return serviceSubmissionId;
    }

    // Review a service submission
    function review(
        uint256 requestId,
        uint256 submissionId,
        uint256 score
    ) external onlyMaintainer {
        if (requestId > serviceRequestId) {
            revert RequestDoesNotExist(requestId);
        }
        if (submissionId > serviceSubmissionId) {
            revert SubmissionDoesNotExist(submissionId);
        }
        if (block.timestamp > serviceRequests[requestId].enforcementExp) {
            revert EnforcementDeadlinePassed();
        }
        if (serviceSubmissions[submissionId].score != 0) {
            revert AlreadyReviewed();
        }

        // score = EnforcementModule.review(submissionId, score);

        serviceSubmissions[submissionId].score = score;

        // _balanceReputation(from, to, amount);

        emit RequestReviewed(msg.sender, requestId, submissionId, score);
    }

    // Claim reward for a service submission
    function claim(uint256 submissionId) external permittedParticipant {
        if (submissionId > serviceSubmissionId) {
            revert SubmissionDoesNotExist(submissionId);
        }
        if (serviceSubmissions[submissionId].score == 0) {
            revert NotReviewed();
        }
        if (serviceSubmissions[submissionId].serviceProvider != msg.sender) {
            revert NotServiceProvider();
        }
        if (hasClaimed[submissionId][msg.sender]) {
            revert AlreadyClaimed();
        }

        uint256 amount = 1;
        // uint256 amount = PaymentModule.pay(uint256 requestId, uint256 submissionId)
        // _balanceReputation(from, to, amount);

        hasClaimed[submissionId][msg.sender] = true;

        emit RequestPayClaimed(msg.sender, submissionId, amount);
    }

    // Withdraw a service request given that it has not been signaled
    function withdrawRequest(uint256 requestId) external onlyPermissioned {
        if (serviceRequests[requestId].serviceRequester != msg.sender)
            revert NotTheRequester(msg.sender);
        if (signalCount[requestId] > 0) revert RequestActive(requestId);

        delete serviceRequests[requestId];

        emit RequestWithdrawn(requestId);
    }

    // Update market parameters as long as the market is not active
    function setMarketParameters(
        address _delegateBadge,
        address _participationBadge,
        address _payCurve,
        address _enforcementCriteria,
        uint256 _repMultiplier,
        string calldata _marketUri
    ) external onlyPermissioned {
        if (serviceRequestId > 0) revert MarketActive();
        delegateBadge = ERC1155(_delegateBadge);
        participationBadge = ERC1155(_participationBadge);
        payCurve = _payCurve;
        enforcementCriteria = _enforcementCriteria;
        repMultiplier = _repMultiplier;
        marketUri = _marketUri;

        emit MarketParametersUpdated(
            marketId,
            _delegateBadge,
            _participationBadge,
            _payCurve,
            _enforcementCriteria,
            _repMultiplier,
            _marketUri
        );
    }

    function _balanceReputation(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        participationBadge.safeTransferFrom(
            from,
            to,
            participationTokenId,
            amount,
            ""
        );

        return amount;
    }

    function getRequest(uint256 requestId)
        external
        view
        returns (ServiceRequest memory)
    {
        return serviceRequests[requestId];
    }

    function getSubmission(uint256 submissionId)
        external
        view
        returns (ServiceSubmission memory)
    {
        return serviceSubmissions[submissionId];
    }

    modifier permittedParticipant() {
        if (
            (delegateBadge.balanceOf(msg.sender, delegateTokenId) < 1) ||
            (participationBadge.balanceOf(msg.sender, participationTokenId) <
                (metricNetwork.baseReputation() * repMultiplier))
        ) revert NotQualified();
        _;
    }

    modifier onlyPermissioned() {
        _;
    }

    modifier onlyMaintainer() {
        _;
    }
}
