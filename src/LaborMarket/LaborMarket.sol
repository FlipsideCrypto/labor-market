// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @dev Core dependencies.
import {LaborMarketInterface} from "./interfaces/LaborMarketInterface.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC1155HolderUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import {ERC721HolderUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

/// @dev Helpers.
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/// @dev Helper interfaces.
import {LaborMarketNetwork} from "../Network/LaborMarketNetwork.sol";
import {EnforcementCriteriaInterface} from "../Modules/Enforcement/interfaces/EnforcementCriteriaInterface.sol";
import {PayCurveInterface} from "../Modules/Payment/interfaces/PayCurveInterface.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @dev Supported interfaces.
import {IERC1155ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

contract LaborMarket is
    LaborMarketInterface,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable,
    ERC721HolderUpgradeable
{
    LaborMarketNetwork public network;
    EnforcementCriteriaInterface public enforcementCriteria;
    PayCurveInterface public paymentCurve;

    IERC1155 public delegateBadge;
    IERC1155 public participationBadge;

    LaborMarketConfiguration public configuration;

    mapping(uint256 => uint256) public signalCount;

    mapping(uint256 => ServiceRequest) public serviceRequests;
    mapping(uint256 => ServiceSubmission) public serviceSubmissions;

    mapping(uint256 => mapping(address => bool)) public submissionSignals;
    mapping(uint256 => mapping(address => bool)) public reviewSignals;

    mapping(uint256 => mapping(address => bool)) public hasSubmitted;
    mapping(uint256 => mapping(address => bool)) public hasClaimed;

    mapping(address => bool) public permissioned;

    uint256 public serviceRequestId;
    uint256 public serviceSubmissionId;

    modifier permittedParticipant() {
        require(
            (delegateBadge.balanceOf(
                msg.sender,
                configuration.delegateTokenId
            ) >= 1) ||
                (participationBadge.balanceOf(
                    msg.sender,
                    configuration.participationTokenId
                ) >=
                    (network.baseProviderThreshold() *
                        configuration.repParticipantMultiplier)),
            "LaborMarket::permittedParticipant: Not a permitted participant"
        );
        _;
    }

    modifier onlyPermissioned() {
        _;
    }

    modifier onlyMaintainer() {
        require(
            participationBadge.balanceOf(
                msg.sender,
                configuration.participationTokenId
            ) >=
                (network.baseMaintainerThreshold() *
                    configuration.repMaintainerMultiplier),
            "LaborMarket::onlyMaintainer: Not a maintainer"
        );
        _;
    }

    /// @notice emitted when a new labor market is created
    event LaborMarketCreated(
        uint256 indexed marketId,
        address delegateBadge,
        address participationBadge,
        address payCurve,
        address enforcementCriteria,
        uint256 repParticipantMultiplier,
        uint256 repMaintainerMultiplier,
        string marketUri
    );

    /// @notice emitted when labor market parameters are updated
    event MarketParametersUpdated(
        LaborMarketConfiguration indexed configuration
    );

    /// @notice emitted when a new service request is made
    event RequestCreated(
        address indexed requester,
        uint256 indexed requestId,
        string indexed uri,
        address pToken,
        uint256 pTokenId,
        uint256 pTokenQ,
        uint256 signalExp,
        uint256 submissionExp,
        uint256 enforcementExp
    );

    /// @notice emitted when a user signals a service request
    event RequestSignal(
        address indexed signaler,
        uint256 indexed requestId,
        uint256 signalAmount
    );

    /// @notice emitted when a maintainer signals a review
    event ReviewSignal(
        address indexed signaler,
        uint256 indexed requestId,
        uint256 signalAmount
    );

    /// @notice emitted when a service request is withdrawn
    event RequestWithdrawn(uint256 indexed requestId);

    /// @notice emitted when a service request is fulfilled
    event RequestFulfilled(
        address indexed fulfiller,
        uint256 indexed requestId,
        uint256 indexed submissionId
    );

    /// @notice emitted when a service submission is reviewed
    event RequestReviewed(
        address reviewer,
        uint256 indexed requestId,
        uint256 indexed submissionId,
        uint256 indexed reviewScore
    );

    event RequestPayClaimed(
        address indexed claimer,
        uint256 indexed submissionId,
        uint256 indexed payAmount
    );

    function initialize(
        address _network,
        LaborMarketConfiguration calldata _configuration
    ) external override initializer {
        _setConfiguration(_configuration);
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
        require(
            requestId <= serviceRequestId,
            "LaborMarket::signal: Request does not exist."
        );
        require(
            block.timestamp <= serviceRequests[requestId].signalExp,
            "LaborMarket::signal: Signal deadline passed."
        );
        require(
            !submissionSignals[requestId][msg.sender],
            "LaborMarket::signal: Already signaled."
        );

        // Lock reputation here
        uint256 signalAmt = 1;

        submissionSignals[requestId][msg.sender] = true;

        unchecked {
            ++signalCount[requestId];
        }

        emit RequestSignal(msg.sender, requestId, signalAmt);
    }

    // TODO: Signal review
    function signalReview(uint256 submissionId) external onlyMaintainer {
        require(
            submissionId <= serviceSubmissionId,
            "LaborMarket::signalReview: Submission does not exist."
        );
        require(
            !reviewSignals[submissionId][msg.sender],
            "LaborMarket::signalReview: Already signaled."
        );

        // Lock reputation here
        uint256 signalAmt = 1;

        reviewSignals[submissionId][msg.sender] = true;

        emit ReviewSignal(msg.sender, submissionId, signalAmt);
    }

    // Fulfill a service request
    function provide(uint256 requestId, string calldata uri)
        external
        returns (uint256 submissionId)
    {
        require(
            requestId <= serviceRequestId,
            "LaborMarket::provide: Request does not exist."
        );
        require(
            block.timestamp <= serviceRequests[requestId].submissionExp,
            "LaborMarket::provide: Submission deadline passed."
        );
        require(
            submissionSignals[requestId][msg.sender],
            "LaborMarket::provide: Not signaled."
        );
        require(
            !hasSubmitted[requestId][msg.sender],
            "LaborMarket::provide: Already submitted."
        );

        unchecked {
            ++serviceSubmissionId;
        }

        ServiceSubmission memory serviceSubmission = ServiceSubmission({
            serviceProvider: msg.sender,
            requestId: requestId,
            timestamp: block.timestamp,
            uri: uri,
            score: 0,
            graded: false
        });

        serviceSubmissions[serviceSubmissionId] = serviceSubmission;

        hasSubmitted[requestId][msg.sender] = true;

        // Unlock reputation here for submission signal

        emit RequestFulfilled(msg.sender, requestId, serviceSubmissionId);

        return serviceSubmissionId;
    }

    // Review a service submission
    function review(
        uint256 requestId,
        uint256 submissionId,
        uint256 score
    ) external onlyMaintainer {
        require(
            requestId <= serviceRequestId,
            "LaborMarket::review: Request does not exist."
        );
        require(
            submissionId <= serviceSubmissionId,
            "LaborMarket::review: Submission does not exist."
        );
        require(
            block.timestamp <= serviceRequests[requestId].enforcementExp,
            "LaborMarket::review: Enforcement deadline passed."
        );

        require(
            reviewSignals[submissionId][msg.sender],
            "LaborMarket::review: Not signaled."
        );
        // TODO: Fix this --> likert scores start at 0 if using enums
        require(
            !serviceSubmissions[submissionId].graded,
            "LaborMarket::review: Already graded."
        );
        require(
            serviceSubmissions[submissionId].serviceProvider != msg.sender,
            "LaborMarket::review: Cannot review own submission."
        );

        score = enforcementCriteria.review(submissionId, score);

        serviceSubmissions[submissionId].score = score;
        serviceSubmissions[submissionId].graded = true;

        // Unlock maintainer reputation here

        emit RequestReviewed(msg.sender, requestId, submissionId, score);
    }

    // Claim reward for a service submission
    function claim(uint256 submissionId) external returns (uint256) {
        require(
            submissionId <= serviceSubmissionId,
            "LaborMarket::claim: Submission does not exist."
        );
        require(
            serviceSubmissions[submissionId].graded,
            "LaborMarket::claim: Not graded."
        );
        require(
            block.timestamp >=
                serviceRequests[serviceSubmissions[submissionId].requestId]
                    .enforcementExp,
            "LaborMarket::claim: Enforcement deadline not passed."
        );
        require(
            serviceSubmissions[submissionId].serviceProvider == msg.sender,
            "LaborMarket::claim: Not service provider."
        );
        require(
            !hasClaimed[submissionId][msg.sender],
            "LaborMarket::claim: Already claimed."
        );

        uint256 curveIndex = enforcementCriteria.verify(submissionId);

        // Increase/(decrease) reputation here for submitter

        uint256 amount = paymentCurve.curvePoint(curveIndex);

        hasClaimed[submissionId][msg.sender] = true;

        emit RequestPayClaimed(msg.sender, submissionId, amount);

        return amount;
    }

    // Withdraw a service request given that it has not been signaled
    function withdrawRequest(uint256 requestId) external onlyPermissioned {
        require(
            serviceRequests[requestId].serviceRequester == msg.sender,
            "LaborMarket::withdrawRequest: Not service requester."
        );
        require(
            signalCount[requestId] < 1,
            "LaborMarket::withdrawRequest: Already active."
        );

        delete serviceRequests[requestId];

        emit RequestWithdrawn(requestId);
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

    function _setConfiguration(LaborMarketConfiguration calldata _configuration)
        internal
    {
        /// @dev Connect to the higher level network to pull the active states.
        network = LaborMarketNetwork(_configuration.network);

        /// @dev Configure the Labor Market state control.
        enforcementCriteria = EnforcementCriteriaInterface(
            _configuration.enforcementModule
        );
        paymentCurve = PayCurveInterface(_configuration.paymentModule);

        /// @dev Configure the Labor Market access control.
        delegateBadge = IERC1155(_configuration.delegateBadge);
        participationBadge = IERC1155(_configuration.participationBadge);

        /// @dev Configure the Labor Market parameters.
        configuration = _configuration;

        emit MarketParametersUpdated(_configuration);
    }
}
