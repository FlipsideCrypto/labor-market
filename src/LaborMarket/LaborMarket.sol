// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @dev Core dependencies.
import { LaborMarketInterface } from "./interfaces/LaborMarketInterface.sol";
import { LaborMarketEventsAndErrors } from "./LaborMarketEventsAndErrors.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol"; 
import { ERC1155HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { ERC721HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

// Structs
import {ServiceRequest} from "../Structs/ServiceRequest.sol";
import {ServiceSubmission} from "../Structs/ServiceSubmission.sol";

/// @dev Helpers.
import { StringsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/// @dev Helper interfaces.
import { LaborMarketNetwork } from "../Network/LaborMarketNetwork.sol";
import { EnforcementModule } from "../Modules/Enforcement/EnforcementModule.sol";
import { PaymentModule } from "../Modules/Payment/PaymentModule.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @dev Supported interfaces. 
import { IERC1155ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import { IERC721ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

contract LaborMarket is 
      LaborMarketInterface
    , LaborMarketEventsAndErrors
    , OwnableUpgradeable
    , ERC1155HolderUpgradeable 
    , ERC721HolderUpgradeable
{
    LaborMarketNetwork public network;
    EnforcementModule public enforcementModule;
    PaymentModule public paymentModule;

    IERC1155 public delegateBadge;
    IERC1155 public participationBadge;

    uint256 public delegateTokenId;
    uint256 public participationTokenId;

    address public payCurve;
    address public enforcementCriteria;

    uint256 public repParticipantMultiplier;
    uint256 public repMaintainerMultiplier;
    string public marketUri;

    mapping(uint256 => uint256) public signalCount;

    mapping(uint256 => ServiceRequest) public serviceRequests;
    mapping(uint256 => ServiceSubmission) public serviceSubmissions;

    mapping(uint256 => mapping(address => bool)) public hasSignaled;
    mapping(uint256 => mapping(address => bool)) public hasSubmitted;
    mapping(uint256 => mapping(address => bool)) public hasClaimed;

    mapping(address => bool) public permissioned;

    uint256 public serviceRequestId;
    uint256 public serviceSubmissionId;

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
        network = LaborMarketNetwork(_network);

        /// @dev Configure the Labor Market state control.
        enforcementModule = EnforcementModule(_enforcementModule);
        paymentModule = PaymentModule(_paymentModule);

        /// @dev Configure the Labor Market access control.
        delegateBadge = IERC1155(_delegateBadge);
        participationBadge = IERC1155(_participationBadge);

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
        IERC1155(pToken).safeTransferFrom(
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
        delegateBadge = IERC1155(_delegateBadge);
        participationBadge = IERC1155(_participationBadge);
        payCurve = _payCurve;
        enforcementCriteria = _enforcementCriteria;
        repParticipantMultiplier = _repParticipantMultiplier;
        repMaintainerMultiplier = _repMaintainerMultiplier;
        marketUri = _marketUri;

        emit MarketParametersUpdated(
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
}
