// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @dev Core dependencies.
import { LaborMarketInterface } from "./interfaces/LaborMarketInterface.sol";
import { LaborMarketEventsAndErrors } from "./LaborMarketEventsAndErrors.sol";

// Interfacing
import { Network } from "../Network.sol";
import { EnforcementModule } from "../Modules/Enforcement/EnforcementModule.sol";
import { PaymentModule } from "../Modules/Payment/PaymentModule.sol";

// Structs
import {ServiceRequest} from "../Structs/ServiceRequest.sol";
import {ServiceSubmission} from "../Structs/ServiceSubmission.sol";

// Events & Errors

/// @dev Helpers.
import { StringsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract LaborMarket is 
      LaborMarketInterface
    , LaborMarketEventsAndErrors
{
    Network public network;
    EnforcementModule public enforcementModule;
    PaymentModule public paymentModule;

    ERC1155 public delegateBadge;
    ERC1155 public participationBadge;

    uint256 public delegateTokenId;
    uint256 public participationTokenId;

    address public payCurve;
    address public enforcementCriteria;

    uint256 public repParticipantMultiplier;
    uint256 public repMaintainerMultiplier;
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

    function initialize(
          address _network
        , address _enforcementModule
        , address _paymentModule
        , address _delegateBadge
        , uint256 _delegateTokenId
        , address _participationBadge
        , uint256 _participationTokenId
        , uint256 _repParticipantMultiplier
        , uint256 _repMaintainerMultiplier
        , string memory _marketUri
    )
        external
        initializer
    {
        /// @dev Connect to the higher level network to pull the active states.
        network = Network(_network);

        /// @dev Configure the Labor Market state control.
        enforcementModule = EnforcementModule(_enforcementModule);
        paymentModule = PaymentModule(_paymentModule);

        /// @dev Configure the Labor Market access control.
        delegateBadge = ERC1155(_delegateBadge);
        participationBadge = ERC1155(_participationBadge);

        delegateTokenId = _delegateTokenId;
        participationTokenId = _participationTokenId;

        repParticipantMultiplier = _repParticipantMultiplier;
        repMaintainerMultiplier = _repMaintainerMultiplier;

        marketUri = _marketUri;
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

        // TODO: Move this to payment module
        ERC1155(pToken).safeTransferFrom(
            msg.sender,
            address(this),
            pTokenId,
            pTokenQ,
            ""
        );

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
            network.baseSignalStake()
        );

        hasSignaled[requestId][msg.sender] = true;

        unchecked {
            ++signalCount[requestId];
        }

        emit RequestSignal(msg.sender, requestId, signalAmt);
    }

    // TODO: Signal review
    // function signal(uint256 requestId) external permittedParticipant {
    //     if (requestId > serviceRequestId) {
    //         revert RequestDoesNotExist(requestId);
    //     }
    //     if (block.timestamp > serviceRequests[requestId].signalExp) {
    //         revert SignalDeadlinePassed();
    //     }
    //     if (hasSignaled[requestId][msg.sender]) {
    //         revert AlreadySignaled();
    //     }

    //     uint256 signalAmt = _balanceReputation(
    //         msg.sender,
    //         address(this),
    //         network.baseSignalStake()
    //     );

    //     hasSignaled[requestId][msg.sender] = true;

    //     unchecked {
    //         ++signalCount[requestId];
    //     }

    //     emit RequestSignal(msg.sender, requestId, signalAmt);
    // }

    // Fulfill a service request
    function provide(uint256 requestId, string calldata uri)
        external
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
            requestId: requestId,
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
        // TODO: Fix this --> likert scores start at 0 if using enums
        if (serviceSubmissions[submissionId].score != 0) {
            revert AlreadyReviewed();
        }
        if (serviceSubmissions[submissionId].serviceProvider == msg.sender) {
            revert CannotReviewOwnSubmission();
        }

        score = enforcementModule.review(
            enforcementCriteria,
            submissionId,
            score
        );

        serviceSubmissions[submissionId].score = score;

        // _balanceReputation(from, to, amount);

        emit RequestReviewed(msg.sender, requestId, submissionId, score);
    }

    // Claim reward for a service submission
    function claim(uint256 submissionId) external returns (uint256) {
        if (submissionId > serviceSubmissionId) {
            revert SubmissionDoesNotExist(submissionId);
        }
        if (serviceSubmissions[submissionId].score == 99999) {
            revert NotReviewed();
        }
        if (
            serviceRequests[serviceSubmissions[submissionId].requestId]
                .enforcementExp < block.timestamp
        ) {
            revert InReview();
        }
        if (serviceSubmissions[submissionId].serviceProvider != msg.sender) {
            revert NotServiceProvider();
        }
        if (hasClaimed[submissionId][msg.sender]) {
            revert AlreadyClaimed();
        }

        uint256 curveIndex = enforcementModule.verifyIndex(
            enforcementCriteria,
            submissionId
        );
        // _balanceReputation(from, to, amount);
        uint256 amount = paymentModule.claim(payCurve, curveIndex);

        hasClaimed[submissionId][msg.sender] = true;

        emit RequestPayClaimed(msg.sender, submissionId, amount);

        return amount;
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
        uint256 _repParticipantMultiplier,
        uint256 _repMaintainerMultiplier,
        string calldata _marketUri
    ) external onlyPermissioned {
        if (serviceRequestId > 0) revert MarketActive();
        delegateBadge = ERC1155(_delegateBadge);
        participationBadge = ERC1155(_participationBadge);
        payCurve = _payCurve;
        enforcementCriteria = _enforcementCriteria;
        repParticipantMultiplier = _repParticipantMultiplier;
        repMaintainerMultiplier = _repMaintainerMultiplier;
        marketUri = _marketUri;

        emit MarketParametersUpdated(
            marketId,
            _delegateBadge,
            _participationBadge,
            _payCurve,
            _enforcementCriteria,
            _repParticipantMultiplier,
            _repMaintainerMultiplier,
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
                (network.baseProviderThreshold() *
                    repParticipantMultiplier))
        ) revert NotQualified();
        _;
    }

    modifier onlyPermissioned() {
        _;
    }

    modifier onlyMaintainer() {
        if (
            participationBadge.balanceOf(msg.sender, participationTokenId) <
            (network.baseMaintainerThreshold() * repMaintainerMultiplier)
        ) revert NotQualified();
        _;
    }
}
