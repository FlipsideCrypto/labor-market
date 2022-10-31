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
import {ReputationModuleInterface} from "../Modules/Reputation/interfaces/ReputationModuleInterface.sol";
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
    ReputationModuleInterface public reputationModule;

    IERC1155 public delegateBadge;

    LaborMarketConfiguration public configuration;

    mapping(uint256 => uint256) public signalCount;

    mapping(uint256 => ServiceRequest) public serviceRequests;
    mapping(uint256 => ServiceSubmission) public serviceSubmissions;

    mapping(uint256 => mapping(address => bool)) public submissionSignals;
    mapping(address => mapping(uint256 => ReviewPromise)) public reviewSignals;

    mapping(uint256 => mapping(address => bool)) public hasSubmitted;
    mapping(uint256 => mapping(address => bool)) public hasClaimed;

    mapping(address => bool) public permissioned;

    uint256 public serviceRequestId;
    uint256 public serviceSubmissionId;

    /// @notice emitted when a new labor market is created
    event LaborMarketCreated(
        uint256 indexed marketId,
        address delegateBadge,
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
        uint256 indexed quantity,
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

    modifier permittedParticipant() {
        require(
            (delegateBadge.balanceOf(
                msg.sender,
                configuration.delegateTokenId
            ) >= 1) ||
                (_getAvailableReputation() >=
                    reputationModule
                        .getMarketReputationConfig(address(this))
                        .providerThreshold),
            "LaborMarket::permittedParticipant: Not a permitted participant"
        );
        _;
    }

    modifier onlyPermissioned() {
        _;
    }

    modifier onlyMaintainer() {
        require(
            _getAvailableReputation() >=
                reputationModule
                    .getMarketReputationConfig(address(this))
                    .maintainerThreshold,
            "LaborMarket::onlyMaintainer: Not a maintainer"
        );
        _;
    }

    function initialize(LaborMarketConfiguration calldata _configuration)
        external
        override
        initializer
    {
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
            block.timestamp <= serviceRequests[requestId].signalExp,
            "LaborMarket::signal: Signal deadline passed."
        );
        require(
            !submissionSignals[requestId][msg.sender],
            "LaborMarket::signal: Already signaled."
        );

        uint256 signalStake = _baseStake();

        _lockReputation(msg.sender, signalStake);

        submissionSignals[requestId][msg.sender] = true;

        unchecked {
            ++signalCount[requestId];
        }

        emit RequestSignal(msg.sender, requestId, signalStake);
    }

    /**
     * @notice Signals interest in reviewing a submission.
     * @param requestId The id of the service providers submission.
     * @param quantity The amount of submissions a maintainer is willing to review.
     */
    function signalReview(uint256 requestId, uint256 quantity)
        external
        onlyMaintainer
    {
        require(
            reviewSignals[msg.sender][requestId].remainder == 0,
            "LaborMarket::signalReview: Already signaled."
        );

        uint256 signalStake = _baseStake();

        _lockReputation(msg.sender, signalStake);

        reviewSignals[msg.sender][requestId].total = quantity;
        reviewSignals[msg.sender][requestId].remainder = quantity;

        emit ReviewSignal(msg.sender, requestId, quantity, signalStake);
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

        _unlockReputation(msg.sender, _baseStake());

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
    ) external {
        require(
            submissionId <= serviceSubmissionId,
            "LaborMarket::review: Submission does not exist."
        );
        require(
            block.timestamp <= serviceRequests[requestId].enforcementExp,
            "LaborMarket::review: Enforcement deadline passed."
        );

        require(
            reviewSignals[msg.sender][requestId].remainder > 0,
            "LaborMarket::review: Not signaled."
        );
        require(
            !serviceSubmissions[submissionId].graded,
            "LaborMarket::review: Already reviewed."
        );
        require(
            serviceSubmissions[submissionId].serviceProvider != msg.sender,
            "LaborMarket::review: Cannot review own submission."
        );

        score = enforcementCriteria.review(submissionId, score);

        serviceSubmissions[submissionId].score = score;
        serviceSubmissions[submissionId].graded = true;

        unchecked {
            --reviewSignals[msg.sender][requestId].remainder;
        }

        _unlockReputation(
            msg.sender,
            (_baseStake()) / reviewSignals[msg.sender][requestId].total
        );

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
            !hasClaimed[submissionId][msg.sender],
            "LaborMarket::claim: Already claimed."
        );
        require(
            serviceSubmissions[submissionId].graded,
            "LaborMarket::claim: Not graded."
        );
        require(
            serviceSubmissions[submissionId].serviceProvider == msg.sender,
            "LaborMarket::claim: Not service provider."
        );
        require(
            block.timestamp >=
                serviceRequests[serviceSubmissions[submissionId].requestId]
                    .enforcementExp,
            "LaborMarket::claim: Enforcement deadline not passed."
        );

        uint256 curveIndex = enforcementCriteria.verify(submissionId);

        // Increase/(decrease) reputation here for submitter
        // Mint/burn(lock) rep

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

    /**
     * @notice Returns the service request data.
     * @param _requestId The id of the service requesters request.
     */
    function getRequest(uint256 _requestId)
        external
        view
        returns (ServiceRequest memory)
    {
        return serviceRequests[_requestId];
    }

    /**
     * @notice Returns the service submission data.
     * @param _submissionId The id of the service providers submission.
     */
    function getSubmission(uint256 _submissionId)
        external
        view
        returns (ServiceSubmission memory)
    {
        return serviceSubmissions[_submissionId];
    }

    /**
     * @dev See {ReputationModule-lockReputation}.
     */
    function _lockReputation(address account, uint256 amount) internal {
        reputationModule.lockReputation(account, amount);
    }

    /**
     * @dev See {ReputationModule-unlockReputation}.
     */
    function _unlockReputation(address account, uint256 amount) internal {
        reputationModule.unlockReputation(account, amount);
    }

    /**
     * @dev See {ReputationModule-freezeReputation}.
     */
    function _freezeReputation(address account, uint256 amount) internal {
        reputationModule.freezeReputation(account, amount);
    }

    /**
     * @dev See {ReputationModule-getAvailableReputation}
     */

    function _getAvailableReputation() internal view returns (uint256) {
        return
            reputationModule.getAvailableReputation(address(this), msg.sender);
    }

    /**
     * @dev See {ReputationModule-getMarketReputationConfig}
     */

    function _baseStake() internal view returns (uint256) {
        return
            reputationModule
                .getMarketReputationConfig(address(this))
                .signalStake;
    }

    /**
     * @dev Handle all the logic for configuration on deployment of a new LaborMarket.
     */
    function _setConfiguration(LaborMarketConfiguration calldata _configuration)
        internal
    {
        /// @dev Connect to the higher level network to pull the active states.
        network = LaborMarketNetwork(_configuration.network);

        /// @dev Configure the Labor Market state control.
        enforcementCriteria = EnforcementCriteriaInterface(
            _configuration.enforcementModule
        );

        /// @dev Configure the Labor Market pay curve.
        paymentCurve = PayCurveInterface(_configuration.paymentModule);

        /// @dev Configure the Labor Market reputation module.
        reputationModule = ReputationModuleInterface(
            _configuration.reputationModule
        );

        /// @dev Configure the Labor Market access control.
        delegateBadge = IERC1155(_configuration.delegateBadge);

        /// @dev Configure the Labor Market parameters.
        configuration = _configuration;

        emit MarketParametersUpdated(_configuration);
    }
}
