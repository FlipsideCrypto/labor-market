// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @dev Core dependencies.
import {LaborMarketInterface} from "./interfaces/LaborMarketInterface.sol";
import {OwnableUpgradeable, ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC1155HolderUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import {ERC721HolderUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import {Delegatable, DelegatableCore} from "delegatable/Delegatable.sol";

/// @dev Helpers.
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/// @dev Helper interfaces.
import {LaborMarketNetwork} from "../Network/LaborMarketNetwork.sol";
import {EnforcementCriteriaInterface} from "../Modules/Enforcement/interfaces/EnforcementCriteriaInterface.sol";
import {PayCurveInterface} from "../Modules/Payment/interfaces/PayCurveInterface.sol";
import {ReputationModuleInterface} from "../Modules/Reputation/interfaces/ReputationModuleInterface.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Supported interfaces.
import {IERC1155ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

contract LaborMarket is
    LaborMarketInterface,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable,
    ERC721HolderUpgradeable,
    Delegatable("LaborMarket", "v1.0.0")
{
    /// @dev Performable actions.
    bytes32 public constant HAS_SUBMITTED = keccak256("hasSubmitted");
    bytes32 public constant HAS_CLAIMED = keccak256("hasClaimed");
    bytes32 public constant HAS_CLAIMED_REMAINDER =
        keccak256("hasClaimedRemainder");
    bytes32 public constant HAS_REVIEWED = keccak256("hasReviewed");
    bytes32 public constant HAS_SIGNALED = keccak256("hasSignaled");

    /// @dev The network contract.
    LaborMarketNetwork public network;

    /// @dev The enforcement criteria.
    EnforcementCriteriaInterface public enforcementCriteria;

    /// @dev The payment curve.
    PayCurveInterface public paymentCurve;

    /// @dev The reputation module.
    ReputationModuleInterface public reputationModule;

    /// @dev The address of the ERC1155 token used for delegates.
    IERC1155 public delegateBadge;

    /// @dev The address of the ERC1155 token used for maintainers
    IERC1155 public maintainerBadge;

    /// @dev The configuration of the labor market.
    LaborMarketConfiguration public configuration;

    /// @dev Tracking the signals per service request.
    mapping(uint256 => uint256) public signalCount;

    /// @dev Tracking the service requests.
    mapping(uint256 => ServiceRequest) public serviceRequests;

    /// @dev Tracking the service submissions.
    mapping(uint256 => ServiceSubmission) public serviceSubmissions;

    /// @dev Tracking the review signals.
    mapping(address => ReviewPromise) public reviewSignals;

    /// @dev Tracking whether an action has been performed.
    mapping(uint256 => mapping(address => mapping(bytes32 => bool)))
        public hasPerformed;

    /// @dev The service request id counter.
    uint256 public serviceRequestId;

    /// @dev The service submission id counter.
    uint256 public serviceSubmissionId;

    /// @notice emitted when a new labor market is created.
    event LaborMarketCreated(
        uint256 indexed marketId,
        address delegateBadge,
        address maintainerBadge,
        address payCurve,
        address enforcementCriteria,
        uint256 repParticipantMultiplier,
        uint256 repMaintainerMultiplier,
        string marketUri
    );

    /// @notice emitted when labor market parameters are updated.
    event MarketParametersUpdated(
        LaborMarketConfiguration indexed configuration
    );

    /// @notice emitted when a new service request is made.
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

    /// @notice emitted when a user signals a service request.
    event RequestSignal(
        address indexed signaler,
        uint256 indexed requestId,
        uint256 signalAmount
    );

    /// @notice emitted when a maintainer signals a review.
    event ReviewSignal(
        address indexed signaler,
        uint256 indexed quantity,
        uint256 signalAmount
    );

    /// @notice emitted when a service request is withdrawn.
    event RequestWithdrawn(uint256 indexed requestId);

    /// @notice emitted when a service request is fulfilled.
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

    /// @notice emitted when a service submission is claimed.
    event RequestPayClaimed(
        address indexed claimer,
        uint256 indexed submissionId,
        uint256 indexed payAmount,
        address to
    );

    /// @notice emitted when a remainder is claimed.
    event RemainderClaimed(
        address indexed claimer,
        uint256 indexed requestId,
        uint256 remainderAmount
    );

    /*
     * @notice Make sure that only addresses holding the delegate badge can call the function.
     */
    modifier onlyDelegate() {
        require(
            (delegateBadge.balanceOf(
                _msgSender(),
                configuration.delegateTokenId
            ) >= 1),
            "LaborMarket::permittedParticipant: Not a delegate."
        );
        _;
    }

    /*
     * @notice Make sure that only addresses conforming to the reputational barrier can call the function.
     */
    modifier permittedParticipant() {
        require(
            (_getAvailableReputation() >=
                reputationModule
                    .getMarketReputationConfig(address(this))
                    .providerThreshold),
            "LaborMarket::permittedParticipant: Not a permitted participant"
        );
        _;
    }

    /*
     * @notice Make sure that only addresses holding the maintainer badge can call the function.
     */
    modifier onlyMaintainer() {
        require(
            (maintainerBadge.balanceOf(
                _msgSender(),
                configuration.maintainerTokenId
            ) >= 1),
            "LaborMarket::onlyMaintainer: Not a maintainer"
        );
        _;
    }

    /// @notice Initialize the labor market.
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
    ) external onlyDelegate returns (uint256 requestId) {
        unchecked {
            ++serviceRequestId;
        }

        ServiceRequest memory serviceRequest = ServiceRequest({
            serviceRequester: _msgSender(),
            pToken: pToken,
            pTokenId: pTokenId,
            pTokenQ: pTokenQ,
            signalExp: signalExp,
            submissionExp: submissionExp,
            enforcementExp: enforcementExp,
            uri: requestUri
        });

        serviceRequests[serviceRequestId] = serviceRequest;

        IERC20(pToken).transferFrom(_msgSender(), address(this), pTokenQ);

        emit RequestCreated(
            _msgSender(),
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
            !hasPerformed[requestId][_msgSender()][HAS_SIGNALED],
            "LaborMarket::signal: Already signaled."
        );

        uint256 signalStake = _baseStake();

        _lockReputation(_msgSender(), signalStake);

        hasPerformed[requestId][_msgSender()][HAS_SIGNALED] = true;

        unchecked {
            ++signalCount[requestId];
        }

        emit RequestSignal(_msgSender(), requestId, signalStake);
    }

    /**
     * @notice Signals interest in reviewing a submission.
     * @param quantity The amount of submissions a maintainer is willing to review.
     */
    function signalReview(uint256 quantity) external onlyMaintainer {
        require(
            reviewSignals[_msgSender()].remainder == 0,
            "LaborMarket::signalReview: Already signaled."
        );

        uint256 signalStake = _baseStake();

        _lockReputation(_msgSender(), signalStake);

        reviewSignals[_msgSender()].total = quantity;
        reviewSignals[_msgSender()].remainder = quantity;

        emit ReviewSignal(_msgSender(), quantity, signalStake);
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
            hasPerformed[requestId][_msgSender()][HAS_SIGNALED],
            "LaborMarket::provide: Not signaled."
        );
        require(
            !hasPerformed[requestId][_msgSender()][HAS_SUBMITTED],
            "LaborMarket::provide: Already submitted."
        );

        unchecked {
            ++serviceSubmissionId;
        }

        ServiceSubmission memory serviceSubmission = ServiceSubmission({
            serviceProvider: _msgSender(),
            requestId: requestId,
            timestamp: block.timestamp,
            uri: uri,
            scores: new uint256[](0),
            reviewed: false
        });

        serviceSubmissions[serviceSubmissionId] = serviceSubmission;

        hasPerformed[requestId][_msgSender()][HAS_SUBMITTED] = true;

        _unlockReputation(_msgSender(), _baseStake());

        emit RequestFulfilled(_msgSender(), requestId, serviceSubmissionId);

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
            reviewSignals[_msgSender()].remainder > 0,
            "LaborMarket::review: Not signaled."
        );
        require(
            !hasPerformed[submissionId][_msgSender()][HAS_REVIEWED],
            "LaborMarket::review: Already reviewed."
        );
        require(
            serviceSubmissions[submissionId].serviceProvider != _msgSender(),
            "LaborMarket::review: Cannot review own submission."
        );

        score = enforcementCriteria.review(submissionId, score);

        serviceSubmissions[submissionId].scores.push(score);

        if (!serviceSubmissions[submissionId].reviewed)
            serviceSubmissions[submissionId].reviewed = true;

        hasPerformed[submissionId][_msgSender()][HAS_REVIEWED] = true;

        unchecked {
            --reviewSignals[_msgSender()].remainder;
        }

        _unlockReputation(
            _msgSender(),
            (_baseStake()) / reviewSignals[_msgSender()].total
        );

        emit RequestReviewed(_msgSender(), requestId, submissionId, score);
    }

    /**
     * @notice Allows a service provider to claim payment for a service submission.
     * @param submissionId The id of the service providers submission.
     */
    function claim(
        uint256 submissionId,
        address to,
        bytes calldata data
    ) external returns (uint256) {
        require(
            submissionId <= serviceSubmissionId,
            "LaborMarket::claim: Submission does not exist."
        );
        require(
            !hasPerformed[submissionId][_msgSender()][HAS_CLAIMED],
            "LaborMarket::claim: Already claimed."
        );
        require(
            serviceSubmissions[submissionId].reviewed,
            "LaborMarket::claim: Not reviewed."
        );
        require(
            serviceSubmissions[submissionId].serviceProvider == _msgSender(),
            "LaborMarket::claim: Not service provider."
        );
        require(
            block.timestamp >=
                serviceRequests[serviceSubmissions[submissionId].requestId]
                    .enforcementExp,
            "LaborMarket::claim: Enforcement deadline not passed."
        );

        uint256 curveIndex = enforcementCriteria.verify(submissionId);

        uint256 amount = paymentCurve.curvePoint(curveIndex);

        hasPerformed[submissionId][_msgSender()][HAS_CLAIMED] = true;

        IERC20(
            serviceRequests[serviceSubmissions[submissionId].requestId].pToken
        ).transfer(to, amount);

        emit RequestPayClaimed(_msgSender(), submissionId, amount, to);

        return amount;
    }

    /**
     * @notice Allows a service requester to claim the remainder of funds not allocated to service providers.
     * @param requestId The id of the service request.
     */
    function claimRemainder(uint256 requestId) public {
        require(
            serviceRequests[requestId].serviceRequester == _msgSender(),
            "LaborMarket::claimRemainder: Not service requester."
        );
        require(
            block.timestamp >= serviceRequests[requestId].enforcementExp,
            "LaborMarket::claimRemainder: Enforcement deadline not passed."
        );
        require(
            !hasPerformed[requestId][_msgSender()][HAS_CLAIMED_REMAINDER],
            "LaborMarket::claimRemainder: Already claimed."
        );
        uint256 totalClaimable = enforcementCriteria.getRemainder(requestId);

        hasPerformed[requestId][_msgSender()][HAS_CLAIMED_REMAINDER] = true;

        IERC20(serviceRequests[requestId].pToken).transfer(
            _msgSender(),
            totalClaimable
        );

        emit RemainderClaimed(_msgSender(), requestId, totalClaimable);
    }

    /**
     * @notice Allows a service requester to withdraw a request.
     * @param requestId The id of the service requesters request.
     * Requirements:
     * - The request must not have been signaled.
     */
    function withdrawRequest(uint256 requestId) external onlyDelegate {
        require(
            serviceRequests[requestId].serviceRequester == _msgSender(),
            "LaborMarket::withdrawRequest: Not service requester."
        );
        require(
            signalCount[requestId] < 1,
            "LaborMarket::withdrawRequest: Already active."
        );
        address pToken = serviceRequests[requestId].pToken;
        uint256 amount = serviceRequests[requestId].pTokenQ;

        delete serviceRequests[requestId];

        IERC20(pToken).transfer(_msgSender(), amount);

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
     * @notice Returns the market configuration.
     */
    function getConfiguration()
        external
        view
        returns (LaborMarketConfiguration memory)
    {
        return configuration;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL SETTERS
    //////////////////////////////////////////////////////////////*/

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
        maintainerBadge = IERC1155(_configuration.maintainerBadge);

        /// @dev Configure the Labor Market parameters.
        configuration = _configuration;

        emit MarketParametersUpdated(_configuration);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {ReputationModule-getAvailableReputation}
     */

    function _getAvailableReputation() internal view returns (uint256) {
        return
            reputationModule.getAvailableReputation(
                address(this),
                _msgSender()
            );
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
     * @dev Delegatable ETH support
     */
    function _msgSender()
        internal
        view
        virtual
        override(DelegatableCore, ContextUpgradeable)
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}
