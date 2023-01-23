// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarketInterface } from "./interfaces/LaborMarketInterface.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ERC1155HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { ERC721HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import { Delegatable, DelegatableCore } from "delegatable/Delegatable.sol";

/// @dev Helpers.
import { StringsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/// @dev Helper interfaces.
import { LaborMarketNetworkInterface } from "../Network/interfaces/LaborMarketNetworkInterface.sol";
import { EnforcementCriteriaInterface } from "../Modules/Enforcement/interfaces/EnforcementCriteriaInterface.sol";
import { PayCurveInterface } from "../Modules/Payment/interfaces/PayCurveInterface.sol";
import { ReputationModuleInterface } from "../Modules/Reputation/interfaces/ReputationModuleInterface.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @dev Supported interfaces.
import { IERC1155ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import { IERC721ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

contract LaborMarketManager is
    LaborMarketInterface,
    ERC1155HolderUpgradeable,
    ERC721HolderUpgradeable,
    Delegatable("LaborMarket", "v1.0.0"),
    ContextUpgradeable
{
    /// @dev Performable actions.
    bytes32 public constant HAS_SUBMITTED = keccak256("hasSubmitted");

    bytes32 public constant HAS_CLAIMED = keccak256("hasClaimed");

    bytes32 public constant HAS_CLAIMED_REMAINDER =
        keccak256("hasClaimedRemainder");

    bytes32 public constant HAS_REVIEWED = keccak256("hasReviewed");
    
    bytes32 public constant HAS_SIGNALED = keccak256("hasSignaled");

    /// @dev The network contract.
    LaborMarketNetworkInterface public network;

    /// @dev The enforcement criteria.
    EnforcementCriteriaInterface public enforcementCriteria;

    /// @dev The payment curve.
    PayCurveInterface public paymentCurve;

    /// @dev The reputation module.
    ReputationModuleInterface public reputationModule;

    /// @dev The configuration of the labor market.
    LaborMarketConfiguration public configuration;

    /// @dev The delegate badge.
    IERC1155 public delegateBadge;

    /// @dev The maintainer badge.
    IERC1155 public maintainerBadge;

    /// @dev Tracking the signals per service request.
    mapping(uint256 => uint256) public signalCount;

    /// @dev Tracking the service requests.
    mapping(uint256 => ServiceRequest) public serviceRequests;

    /// @dev Tracking the service submissions.
    mapping(uint256 => ServiceSubmission) public serviceSubmissions;

    /// @dev Tracking the review signals.
    mapping(uint256 => mapping(address => ReviewPromise)) public reviewSignals;

    /// @dev Tracking whether an action has been performed.
    mapping(uint256 => mapping(address => mapping(bytes32 => bool)))
        public hasPerformed;

    /// @dev The service request id counter.
    uint256 public serviceId;

    /// @notice emitted when labor market parameters are updated.
    event LaborMarketConfigured(
        LaborMarketConfiguration indexed configuration
    );

    /// @notice emitted when a new service request is made.
    event RequestConfigured(
          address indexed requester
        , uint256 indexed requestId
        , string indexed uri
        , address pToken
        , uint256 pTokenQ
        , uint256 signalExp
        , uint256 submissionExp
        , uint256 enforcementExp
    );

    /// @notice emitted when a user signals a service request.
    event RequestSignal(
          address indexed signaler
        , uint256 indexed requestId
        , uint256 signalAmount
    );

    /// @notice emitted when a maintainer signals a review.
    event ReviewSignal(
          address indexed signaler
        , uint256 indexed quantity
        , uint256 signalAmount
    );

    /// @notice emitted when a service request is withdrawn.
    event RequestWithdrawn(
        uint256 indexed requestId
    );

    /// @notice emitted when a service request is fulfilled.
    event RequestFulfilled(
          address indexed fulfiller
        , uint256 indexed requestId
        , uint256 indexed submissionId
    );

    /// @notice emitted when a service submission is reviewed
    event RequestReviewed(
          address reviewer
        , uint256 indexed requestId
        , uint256 indexed submissionId
        , uint256 indexed reviewScore
    );

    /// @notice emitted when a service submission is claimed.
    event RequestPayClaimed(
          address indexed claimer
        , uint256 indexed submissionId
        , uint256 indexed payAmount
        , address to
    );

    /// @notice emitted when a remainder is claimed.
    event RemainderClaimed(
          address indexed claimer
        , uint256 indexed requestId
        , uint256 remainderAmount
    );

    /// @notice Gates the permissions to create new requests.
    modifier onlyDelegate() {
        require(
            delegateBadge.balanceOf(
                _msgSender(),
                configuration.delegateTokenId
            ) > 0,
            "LaborMarket::onlyDelegate: Not a delegate."
        );
        _;
    }

    /// @notice Gates the permissions to review submissions.
    modifier onlyMaintainer() {
        require(
            maintainerBadge.balanceOf(
                _msgSender(),
                configuration.maintainerTokenId
            ) > 0,
            "LaborMarket::onlyMaintainer: Not a maintainer"
        );
        _;
    }

    /// @notice Gates the permissions to provide submissions based on reputation.
    modifier permittedParticipant() {
        uint256 availableRep = _getAvailableReputation();
        require((
                availableRep >= configuration.submitMin &&
                availableRep < configuration.submitMax
            ), "LaborMarket::permittedParticipant: Not a permitted participant"
        );
        _;
    }

    /// @notice Initialize the labor market.
    function initialize(
        LaborMarketConfiguration calldata _configuration
    )
        external
        override
        initializer
    {
        _setConfiguration(_configuration);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the service request data.
     * @param _requestId The id of the service requesters request.
     */
    function getRequest(
        uint256 _requestId
    )
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
    function getSubmission(
        uint256 _submissionId
    )
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
     * @dev Handle all the logic for configuration of a LaborMarket.
     */
    function _setConfiguration(
        LaborMarketConfiguration calldata _configuration
    )
        internal
    {
        /// @dev Connect to the higher level network to pull the active states.
        network = LaborMarketNetworkInterface(_configuration.network);

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

        emit LaborMarketConfigured(_configuration);
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
     * @dev Delegatable ETH support
     */
    function _msgSender()
        internal
        view
        virtual
        override(DelegatableCore, ContextUpgradeable)
        returns (
            address sender
        )
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
