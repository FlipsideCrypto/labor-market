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
    IERC1155 public reputationToken;
    uint256 public reputationTokenId;

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
            ) >= 1) || (
                network.getAvailableReputation(
                        msg.sender
                    , configuration.reputationToken
                    , configuration.reputationTokenId
                ) >= (
                    network.getBaseProviderThreshold(
                                configuration.reputationToken
                            , configuration.reputationTokenId
                    ) * configuration.repParticipantMultiplier
                )
            ),
            "LaborMarket::permittedParticipant: Not a permitted participant"
        );
        _;
    }

    modifier onlyPermissioned() {
        _;
    }

    modifier onlyMaintainer() {
        require(
            network.getAvailableReputation(
                  msg.sender
                , configuration.reputationToken
                , configuration.reputationTokenId
            ) >= (
                network.getBaseMaintainerThreshold(
                        configuration.reputationToken
                    , configuration.reputationTokenId
                ) * configuration.repMaintainerMultiplier
            ),
            "LaborMarket::onlyMaintainer: Not a maintainer"
        );
        _;
    }

    function initialize(
        LaborMarketConfiguration calldata _configuration
    ) external override initializer {
        _setConfiguration(_configuration);
    }

    /**
     * @notice Creates a service request.
     * @param pToken The address of the payment token.
     * @param pTokenId The id of the payment token.
     * @param pTokenQ The quantity of the payment token.
     * @param signalExp The signal deadline expiration.
     * @param submissionExp The submission deadline expiration.
     * @param enforcementExp The enforcement deadline expiration.
     * @param requestUri The uri of the service request data.
     * Requirements:
     * - A user has to be conform to the reputational restrictions imposed by the labor market.
     */
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

    /**
     * @notice Signals interest in fulfilling a service request.
     * @param requestId The id of the service request.
     */
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

    /**
     * @notice Signals interest in reviewing a submission.
     * @param submissionId The id of the service providers submission.
     */
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

    /**
     * @notice Allows a service provider to fulfill a service request.
     * @param requestId The id of the service request being fulfilled.
     * @param uri The uri of the service submission data.
     */
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

    /**
     * @notice Allows a maintainer to review a service submission.
     * @param requestId The id of the service request being fulfilled.
     * @param submissionId The id of the service providers submission.
     * @param score The score of the service submission.
     */
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

    /**
     * @notice Allows a service provider to claim payment for a service submission.
     * @param submissionId The id of the service providers submission.
     */
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

    /**
     * @notice Allows a service requester to withdraw a request.
     * @param requestId The id of the service requesters request.
     * Requirements:
     * - The request must not have been signaled.
     */
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

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

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

        /// @dev Ensure the reputation token has been configured.
        require(
            network.getReputationManager(
                  _configuration.reputationToken
                , _configuration.reputationTokenId
            ) != address(0),
            "LaborMarket:: _setConfiguration: Reputation token not configured."
        );

        /// @dev Configure the Labor Market state control.
        enforcementCriteria = EnforcementCriteriaInterface(
            _configuration.enforcementModule
        );
        paymentCurve = PayCurveInterface(_configuration.paymentModule);

        /// @dev Configure the Labor Market access control.
        delegateBadge = IERC1155(_configuration.delegateBadge);
        reputationToken = IERC1155(_configuration.reputationToken);

        /// @dev Configure the Labor Market parameters.
        configuration = _configuration;

        emit MarketParametersUpdated(_configuration);
    }
}
